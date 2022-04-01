//
//  kkp_helper.m
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import "kkp_helper.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <os/lock.h>
#import "lauxlib.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_runtime_helper.h"
#import "kkp_class.h"
#import "kkp_instance.h"
#import "kkp_converter.h"
#import "KKPBlockDescription.h"

#define KKP_PROTOCOL_TYPE_CONST 'r'
#define KKP_PROTOCOL_TYPE_IN 'n'
#define KKP_PROTOCOL_TYPE_INOUT 'N'
#define KKP_PROTOCOL_TYPE_OUT 'o'
#define KKP_PROTOCOL_TYPE_BYCOPY 'O'
#define KKP_PROTOCOL_TYPE_BYREF 'R'
#define KKP_PROTOCOL_TYPE_ONEWAY 'V'

#define KKP_BEGIN_STACK_MODIFY(L) int __startStackIndex = lua_gettop((L));
#define KKP_END_STACK_MODIFY(L, i) while(lua_gettop((L)) > (__startStackIndex + (i))) lua_remove((L), __startStackIndex + 1);

@implementation KKPHelper
@end

#pragma mark - 帮助方法
bool kkp_recordLuaError(NSString *error)
{
    if (kkp_getLuaErrorHandler()) {
        kkp_getLuaErrorHandler()(error);
        return true;
    }
    
    return false;
}

int kkp_safeInLuaStack(lua_State *L, kkp_lua_stack_safe_block_t block)
{
    return kkp_performLocked(^int{
        int result = 0;
        KKP_BEGIN_STACK_MODIFY(L)
        if (block) {
            result = block();
        }
        KKP_END_STACK_MODIFY(L, result)
        return result;
    });
}

static NSRecursiveLock *lock = nil;

int kkp_performLocked(kkp_lua_lock_safe_block_t block) {
    int result = 0;
    
    if (lock == nil) {
        lock = [[NSRecursiveLock alloc] init];
    }
    [lock lock];
    result = block();
    [lock unlock];
    return result;
}

void traverse_table(lua_State *L, int index)
{
    lua_pushnil(L);
    while (lua_next(L, index)) {
        lua_pushvalue(L, -2);
        const char* key = lua_tostring(L, -1);
        int type = lua_type(L, -2);
        printf("%s => type %s", key, lua_typename(L, type));
        switch (type) {
            case LUA_TNUMBER:
                printf(" value=%f", lua_tonumber(L, -2));
                break;
            case LUA_TSTRING:
                printf(" value=%s", lua_tostring(L, -2));
                break;
            case LUA_TFUNCTION:
                if (lua_iscfunction(L, -2)) {
                    printf(" C:%p", lua_tocfunction(L, -2));
                }
        }
        printf("\n");
        lua_pop(L, 2);
    }
}

void kkp_stackDump(lua_State *L) {
    printf("------------ kkp_stackDump begin ------------\n");
    int top = lua_gettop(L);
    for (int i = 0; i < top; i++) {
        int positive = top - i;
        int negative = -(i + 1);
        int type = lua_type(L, positive);
        int typeN = lua_type(L, negative);
        assert(type == typeN);
        const char* typeName = lua_typename(L, type);
        printf("%d/%d: type=%s", positive, negative, typeName);
        switch (type) {
            case LUA_TBOOLEAN:
                printf(" value=%d", lua_toboolean(L, positive));
                break;
            case LUA_TNUMBER:
                printf(" value=%f", lua_tonumber(L, positive));
                break;
            case LUA_TSTRING:
                printf(" value=%s", lua_tostring(L, positive));
                break;
            case LUA_TFUNCTION:
                if (lua_iscfunction(L, positive)) {
                    printf(" C:%p", lua_tocfunction(L, positive));
                }
            case LUA_TUSERDATA:
                if (lua_isuserdata(L, positive)) {
                    printf(" C:%p", lua_touserdata(L, positive));
                }
            case LUA_TLIGHTUSERDATA:
                if (lua_isuserdata(L, positive)) {
                    printf(" Light C:%p", lua_touserdata(L, positive));
                }
            case LUA_TTABLE:
                if (lua_istable(L, positive)) {
                    printf("\nvalue=\n{\n");
                    traverse_table(L, positive);
                    printf("}\n");
                }
                break;
        }
        printf("\n");
    }
    printf("------------ kkp_stackDump end ------------\n\n");
}

