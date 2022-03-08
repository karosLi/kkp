//
//  KKPBlockHelper.m
//  Example
//
//  Created by tianyubing on 2020/8/4.
//  Copyright © 2020 TianyuBing. All rights reserved.
//

#import "KKPBlockWrapper.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/message.h>
#import "ffi.h"
#import "lauxlib.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_instance.h"
#import "kkp_converter.h"

@interface KKPBlockWrapper () {
    ffi_cif *_cifPtr;
    ffi_type **_args;
    ffi_closure *_closure;
    void *_blockPtr;
    struct KKPKitBlockDescriptor *_descriptor;
    
    lua_State *_state;
    int _funcIndex;
}

@property (nonatomic, copy) NSString *typeEncoding;

@end

@implementation KKPBlockWrapper

void copy_helper(struct KKPKitBlock *dst, struct KKPKitBlock *src) {
    // do not copy anything is this function! just retain if need.
    CFRetain(dst->wrapper);
}

void dispose_helper(struct KKPKitBlock *src) {
    CFRelease(src->wrapper);
}

static void blockIMP(ffi_cif *cif, void *ret, void **args, void *userdata) {
    KKPBlockWrapper *userInfo = (__bridge KKPBlockWrapper *)userdata;  // 不可以进行释放
    NSString *typeEncoding = userInfo.typeEncoding;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding.UTF8String];
    const char * returnType = signature.methodReturnType;
    
    __block void * return_buffer = nil;
    
    lua_State* L = kkp_currentLuaState();
    kkp_safeInLuaStack(L, ^int{
        
        luaL_getmetatable(L, KKP_INSTANCE_USER_DATA_LIST_TABLE);
        lua_pushlightuserdata(L, (__bridge void *)(userInfo));
        lua_rawget(L, -2);
        lua_remove(L, -2); // remove userdataTable

        // 获取 实例 userdata 的关联表，并压栈
        lua_getuservalue(L, -1);
        // 压入key
        lua_pushstring(L, "f");
        // 获取 key 对应的 lua 函数，并压栈
        lua_rawget(L, -2);
        
        if (lua_isnil(L, -1) || lua_type(L, -1) != LUA_TFUNCTION) {
            return 0;
        }
        
        // 压入参数，跳过第一个参数，因为第一个是 block 本身
        for (int i = 1; i < signature.numberOfArguments; i++) {
            const char *type = [signature getArgumentTypeAtIndex:i];
            kkp_toLuaObjectWithBuffer(L, type, args[i]);
        }
        
        NSUInteger paramNum = signature.numberOfArguments - 1;
        
        if (returnType == nil) {
            if (kkp_pcall(L, (int)paramNum, 0)) {
                NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(L, -1)];
                KKP_ERROR(L, log);
            }
        } else {
            if (kkp_pcall(L, (int)paramNum, 1)) {
                NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(L, -1)];
                KKP_ERROR(L, log);
            }
            return_buffer = kkp_toOCObject(L, returnType, -1);
        }
        
        return 0;
    });
    
    convertReturnValue(returnType, return_buffer, ret);
    if (return_buffer != NULL) {
        free(return_buffer);
    }
    return;
}

- (id)initWithTypeEncoding:(NSString *)typeEncoding state:(lua_State *)state funcIndex:(int)funcIndex {
    self = [super init];
    if (self) {
        _typeEncoding = typeEncoding;
        _state = state;
        _funcIndex = funcIndex;
        [self setup];
    }
    return self;
}

- (void)setup {
    lua_State *L = _state;
    int funcIndex = _funcIndex;
    kkp_safeInLuaStack(L, ^int{
        // 创建 实例 userdata
        kkp_instance_create_userdata(L, self);

        // 获取 实例 user data 的关联表，并压栈
        lua_getuservalue(L, -1);
        // 压入key
        lua_pushstring(L, "f");
        // 把函数压栈
        lua_pushvalue(L, funcIndex);
        // 把函数保存到关联表里，相当于 associated_table["f"] = lua 函数
        lua_rawset(L, -3);
        // pop 关联表
        lua_pop(L, 1);
        
        return 1;
    });
}

- (void *)blockPtr {
    NSString *typeEncoding = self.typeEncoding;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding.UTF8String];
    if (typeEncoding.length <= 0) {
        return nil;
    }
    // 第一个参数是自身block的参数
    unsigned int argCount = (unsigned int)signature.numberOfArguments;
    void *imp = NULL;
    _cifPtr = malloc(sizeof(ffi_cif));  //不可以free
    _closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&imp);
    ffi_type *returnType = (ffi_type *)typeEncodingToffiType(signature.methodReturnType);
    _args = malloc(sizeof(ffi_type *) * argCount);
    _args[0] = &ffi_type_pointer;

    for (int i = 1; i < argCount; i++) {
        _args[i] = (ffi_type *)typeEncodingToffiType([signature getArgumentTypeAtIndex:i]);
    }

    if (ffi_prep_cif(_cifPtr, FFI_DEFAULT_ABI, argCount, returnType, _args) == FFI_OK) {
        if (ffi_prep_closure_loc(_closure, _cifPtr, blockIMP, (__bridge void *)self, imp) != FFI_OK) {
            NSAssert(NO, @"block 生成失败");
        }
    }

    struct KKPKitBlockDescriptor descriptor
        = { 0, sizeof(struct KKPKitBlock), (void (*)(void *dst, const void *src))copy_helper, (void (*)(const void *src))dispose_helper, nil };

    _descriptor = malloc(sizeof(struct KKPKitBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct KKPKitBlockDescriptor));

    struct KKPKitBlock newBlock
        = { &_NSConcreteStackBlock, (KKPKit_BLOCK_HAS_COPY_DISPOSE | KKPKit_BLOCK_HAS_SIGNATURE), 0, imp, _descriptor, (__bridge void *)self };

    _blockPtr = Block_copy(&newBlock);
    CFRelease(&descriptor);
    CFRelease(&newBlock);
    return _blockPtr;
}