#pragma mark - lua 调用相关

/// 用于获取 lua 调用运行时堆栈
/// 栈顶默认是错误消息，但是不包含堆栈信息，当能获取堆栈就使用 堆栈+错误信息，获取失败就使用 错误信息
int kkp_callRuntimeErrorFunction(lua_State *L) {
    lua_getglobal(L, "debug");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return 1;
    }

    lua_getfield(L, -1, "traceback");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return 1;
    }
    lua_remove(L, -2); // 移除 debug
    
    lua_call(L, 0, 1);
    lua_pushstring(L, "\n");
    lua_insert(L, -2);
    lua_concat(L, 3);// 把原始错误和堆栈拼接起来然后放到栈顶
    return 1;
}

/// 调用 lua 代码块
int kkp_pcall(lua_State *L, int argumentCount, int returnCount) {
    /// 把错误函数插入到函数和参数的前面
    lua_pushcfunction(L, kkp_callRuntimeErrorFunction);
    int errorFuncStackIndex = lua_gettop(L) - (argumentCount + 1);
    lua_insert(L, errorFuncStackIndex);
    
    int result = lua_pcall(L, argumentCount, returnCount, errorFuncStackIndex);
    lua_remove(L, errorFuncStackIndex);// 移除错误函数
    
    return result;
}

/// 运行 lua 字符串
int kkp_dostring(lua_State *L, const char *script) {
    int result = luaL_loadstring(L, script) || kkp_pcall(L, 0, LUA_MULTRET);
    
    if (result != 0) {
        NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(L, -1)];
        KKP_ERROR(L, log);
    }
    
    return result;
}

/// 运行 lua 文件
int kkp_dofile(lua_State *L, const char *fname) {
    int result = luaL_loadfile(L, fname) || kkp_pcall(L, 0, LUA_MULTRET);
    
    if (result != 0) {
        NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(L, -1)];
        KKP_ERROR(L, log);
    }
    
    return result;
}

/// 运行 lua 字节码
int kkp_dobuffer(lua_State *L, NSData *data, const char *name) {
    int result = luaL_loadbuffer(L, [data bytes], data.length, name) || kkp_pcall(L, 0, LUA_MULTRET);
    
    if (result != 0) {
        NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(L, -1)];
        KKP_ERROR(L, log);
    }
    
    return result;
}

/// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
const char* kkp_removeProtocolEncodings(const char *typeDescription)
{
    switch (typeDescription[0]) {
        case KKP_PROTOCOL_TYPE_CONST:
        case KKP_PROTOCOL_TYPE_INOUT:
        case KKP_PROTOCOL_TYPE_OUT:
        case KKP_PROTOCOL_TYPE_BYCOPY:
        case KKP_PROTOCOL_TYPE_BYREF:
        case KKP_PROTOCOL_TYPE_ONEWAY:
            return &typeDescription[1];
            break;
        default:
            return typeDescription;
            break;
    }
}