- (void)dealloc {
    if (_closure) {
        ffi_closure_free(_closure);
        free(_args);
        free(_cifPtr);
        free(_descriptor);
    }
}

#define KKP_RETURN_PTR_WRAP(typeChar, type) \
    case typeChar: {                         \
        *(type *)ret = *(type *)retBuffer;    \
    } break;
static void convertReturnValue(const char *returnType, void *retBuffer, void *ret) {
    const char * type = kkp_removeProtocolEncodings(returnType);
    
    switch (type[0]) {
        case _C_ID:
        case _C_CLASS:
        case _C_PTR:
        case _C_SEL:
        case _C_CHARPTR:
        {
            if (retBuffer != nil) {
                *(void **)ret = *(void **)retBuffer;
            } else {
                *(void **)ret = nil;
            }
        } break;
        case _C_STRUCT_B:
        {
            *(void **)ret = *(void **)retBuffer;
        } break;
            KKP_RETURN_PTR_WRAP(_C_SHT, short);
            KKP_RETURN_PTR_WRAP(_C_USHT, unsigned short);
            KKP_RETURN_PTR_WRAP(_C_INT, int);
            KKP_RETURN_PTR_WRAP(_C_UINT, unsigned int);
            KKP_RETURN_PTR_WRAP(_C_LNG, long);
            KKP_RETURN_PTR_WRAP(_C_ULNG, unsigned long);
            KKP_RETURN_PTR_WRAP(_C_LNG_LNG, long long);
            KKP_RETURN_PTR_WRAP(_C_ULNG_LNG, unsigned long long);
            KKP_RETURN_PTR_WRAP(_C_FLT, float);
            KKP_RETURN_PTR_WRAP(_C_DBL, double);
            KKP_RETURN_PTR_WRAP(_C_BFLD, BOOL);
            KKP_RETURN_PTR_WRAP(_C_BOOL, BOOL);
            KKP_RETURN_PTR_WRAP(_C_CHR, char);
            KKP_RETURN_PTR_WRAP(_C_UCHR, u_char);

        default:
            break;
    }
    return;
}

static ffi_type *typeEncodingToffiType(const char *typeEncoding) {
    NSString *typeString = [NSString stringWithUTF8String:typeEncoding];
    switch (typeEncoding[0]) {
        case 'v':
            return &ffi_type_void;
        case 'c':
            return &ffi_type_schar;
        case '*':// char *
            return &ffi_type_pointer;
        case 'C':
            return &ffi_type_uchar;
        case 's':
            return &ffi_type_sshort;
        case 'S':
            return &ffi_type_ushort;
        case 'i':
            return &ffi_type_sint;
        case 'I':
            return &ffi_type_uint;
        case 'l':
            return &ffi_type_slong;
        case 'L':
            return &ffi_type_ulong;
        case 'q':
            return &ffi_type_sint64;
        case 'Q':
            return &ffi_type_uint64;
        case 'f':
            return &ffi_type_float;
        case 'd':
            return &ffi_type_double;
        case 'D':
            return &ffi_type_longdouble;
        case 'B':
            return &ffi_type_uint8;
        case '^':
            return &ffi_type_pointer;
        case '@':
            return &ffi_type_pointer;
        case '#':
            return &ffi_type_pointer;
        case ':':
            return &ffi_type_pointer;
        case '{': {
            ffi_type *type = malloc(sizeof(ffi_type));
            type->size = 0;
            type->alignment = 0;
            type->elements = NULL;
            type->type = FFI_TYPE_STRUCT;

            NSString *types = [typeString substringToIndex:typeString.length - 1];
            NSUInteger location = [types rangeOfString:@"="].location + 1;
            types = [types substringFromIndex:location];
            char *typesCode = (char *)[types UTF8String];

            size_t index = 0;
            size_t subCount = 0;
            NSString *subTypeEncoding;

            while (typesCode[index]) {
                if (typesCode[index] == '{') {
                    size_t stackSize = 1;
                    size_t end = index + 1;
                    for (char c = typesCode[end]; c; end++, c = typesCode[end]) {
                        if (c == '{') {
                            stackSize++;
                        } else if (c == '}') {
                            stackSize--;
                            if (stackSize == 0) {
                                break;
                            }
                        }
                    }
                    subTypeEncoding = [types substringWithRange:NSMakeRange(index, end - index + 1)];
                    index = end + 1;
                } else {
                    subTypeEncoding = [types substringWithRange:NSMakeRange(index, 1)];
                    index++;
                }

                ffi_type *subFfiType = (ffi_type *)typeEncodingToffiType((char *)subTypeEncoding.UTF8String);
                type->size += subFfiType->size;
                type->elements = realloc((void *)(type->elements), sizeof(ffi_type *) * (subCount + 1));
                type->elements[subCount] = subFfiType;
                subCount++;
            }

            type->elements = realloc((void *)(type->elements), sizeof(ffi_type *) * (subCount + 1));
            type->elements[subCount] = NULL;
            return type;
        }
        default:
            return NULL;
    }
}

@end