/// lua 函数名转成 oc 函数名时规则
/// 一个 _ 下划线转换成 :
/// 两个 __ 下划线转换成一个 _ 下划线
const char* kkp_toObjcSel(const char *luaFuncName)
{
    NSString* __autoreleasing s = [NSString stringWithFormat:@"%s", luaFuncName];
    s = [s stringByReplacingOccurrencesOfString:@"__" withString:@"!"];
    s = [s stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    s = [s stringByReplacingOccurrencesOfString:@"!" withString:@"_"];
    return s.UTF8String;
}

char* kkp_toObjcPropertySel(const char *prop)
{
    if (!prop) {
        return NULL;
    }
    size_t len = strlen(prop) + 3 + 2;
    char* func = malloc(len);
    memset(func, 0, len);
    
    char c = prop[0];
    if(c >= 'a' && c <= 'z') {
        c = c - 32;
    }
    
    strcpy(func, "set");
    memset(func+3, c, 1);
    strcpy(func+4, prop+1);
    strcat(func, ":");
    return func;
}

const char* kkp_toLuaFuncName(const char *objcSel)
{
    NSString* __autoreleasing s = [NSString stringWithFormat:@"%s", objcSel];
    s = [s stringByReplacingOccurrencesOfString:@"_" withString:@"__"];
    s = [s stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    return s.UTF8String;
}

NSString *kkp_trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NSString *kkp_removeAllWhiteSpace(NSString *string)
{
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [string stringByReplacingOccurrencesOfString:@"\\s" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
}

bool kkp_isAllocMethod(const char *methodName) {
    if (strncmp(methodName, "alloc", 5) == 0) {
        if (methodName[5] == '\0') return true; // It's just an alloc
        if (isupper(methodName[5]) || isdigit(methodName[5])) return YES; // It's alloc[A-Z0-9]
    }
    
    return false;
}

#pragma mark - lua 调用原生 block
bool kkp_isBlock(id object)
{
    Class klass = object_getClass(object);
    if (klass == NSClassFromString(@"__NSGlobalBlock__")
        || klass == NSClassFromString(@"__NSStackBlock__")
        || klass == NSClassFromString(@"__NSMallocBlock__")) {
        return true;
    }
    return false;
}

int kkp_callBlock(lua_State *L)
{
    KKPInstanceUserdata* instance = lua_touserdata(L, 1);
    id block = instance->instance;
    /// 获取 block 签名，比如 i12@?0i8
    KKPBlockDescription *blockDescription = [[KKPBlockDescription alloc] initWithBlock:block];
    NSMethodSignature *signature = blockDescription.blockSignature;
    
    int nresults = [signature methodReturnLength] ? 1 : 0;
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:block];
    
    for (unsigned long i = [signature numberOfArguments] - 1; i >= 1; i--) {
        const char *typeDescription = [signature getArgumentTypeAtIndex:i];
        void *pReturnValue = kkp_toOCObject(L, typeDescription, -1);
        [invocation setArgument:pReturnValue atIndex:i];
        
        if (pReturnValue != NULL) {
            free(pReturnValue);
        }
    }
    
    /// 调用 block 实现
    [invocation invoke];
    
    if (nresults > 0) {
        const char *typeDescription = [signature methodReturnType];
        NSUInteger size = 0;
        NSGetSizeAndAlignment(typeDescription, &size, NULL);
        void *buffer = malloc(size);
        [invocation getReturnValue:buffer];
        kkp_toLuaObjectWithBuffer(L, typeDescription, buffer);
        free(buffer);
    }
    
    return nresults;
}

#pragma mark - 原生调用 lua 函数

/// 通过 hook oc 的 实例方法和类方法来调用 lua 函数，并把 lua 函数调用结果返回到原生
int kkp_callLuaFunction(lua_State *L, __unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation)
{
    return kkp_safeInLuaStack(L, ^int{
        id slf = assignSlf;
        
        NSMethodSignature *signature = [slf methodSignatureForSelector:selector];
        int nargs = (int)[signature numberOfArguments] - 2;// 减 2 的目的，减去 self 和 _cmd 这个参数，因为 self 会作为环境 _ENV 的环境变量而存在，而 _cmd 也是不需要的
        int nresults = [signature methodReturnLength] ? 1 : 0;
        // 获取 class list table 并压栈
        luaL_getmetatable(L, KKP_CLASS_USER_DATA_LIST_TABLE);
        // in case self KVO ,object_getClassName(self) get wrong class
        // 从 class list table 获取指定名称的 userdata
        lua_getfield(L, -1, [NSStringFromClass([slf class]) UTF8String]);
        // 获取 class userdata 的关联表，并压栈
        lua_getuservalue(L, -1);
        
        BOOL deallocFlag = NO;
        if ([NSStringFromSelector(selector) isEqualToString:@"dealloc"]) {// 是否是实例对象释放了
            deallocFlag = YES;
        }
        
        // 获取关联表上 selector 对应的 lua 函数，并压栈
        if ([slf class] == slf) {// 说明是类方法调用，slf 是 class
            /// 类方法调用不需要设置什么，因为在定义时，已经设置了 class 关键字了
            NSString *staticSelectorName = [NSString stringWithFormat:@"%@%s", KKP_STATIC_PREFIX, sel_getName(selector)];
            lua_getfield(L, -1, kkp_toLuaFuncName(staticSelectorName.UTF8String));
            
            if (lua_isnil(L, -1)) {
                lua_pop(L, 1);
                lua_getfield(L, -1, kkp_toLuaFuncName(sel_getName(selector)));
            }
        } else {// 说明是实例方法调用
            /// 实例方法调用时，需要设置 self 关键字
            
            // 压入key
            lua_pushstring(L, [KKP_ENV_SCOPE UTF8String]);
            // 获取环境值压栈 associated_table["_scope"]
            lua_rawget(L, -2);
            
            // 压入 key
            lua_pushstring(L, [KKP_ENV_SCOPE_SELF UTF8String]);
            // 创建一个 oc 对象对应的 实例 userdata，并压栈，目的是把 实例 userdata 作为 lua 函数的第一个参数，也就是 self
            
            if (deallocFlag) {// 如果实例对象已经释放了话，就直接把实例 user data 压栈
                kkp_instance_pushUserdata(L, slf);
            } else {
                kkp_instance_create_userdata(L, slf);
            }
            
            // 给环境设置 _scope[self] = 实例 user data
            lua_rawset(L, -3);
            
            // 恢复栈
            lua_pop(L, 1);
            
            // 压入 lua 函数
            lua_getfield(L, -1, kkp_toLuaFuncName(sel_getName(selector)));
        }
        
        if (lua_isnil(L, -1)) {
            NSString* error = [NSString stringWithFormat:@"%s lua function get failed", sel_getName(selector)];
            KKP_ERROR(L, error);
        }
        
        // 如果有参数，就把参数转成 lua 对象，并压栈
        for (NSUInteger i = 2; i < [signature numberOfArguments]; i++) { // start at 2 because to skip the automatic self and _cmd arugments
            const char *typeDescription = [signature getArgumentTypeAtIndex:i];
            NSUInteger size = 0;
            NSGetSizeAndAlignment(typeDescription, &size, NULL);
            void *buffer = malloc(size);
            [invocation getArgument:buffer atIndex:i];
            kkp_toLuaObjectWithBuffer(L, typeDescription, buffer);
            free(buffer);
        }
        
        // 栈上有了 lua 函数，self 参数，和其他参数后，就可以调用 lua 函数了
        if (kkp_pcall(L, nargs, nresults)) {
            NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(L, -1)];
            KKP_ERROR(L, log);
        }
        
        if (deallocFlag) {// 调用完 lua dealloc 后，需要继续调用 oc 实例对象的 dealloc
            slf = nil;
            Class instClass = object_getClass(assignSlf);
            NSString *originSelectorName = [NSString stringWithFormat:@"%@%@", KKP_ORIGIN_PREFIX, NSStringFromSelector(selector)];
            
            Method deallocMethod = class_getInstanceMethod(instClass, NSSelectorFromString(originSelectorName));
            void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            originalDealloc(assignSlf, NSSelectorFromString(@"dealloc"));
        }
        
        return nresults;
    });
}

#pragma mark - lua 函数调用原生
static NSMutableDictionary *_propKeys;
static const void *kkp_propKey(NSString *propName) {
    if (!_propKeys) _propKeys = [[NSMutableDictionary alloc] init];
    id key = _propKeys[propName];
    if (!key) {
        key = [propName copy];
        [_propKeys setObject:key forKey:propName];
    }
    return (__bridge const void *)(key);
}

/// lua 层调用 c 层，在初始化时，需要先创建出来一个 实例对象的 实例 user data
/// 第一个参数是 class user data，而第一个 upvalue 则是之前捕获的 alloc 字符串
int kkp_alloc_closure(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        KKPInstanceUserdata *classUserData = lua_touserdata(L, 1);
        
        // 创建一个实例，并加入自动释放池，目的让 navigationController 可以接管实例，而后的下一个 runloop 才 release 一次实例，这样 实例的引用计数还是 1
        __autoreleasing id instance = [((Class)classUserData->instance) alloc];
        // 创建实例 user data
        kkp_instance_create_userdata(L, instance);
        return 1;
    });
}

/// lua 层调用 c 层
/// 比如调用是这样的： self:view()，在 lua 语法糖中，self:view() == self.view(self)，self 后面必须跟随冒号，否则闭包调用的时候获取不到 user data
/// 所以 第一个参数是 self（userdata，如果是调用实例方法就是 实例 user data，如果是调用类方法就是 class userdata），索引是 1，后面的索引全部都是参数了
/// 而第一个 upvalue 则是之前捕获的 view 字符串
int kkp_invoke_closure(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        KKPInstanceUserdata *instance = lua_touserdata(L, 1);
        if (instance && instance->instance) {
            Class klass = object_getClass(instance->instance);
            const char* func = lua_tostring(L, lua_upvalueindex(1));
            
            NSString *selectorName;
            selectorName = [NSString stringWithFormat:@"%s", kkp_toObjcSel(func)];
            // May be you call class function user static prefix, need to be remove
            selectorName = [selectorName stringByReplacingOccurrencesOfString:KKP_STATIC_PREFIX withString:@""];
            
            if (instance->isCallSuper) {// 如果是调用父类方法，就需要为当前类添加一个父类方法实现
                instance->isCallSuper = false;// 还原 super 到 false
                NSString *superSelectorName = [NSString stringWithFormat:@"%@%@", KKP_SUPER_PREFIX, selectorName];
                SEL superSelector = NSSelectorFromString(superSelectorName);
                Class klass = object_getClass(instance->instance);
                Class superClass = class_getSuperclass(klass);
                // 获取父类的方法实现
                Method superMethod = class_getInstanceMethod(superClass, NSSelectorFromString(selectorName));
                IMP superMethodImp = method_getImplementation(superMethod);
                char *typeDescription = (char *)method_getTypeEncoding(superMethod);
                // 如果是调用父类方法，就为当前类添加一个父类的实现
                class_addMethod(klass, superSelector, superMethodImp, typeDescription);
                selectorName = superSelectorName;
            } else if (instance->isCallOrigin) {// 如果是调用原始方法，就重新拼接原始方法前缀
                instance->isCallOrigin = false;// 还原 origin 到 false
                NSString *originSelectorName = [NSString stringWithFormat:@"%@%@", KKP_ORIGIN_PREFIX, selectorName];
                selectorName = originSelectorName;
            }
            
            SEL sel = NSSelectorFromString(selectorName);
            NSMethodSignature *signature = [klass instanceMethodSignatureForSelector:sel];
            if (signature) {
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                invocation.target = instance->instance;
                invocation.selector = sel;
                
                // args
                int nresults = [signature methodReturnLength] ? 1 : 0;
                for (int i = 2; i < [signature numberOfArguments]; i++) {
                    const char* typeDescription = [signature getArgumentTypeAtIndex:i];
                    void *argValue = kkp_toOCObject(L, typeDescription, i);
                    [invocation setArgument:argValue atIndex:i];
                    free(argValue);
                }
                /// 如果调用的方法被替换了，invoke 会触发 __KKP_ARE_BEING_CALLED__ 调用
                [invocation invoke];
                
                if (nresults > 0) {
                    const char *typeDescription = [signature methodReturnType];
                    NSUInteger size = 0;
                    NSGetSizeAndAlignment(typeDescription, &size, NULL);
                    void *buffer = malloc(size);
                    [invocation getReturnValue:buffer];
                    kkp_toLuaObjectWithBuffer(L, typeDescription, buffer);
                    free(buffer);
                }
                return nresults;
            } else {// 说明要调用的方法不存在
                if (!instance->isClass && instance->instance) {// 如果是实例的话，尝试把添加值到关联属性里
                    /// 计算参数个数，通过偏离 : 符号来确定个数
                    int argCount = 0;
                    const char *match = selectorName.UTF8String;
                    while ((match = strchr(match, ':'))) {
                        match += 1; // Skip past the matched char
                        argCount++;
                    }
                    
                    NSString *propName = selectorName;
                    propName = [propName stringByReplacingOccurrencesOfString:@"set" withString:@""];
                    propName = [propName stringByReplacingOccurrencesOfString:@":" withString:@""];
                    propName = [propName lowercaseString];
                    propName = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(klass), propName];
                    if (argCount == 1 && [selectorName hasPrefix:@"set"]) {// 说明调用的是设置属性
                        void *argValue = kkp_toOCObject(L, "@", 2);
                        
                        __unsafe_unretained id value;
                        value = (__bridge id)(*(void **)argValue);
                        
                        if (argValue != NULL) {
                            free(argValue);
                        }
                        
                        objc_setAssociatedObject(instance->instance, kkp_propKey(propName), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                        return 0;
                    } else if (argCount == 0) {// 说明调用的是获取属性
                        id value = objc_getAssociatedObject(instance->instance, kkp_propKey(propName));
                        if (value) {
                            kkp_toLuaObject(L, value);
                        } else {
                            lua_pushnil(L);
                        }
                        return 1;
                    }
                }
                
                NSString *error = [NSString stringWithFormat:@"unrecognized selector %@ for instance %@. ", selectorName, instance->instance];
                KKP_ERROR(L, error);
                return 0;
            }
        }
        return 0;
    });
}
