//
//  kkp_converter.m
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import "kkp_converter.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "lauxlib.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_class.h"
#import "kkp_instance.h"
#import "kkp_struct.h"
#import "KKPBlockWrapper.h"

#if CGFLOAT_IS_DOUBLE
#define CGFloatValue doubleValue
#else
#define CGFloatValue floatValue
#endif

/// 根据类型的可读性字符串签名, 构造真实签名
/// @param signatureStr 字符串参数类型 例'void,NSString*'
/// @param isAllArg 是否所有类型都是参数类型，不是的话，就需要把第一个类型当做返回值类型
/// @param isBlock 是否构造block签名
NSString *kkp_create_real_signature(NSString *signatureStr, BOOL isAllArg, BOOL isBlock)
{
    static NSMutableDictionary *typeSignatureDict;
    if (!typeSignatureDict) {
        //        https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100
        typeSignatureDict =
            [NSMutableDictionary dictionaryWithObject:[NSString stringWithUTF8String:@encode(dispatch_block_t)]
                                               forKey:@"?"];
#define KKP_DEFINE_TYPE_SIGNATURE(_type) \
    [typeSignatureDict setObject:[NSString stringWithUTF8String:@encode(_type)] forKey:kkp_removeAllWhiteSpace(@ #_type)];

        KKP_DEFINE_TYPE_SIGNATURE(id);
        KKP_DEFINE_TYPE_SIGNATURE(BOOL);
        KKP_DEFINE_TYPE_SIGNATURE(int);
        KKP_DEFINE_TYPE_SIGNATURE(void);
        KKP_DEFINE_TYPE_SIGNATURE(char);
        KKP_DEFINE_TYPE_SIGNATURE(char *);
        KKP_DEFINE_TYPE_SIGNATURE(short);
        KKP_DEFINE_TYPE_SIGNATURE(unsigned short);
        KKP_DEFINE_TYPE_SIGNATURE(unsigned int);
        KKP_DEFINE_TYPE_SIGNATURE(long);
        KKP_DEFINE_TYPE_SIGNATURE(unsigned long);
        KKP_DEFINE_TYPE_SIGNATURE(long long);
        KKP_DEFINE_TYPE_SIGNATURE(unsigned long long);
        KKP_DEFINE_TYPE_SIGNATURE(float);
        KKP_DEFINE_TYPE_SIGNATURE(double);
        KKP_DEFINE_TYPE_SIGNATURE(bool);
        KKP_DEFINE_TYPE_SIGNATURE(size_t);
        KKP_DEFINE_TYPE_SIGNATURE(CGFloat);
        KKP_DEFINE_TYPE_SIGNATURE(CGSize);
        KKP_DEFINE_TYPE_SIGNATURE(CGRect);
        KKP_DEFINE_TYPE_SIGNATURE(CGPoint);
        KKP_DEFINE_TYPE_SIGNATURE(CGVector);
        KKP_DEFINE_TYPE_SIGNATURE(NSRange);
        KKP_DEFINE_TYPE_SIGNATURE(NSInteger);
        KKP_DEFINE_TYPE_SIGNATURE(Class);
        KKP_DEFINE_TYPE_SIGNATURE(SEL);
        KKP_DEFINE_TYPE_SIGNATURE(void *);
    }
    
    /// 如果类型签名里包含结构体，比如 void,{XPoint4={XPoint3=int,int}int,int}，这样的字符串以逗号分割会有问题，需要先把结构体相关字符串的逗号转成下划线，然后在使用的时候还原成逗号
    NSString *mutableString = [signatureStr copy];
    NSInteger leftIndex = 0;
    NSInteger rightIndex = 0;
    NSInteger leftCount = 0;
    NSInteger rightCount = 0;
    for (NSInteger i = 0; i < signatureStr.length; i++) {
        char chr = [signatureStr characterAtIndex:i];
        if (chr == '{') {
            leftCount++;
            if (leftCount == 1) {
                leftIndex = i;
            }
        } else if (chr == '}') {
            rightCount++;
        }
        
        if (leftCount == rightCount && chr == '}') {// 当相等的时候，说明左括号和右括号匹对上了，就先把这部分字符串中含有的逗号换成下划线
            rightIndex = i;
            leftCount = 0;
            rightCount = 0;
            mutableString = [mutableString stringByReplacingOccurrencesOfString:@"," withString:@"_" options:0 range:NSMakeRange(leftIndex, rightIndex - leftIndex + 1)];
        }
    }
    
    NSArray *lt = [mutableString componentsSeparatedByString:@","];
    
    NSMutableString *funcSignature;
    NSInteger fromIndex = 0;
    
    if (isAllArg) {
        fromIndex = 0;// 0 表示是参数签名，所有类型都是参数类型
        funcSignature = [NSMutableString new];
    } else {
        /**
         * 这里注意下block与func签名要区分下,block中没有_cmd, 并且要用@?便是target
         * 比如 block 签名：i@?i
         * 比如 非 block 签名 i@:i
         */
        funcSignature = [[NSMutableString alloc] initWithString:isBlock ? @"@?" : @"@:"];
        fromIndex = 1; // 1 表示是方法签名，第一个类型是返回类型，后面的类型是参数类型
    }
    
    for (NSInteger i = fromIndex; i < lt.count; i++) {
        // 去掉两边空格
        NSString *inputType = kkp_removeAllWhiteSpace(lt[i]);
        NSString *outputType = typeSignatureDict[inputType];
        if (!outputType) {
            if ([inputType containsString:@"*"]) {// 说明是一个对象指针，就设置默认类型 @
                outputType = @"@";
            } else {// 如果不存在，就以输入为准，比如，输入的是 i 而非 int，那么这个时候 i 找不到对应的类型编码，那就以输入的 i 为准
                outputType = inputType;
            }
        }
        
        // 比如是下面几种情况，都需要进行处理，统一转换成 {XRect=iiff}
        // {XRect={XPoint=ii}ff} 或者 {XRect=iiff} 或者 {XRect={XPoint=int,int}float,float} 或者 {XRect=int,int,float,float}
        if ([outputType characterAtIndex:0] == '{') {// 说明签名里包含结构体，需要把结构体也进行解析
            NSString *types = kkp_parseStructFromTypeDescription(outputType, YES, [outputType containsString:@"_"] ? @"_" : nil);
            NSArray *structWithType = [types componentsSeparatedByString:@"="];
            if (structWithType.count > 1) {
                NSString *structName = structWithType.firstObject;
                // typeString 是 iiff 或者 int,int,float,float
                NSString *typeString = structWithType.lastObject;
                if ([typeString containsString:@"_"]) {// 如果包含下划线(也就是逗号)，就需要把 int,int,float,float 转成 iiff
                    typeString = [typeString stringByReplacingOccurrencesOfString:@"_" withString:@"," options:0 range:NSMakeRange(0, typeString.length)];
                    typeString = kkp_create_real_signature(typeString, YES, isBlock);
                }
                outputType = [NSString stringWithFormat:@"{%@=%@}", structName, typeString];
            }
        }
        
        if (!isBlock &&
            ([outputType isEqualToString:[NSString stringWithUTF8String:@encode(void)]] ||
             strcmp(outputType.UTF8String, "v") == 0)) {// 如果是方法，遇到 void 就跳过
            continue;
        }
        
        [funcSignature appendFormat:@"%@", outputType];
    }
    
    if (!isAllArg) {
        /// 最后处理返回类型
        NSString *inputType = kkp_removeAllWhiteSpace(lt[0]);
        NSString *outputType = typeSignatureDict[inputType];
        if (!outputType) {
            if ([inputType containsString:@"*"]) {// 说明是一个对象指针，就设置默认类型 @
                outputType = @"@";
            } else {// 如果不存在，就以输入为准，比如，输入的是 i 而非 int，那么这个时候 i 找不到对应的类型编码，那就以输入的 i 为准
                outputType = inputType;
            }
        }
        
        // 比如是下面几种情况，都需要进行处理，统一转换成 {XRect=iiff}
        // {XRect={XPoint=ii}ff} 或者 {XRect=iiff} 或者 {XRect={XPoint=int,int}float,float} 或者 {XRect=int,int,float,float}
        if ([outputType characterAtIndex:0] == '{') {// 说明签名里包含结构体，需要把结构体也进行解析
            NSString *types = kkp_parseStructFromTypeDescription(outputType, YES, [outputType containsString:@"_"] ? @"_" : nil);
            NSArray *structWithType = [types componentsSeparatedByString:@"="];
            if (structWithType.count > 1) {
                NSString *structName = structWithType.firstObject;
                // typeString 是 iiff 或者 int,int,float,float
                NSString *typeString = structWithType.lastObject;
                if ([typeString containsString:@"_"]) {// 如果包含下划线(也就是逗号)，就需要把 int,int,float,float 转成 iiff
                    typeString = [typeString stringByReplacingOccurrencesOfString:@"_" withString:@"," options:0 range:NSMakeRange(0, typeString.length)];
                    typeString = kkp_create_real_signature(typeString, YES, isBlock);
                }
                outputType = [NSString stringWithFormat:@"{%@=%@}", structName, typeString];
            }
        }
        
        [funcSignature insertString:[NSString stringWithFormat:@"%@", outputType] atIndex:0];
    }

    return funcSignature;
}

/// 根据原生结构体的类型签名转成数组 [结构体名字，真实签名]
/// 比如：{CGSize=dd} 转成 CGSize=dd
/// 比如：嵌套 {XRect={XPoint=ii}ff} 转成  XRect=iiff
/// 比如：嵌套 {CGRect={CGPoint=dd}{CGSize=dd}} 转成 CGRect=dddd
NSString * kkp_parseStructFromTypeDescription(NSString *typeDes, BOOL needStructName, NSString *replaceRightBracket)
{
    if (typeDes.length == 0) {
        return nil;
    }
 
    NSMutableString *parsingTypes = [NSMutableString new];
    
    NSString *types = [typeDes substringToIndex:typeDes.length - 1];
    NSUInteger location = [types rangeOfString:@"="].location + 1;
    NSString *structName = [typeDes substringWithRange:NSMakeRange(1, location - 1)];
    [parsingTypes appendString:structName];
    
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
        
        NSInteger equalLocation = [subTypeEncoding rangeOfString:@"="].location;
        if (equalLocation != NSNotFound) {
            NSInteger end = [subTypeEncoding rangeOfString:@"}"].location;
            subTypeEncoding = [subTypeEncoding substringWithRange:NSMakeRange(equalLocation + 1, end - (equalLocation + 1))];
            [parsingTypes appendString:subTypeEncoding];
            if (replaceRightBracket) {
                [parsingTypes appendString:replaceRightBracket];
            }
        } else {
            [parsingTypes appendString:subTypeEncoding];
        }
    
        subCount++;
    }
    
    if (replaceRightBracket && [parsingTypes hasSuffix:replaceRightBracket]) {// 去掉最后一个 replaceRightBracket
        [parsingTypes deleteCharactersInRange:NSMakeRange(0, parsingTypes.length - replaceRightBracket.length)];
    }
    
    return parsingTypes;
}

/// 把原生结构体转成 struct user data
int kkp_createStructUserDataWithBuffer(lua_State *L, const char * typeDescription, void *buffer)
{
    NSString *types = kkp_parseStructFromTypeDescription([NSString stringWithUTF8String:typeDescription], YES, nil);
    NSArray *structWithType = [types componentsSeparatedByString:@"="];
    if (structWithType.count > 1) {
        NSString *structName = structWithType.firstObject;
        NSString *typeString = structWithType.lastObject;
        kkp_struct_create_userdata(L, structName.UTF8String, typeString.UTF8String, buffer);
    } else {
        KKP_ERROR(L, @"Parsing struct type description failed");
    }
    
    return 1;
}

/// 把 lua 栈的数据转换成 oc 对象
/// 根据 oc 参数或者返回值类型签名，转成 oc 对象的指针
/// 如果是基本数据类型，则返回基本数据类型的指针，比如 type 是 int，则返回的是 int *
/// 如果是指针数据类型，则返回指针数据类型的指针，比如 type 是 void *，则返回的是 void **
void * kkp_toOCObject(lua_State *L, const char * typeDescription, int index)
{
    void *value = NULL;
    const char *type = kkp_removeProtocolEncodings(typeDescription);
    
    if (type[0] == _C_VOID) {
        return NULL;
    } else if (type[0] == _C_BOOL) {
        value = malloc(sizeof(BOOL));
        *((BOOL *)value) = (BOOL)( lua_isstring(L, index) ? lua_tostring(L, index)[0] : lua_toboolean(L, index));
    } else if (type[0] == _C_CHR) {
        value = malloc(sizeof(char));
        if (lua_type(L, index) == LUA_TNUMBER){//There should be corresponding with kkp_toLuaObjectWithBuffer, otherwise the incoming char by kkp_toLuaObjectWithBuffer into number, and then through the wax_copyToObjc into strings are truncated.（如'a'->97->'9'）
            *((char *)value) = (char)lua_tonumber(L, index);
        } else if(lua_type(L, index) == LUA_TSTRING){
            *((char *)value) = (char)lua_tostring(L, index)[0];
        } else{//32 bit BOOL is char
            *((char *)value) = (char)lua_toboolean(L, index);
        }
    }
    
#define KKP_TO_NUMBER_CONVERT(T) else if (type[0] == @encode(T)[0]) { value = malloc(sizeof(T)); *((T *)value) = (T)lua_tonumber(L, index); }
    
    KKP_TO_NUMBER_CONVERT(int)
    KKP_TO_NUMBER_CONVERT(short)
    KKP_TO_NUMBER_CONVERT(long)
    KKP_TO_NUMBER_CONVERT(long long)
    KKP_TO_NUMBER_CONVERT(unsigned int)
    KKP_TO_NUMBER_CONVERT(unsigned short)
    KKP_TO_NUMBER_CONVERT(unsigned long)
    KKP_TO_NUMBER_CONVERT(unsigned long long)
    KKP_TO_NUMBER_CONVERT(float)
    KKP_TO_NUMBER_CONVERT(double)
    
    else if (type[0] == _C_CHARPTR) {
        const char *string = lua_tostring(L, index);
        value = malloc(sizeof(char *));
        memcpy(value, &string, sizeof(char*));
    } else if (type[0] == @encode(SEL)[0]) {
        if (lua_isnil(L, index)) { // If no slector is passed it, just use an empty string
            lua_pushstring(L, "");
            lua_replace(L, index);
        }
        
        value = malloc(sizeof(SEL));
        const char *selectorName = luaL_checkstring(L, index);
        *((SEL *)value) = sel_getUid(selectorName);
    } else if (type[0] == _C_CLASS) {
        value = malloc(sizeof(Class));
        if (lua_isuserdata(L, index)) {
            KKPInstanceUserdata *instanceUserdata = (KKPInstanceUserdata *)luaL_checkudata(L, index, KKP_CLASS_USER_DATA_META_TABLE);
            //https://www.jianshu.com/p/5fbe5478e24b
            *(__unsafe_unretained id *)value = instanceUserdata->instance;
        }
        else {
            *((Class *)value) = objc_getClass(lua_tostring(L, index));
        }
    } else if (type[0] == _C_ID) {
        value = malloc(sizeof(id));
        id instance = nil;
        
        switch (lua_type(L, index)) {
            case LUA_TNIL:
            case LUA_TNONE:
                instance = nil;
                break;
            case LUA_TBOOLEAN: {
                BOOL flag = lua_toboolean(L, index);
                instance = [NSValue valueWithBytes:&flag objCType:@encode(bool)];
                
                if (instance) {
                    __autoreleasing id temp = instance;
                    *(void **)value = (__bridge void *)temp;
                }
                break;
            }
            case LUA_TNUMBER:
                instance = [NSNumber numberWithDouble:lua_tonumber(L, index)];
                
                if (instance) {
                    __autoreleasing id temp = instance;
                    *(void **)value = (__bridge void *)temp;
                }
                break;
            case LUA_TSTRING:
            {
                instance = [NSString stringWithUTF8String:lua_tostring(L, index)];
                
                if (instance) {
                    // 对于创建的 OC 对象，如果不引用下，在返回的时候就会被释放掉了。所以这里用 __autoreleasing 修饰下，让他在下个循环释放
                    
                    __autoreleasing id temp = instance;
                    *(void **)value = (__bridge void *)temp;
                }
                break;
            }
            case LUA_TTABLE:
            {
                BOOL dictionary = NO;
                
                lua_pushvalue(L, index); // Push the table reference on the top
                lua_pushnil(L);  /* first key */
                while (!dictionary && lua_next(L, -2)) {
                    if (lua_type(L, -2) != LUA_TNUMBER) {
                        dictionary = YES;
                        lua_pop(L, 2); // pop key and value off the stack
                    } else {
                        lua_pop(L, 1);
                    }
                }
                
                if (dictionary) {
                    instance = [NSMutableDictionary dictionary];
                    
                    lua_pushnil(L);  /* first key */
                    while (lua_next(L, -2)) {
                        void *keyArg = kkp_toOCObject(L, "@", -2);
                        __unsafe_unretained id key;
                        key = (__bridge id)(*(void **)keyArg);
                        
                        void *valueArg = kkp_toOCObject(L, "@", -1);
                        __unsafe_unretained id object;
                        object = (__bridge id)(*(void **)valueArg);
                        
                        [instance setObject:object forKey:key];
                        lua_pop(L, 1); // Pop off the value
                        
                        if (keyArg != NULL) {
                            free(keyArg);
                        }
                        
                        if (valueArg != NULL) {
                            free(valueArg);
                        }
                    }
                } else {
                    instance = [NSMutableArray array];
                    
                    lua_pushnil(L);  /* first key */
                    while (lua_next(L, -2)) {
                        int index = lua_tonumber(L, -2) - 1;
                        
                        void *valueArg = kkp_toOCObject(L, "@", -1);
                        __unsafe_unretained id object;
                        object = (__bridge id)(*(void **)valueArg);
                        
                        [instance insertObject:object atIndex:index];
                        lua_pop(L, 1);
                        
                        if (valueArg != NULL) {
                            free(valueArg);
                        }
                    }
                }
                
                lua_pop(L, 1); // Pop the table reference off
                
                if (instance) {
                    __autoreleasing id temp = instance;
                    *(void **)value = (__bridge void *)temp;
                }
                break;
            }
            case LUA_TUSERDATA:
            {
                KKPInstanceUserdata *userdata = lua_touserdata(L, index);
                if (userdata && userdata->instance) {
                    instance = userdata->instance;
                } else {
                    instance = nil;
                }
                
                if (instance) {
                    // 不是创建的对象，没必要增加引用
                    __unsafe_unretained id temp = instance;
                    *(void **)value = (__bridge void *)temp;
                }
                break;
            }
            case LUA_TLIGHTUSERDATA: {
                instance = (__bridge id)lua_touserdata(L, -1);
                
                /// 目前 block 指针会走这里
                /// [block blockPtr]
                if (instance) {
                    __unsafe_unretained id temp = instance;
                    *(void **)value = (__bridge void *)temp;
                }
                break;
            }
            default:
            {
                free(value);
                NSString *error = [NSString stringWithFormat:@"Can't convert %s to obj-c.", luaL_typename(L, index)];
                KKP_ERROR(L, error);
                return NULL;
            }
        }
    } else if (type[0] == _C_STRUCT_B) {
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)luaL_checkudata(L, index, KKP_STRUCT_USER_DATA_META_TABLE);
        value = malloc(structUserdata->size);
        memcpy(value, structUserdata->data, structUserdata->size);
    } else if (type[0] == _C_PTR) {
        value = malloc(sizeof(void *));
        void *pointer = nil;
        
        switch (typeDescription[1]) {
            case _C_VOID:
            case _C_ID: {
                switch (lua_type(L, index)) {
                    case LUA_TNIL:
                    case LUA_TNONE:
                        break;
                        
                    case LUA_TUSERDATA: {
                        KKPInstanceUserdata *instanceUserdata = (KKPInstanceUserdata *)luaL_checkudata(L, index, KKP_INSTANCE_USER_DATA_META_TABLE);
                        if (typeDescription[1] == _C_VOID) {
                            pointer = (__bridge void *)(instanceUserdata->instance);
                        } else {
                            pointer = &instanceUserdata->instance;
                        }

                        break;
                    }
                    case LUA_TLIGHTUSERDATA:
                        pointer = lua_touserdata(L, index);
                        break;
                    default: {
                        NSString *error = [NSString stringWithFormat:@"Can't convert %s to KKPInstanceUserdata.", luaL_typename(L, index)];
                        KKP_ERROR(L, error);
                        break;
                    }
                }
                break;
            }
            default:
                if (lua_islightuserdata(L, index)) {
                    pointer = lua_touserdata(L, index);
                } else {
                    free(value);
                    NSString *error = [NSString stringWithFormat:@"Converstion from %s to Objective-c not implemented.", typeDescription];
                    KKP_ERROR(L, error);
                }
        }
        
        if (pointer) {
            memcpy(value, &pointer, sizeof(void *));
        }
    } else {
        NSString* error = [NSString stringWithFormat:@"type %s in not support !", typeDescription];
        KKP_ERROR(L, error);
        return NULL;
    }
    return value;
}

int kkp_toLuaObject(lua_State *L, id object)
{
    return kkp_safeInLuaStack(L, ^int{
        if ([object isKindOfClass:[NSString class]]) {
            lua_pushstring(L, [object UTF8String]);
        } else if ([object isKindOfClass:[NSNumber class]]) {
            lua_pushnumber(L, [object doubleValue]);
        } else if ([object isKindOfClass:[NSArray class]]) {
            lua_newtable(L);
            for (NSInteger i = 0; i < [object count]; i++) {
                lua_pushnumber(L, i+1);
                kkp_toLuaObject(L, object[i]);
                lua_settable(L, -3);
            }
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            lua_newtable(L);
            [object enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                kkp_toLuaObject(L, key);
                kkp_toLuaObject(L, obj);
                lua_settable(L, -3);
            }];
        } else {
            /// oc block 或者其他 oc 对象都会走这里去创建 实例 user data
            /// 如果是 block 话，创建出来的 block user data 在 lua 脚本里可以通过 block_user_data() 的形式，来触发 LUserData_kkp_instance__call 调用，然后通过 kkp_callBlock 来调用实际 oc block
            kkp_instance_create_userdata(L, object);
        }
        return 1;
    });
}

/// 根据类型签名，把 buffer 数据转换成 lua 类型数据并压栈
int kkp_toLuaObjectWithBuffer(lua_State *L, const char * typeDescription, void *buffer)
{
    return kkp_safeInLuaStack(L, ^int{
        const char * type = kkp_removeProtocolEncodings(typeDescription);
        
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100
        if (type[0] == _C_VOID) {// 没有返回值
            lua_pushnil(L);
        } else if (type[0] == _C_PTR) {// 返回值是 指针 类型
            lua_pushlightuserdata(L, *(void **)buffer);
        }
        
#define NUMBER_TO_KKP_CONVERT(T) else if (type[0] == @encode(T)[0]) { lua_pushnumber(L, *(T *)buffer); }
        
        NUMBER_TO_KKP_CONVERT(char)
        NUMBER_TO_KKP_CONVERT(unsigned char)
        NUMBER_TO_KKP_CONVERT(int)
        NUMBER_TO_KKP_CONVERT(short)
        NUMBER_TO_KKP_CONVERT(long)
        NUMBER_TO_KKP_CONVERT(long long)
        NUMBER_TO_KKP_CONVERT(unsigned int)
        NUMBER_TO_KKP_CONVERT(unsigned short)
        NUMBER_TO_KKP_CONVERT(unsigned long)
        NUMBER_TO_KKP_CONVERT(unsigned long long)
        NUMBER_TO_KKP_CONVERT(float)
        NUMBER_TO_KKP_CONVERT(double)
        
        else if (type[0] == _C_BOOL) {// 返回值是 布尔 类型
            lua_pushboolean(L, *(bool *)buffer);
        } else if (type[0] == _C_CHARPTR) {// 返回值是 字符串 类型
            lua_pushstring(L, *(char **)buffer);
        } else if (type[0] == _C_SEL) {// 返回值是 选择器 类型
            lua_pushstring(L, sel_getName(*(SEL *)buffer));
        } else if (type[0] == _C_ID) {// 返回值是 OC 对象 类型
            /**
             A bridged cast is a C-style cast annotated with one of three keywords:

             (__bridge T) op casts the operand to the destination type T. If T is a retainable object pointer type, then op must have a non-retainable pointer type. If T is a non-retainable pointer type, then op must have a retainable object pointer type. Otherwise the cast is ill-formed. There is no transfer of ownership, and ARC inserts no retain operations.
             (__bridge_retained T) op casts the operand, which must have retainable object pointer type, to the destination type, which must be a non-retainable pointer type. ARC retains the value, subject to the usual optimizations on local values, and the recipient is responsible for balancing that +1.
             (__bridge_transfer T) op casts the operand, which must have non-retainable pointer type, to the destination type, which must be a retainable object pointer type. ARC will release the value at the end of the enclosing full-expression, subject to the usual optimizations on local values.
             
             __bridge 转换Objective-C 和 Core Foundation 指针，不移交持有权.
             __bridge_retained 或 CFBridgingRetain 转换 Objective-C 指针到Core Foundation 指针并移交持有权.
             你要负责调用 CFRelease 或一个相关的函数来释放对象.
             __bridge_transfer 或 CFBridgingRelease 传递一个非Objective-C 指针到 Objective-C 指针并移交持有权给ARC. ARC负责释放对象.
             
             */

            // id instance = *((__unsafe_unretained id *)buffer); 这种写法也可以
            __unsafe_unretained id instance;
            instance = (__bridge id)(*(void **)buffer);
            
            /// 创建 实例 user data
            kkp_toLuaObject(L, instance);
        } else if (type[0] == _C_CLASS) {// 返回值是 class 类型
            __unsafe_unretained id instance;
            instance = (__bridge id)(*(void **)buffer);
            
            /// 创建 类 user data
            kkp_class_create_userdata(L, instance);
        } else if (type[0] == _C_STRUCT_B) {// 返回值是 结构体 类型
            kkp_createStructUserDataWithBuffer(L, typeDescription, buffer);
        }
        else {
            NSString* error = [NSString stringWithFormat:@"Unable to convert Obj-C type with type description '%s'", typeDescription];
            KKP_ERROR(L, error);
            return 0;
        }
        
        return 1;
    });
}

/// 根据类型描述，计算出结构体占用的字节大小
int kkp_sizeOfStructTypes(const char *typeDescription)
{
    NSString *typeString = [NSString stringWithUTF8String:typeDescription];
    int index = 0;
    int size = 0;
    while (typeDescription[index]) {
        switch (typeDescription[index]) {
            #define KKP_STRUCT_SIZE_CASE(_typeChar, _type)   \
            case _typeChar: \
                size += sizeof(_type);  \
                break;
                
            KKP_STRUCT_SIZE_CASE('c', char)
            KKP_STRUCT_SIZE_CASE('C', unsigned char)
            KKP_STRUCT_SIZE_CASE('s', short)
            KKP_STRUCT_SIZE_CASE('S', unsigned short)
            KKP_STRUCT_SIZE_CASE('i', int)
            KKP_STRUCT_SIZE_CASE('I', unsigned int)
            KKP_STRUCT_SIZE_CASE('l', long)
            KKP_STRUCT_SIZE_CASE('L', unsigned long)
            KKP_STRUCT_SIZE_CASE('q', long long)
            KKP_STRUCT_SIZE_CASE('Q', unsigned long long)
            KKP_STRUCT_SIZE_CASE('f', float)
            KKP_STRUCT_SIZE_CASE('F', CGFloat)
            KKP_STRUCT_SIZE_CASE('N', NSInteger)
            KKP_STRUCT_SIZE_CASE('U', NSUInteger)
            KKP_STRUCT_SIZE_CASE('d', double)
            KKP_STRUCT_SIZE_CASE('B', BOOL)
            KKP_STRUCT_SIZE_CASE('*', void *)
            KKP_STRUCT_SIZE_CASE('^', void *)
            
            case '{': {// 结构体嵌套
                NSString *structTypeStr = [typeString substringFromIndex:index];
                NSUInteger end = [structTypeStr rangeOfString:@"}"].location;
                if (end != NSNotFound) {
                    NSUInteger location = [structTypeStr rangeOfString:@"="].location + 1;
                    NSString *subStructTypes = [structTypeStr substringFromIndex:location];
                    size += kkp_sizeOfStructTypes([subStructTypes UTF8String]);
                    index += (int)end;
                    break;
                }
            }
            
            default:
                break;
        }
        index ++;
    }
    return size;
}

/// 把结构体数组的数据往结构体指针指向的内存里填充
void kkp_getStructDataOfArray(void *structData, NSArray *structArray, const char *typeDescription)
{
    NSString *typeString = [NSString stringWithUTF8String:typeDescription];
    
    int index = 0;
    int position = 0;
    for (int i = 0; i < structArray.count; i++) {
        switch(typeDescription[index]) {
            #define KKP_STRUCT_DATA_CASE(_typeStr, _type, _transMethod) \
            case _typeStr: { \
                int size = sizeof(_type);    \
                _type val = [structArray[i] _transMethod];   \
                memcpy(structData + position, &val, size);  \
                position += size;    \
                break;  \
            }
            KKP_STRUCT_DATA_CASE('c', char, charValue)
            KKP_STRUCT_DATA_CASE('C', unsigned char, unsignedCharValue)
            KKP_STRUCT_DATA_CASE('s', short, shortValue)
            KKP_STRUCT_DATA_CASE('S', unsigned short, unsignedShortValue)
            KKP_STRUCT_DATA_CASE('i', int, intValue)
            KKP_STRUCT_DATA_CASE('I', unsigned int, unsignedIntValue)
            KKP_STRUCT_DATA_CASE('l', long, longValue)
            KKP_STRUCT_DATA_CASE('L', unsigned long, unsignedLongValue)
            KKP_STRUCT_DATA_CASE('q', long long, longLongValue)
            KKP_STRUCT_DATA_CASE('Q', unsigned long long, unsignedLongLongValue)
            KKP_STRUCT_DATA_CASE('f', float, floatValue)
            KKP_STRUCT_DATA_CASE('F', CGFloat, CGFloatValue)
            KKP_STRUCT_DATA_CASE('d', double, doubleValue)
            KKP_STRUCT_DATA_CASE('B', BOOL, boolValue)
            KKP_STRUCT_DATA_CASE('N', NSInteger, integerValue)
            KKP_STRUCT_DATA_CASE('U', NSUInteger, unsignedIntegerValue)
            
            case '*':
            case '^': {
                int size = sizeof(void *);
                void *val = (__bridge void *)(structArray[i]);
                memcpy(structData + position, &val, size);
                break;
            }
            case '{': {// 处理结构体嵌套场景
                NSString *structTypeStr = [typeString substringFromIndex:index];
                NSUInteger end = [structTypeStr rangeOfString:@"}"].location;
                if (end != NSNotFound) {
                    NSUInteger location = [structTypeStr rangeOfString:@"="].location + 1;
                    NSString *subStructTypes = [structTypeStr substringFromIndex:location];
                    int size = kkp_sizeOfStructTypes(subStructTypes.UTF8String);
                    kkp_getStructDataOfArray(structData + position, structArray[i], subStructTypes.UTF8String);
                    position += size;
                    index += end;
                    break;
                }
            }
            default:
                break;
        }
        index++;
    }
}

/// 把结构体字指针指向的内存数据转换成数组
NSArray * kkp_getArrayOfStructData(void *structData, const char *typeDescription)
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *typeString = [NSString stringWithUTF8String:typeDescription];
    
    int index = 0;
    int position = 0;
    for (int i = 0; i < typeString.length; i++) {
        switch(typeDescription[index]) {
            #define KKP_STRUCT_DICT_CASE(_typeName, _type)   \
            case _typeName: { \
                size_t size = sizeof(_type); \
                _type *val = malloc(size);   \
                memcpy(val, structData + position, size);   \
                [array addObject:@(*val)];    \
                free(val);  \
                position += size;   \
                break;  \
            }
            KKP_STRUCT_DICT_CASE('c', char)
            KKP_STRUCT_DICT_CASE('C', unsigned char)
            KKP_STRUCT_DICT_CASE('s', short)
            KKP_STRUCT_DICT_CASE('S', unsigned short)
            KKP_STRUCT_DICT_CASE('i', int)
            KKP_STRUCT_DICT_CASE('I', unsigned int)
            KKP_STRUCT_DICT_CASE('l', long)
            KKP_STRUCT_DICT_CASE('L', unsigned long)
            KKP_STRUCT_DICT_CASE('q', long long)
            KKP_STRUCT_DICT_CASE('Q', unsigned long long)
            KKP_STRUCT_DICT_CASE('f', float)
            KKP_STRUCT_DICT_CASE('F', CGFloat)
            KKP_STRUCT_DICT_CASE('N', NSInteger)
            KKP_STRUCT_DICT_CASE('U', NSUInteger)
            KKP_STRUCT_DICT_CASE('d', double)
            KKP_STRUCT_DICT_CASE('B', BOOL)
            
            case '*':
            case '^': {
                size_t size = sizeof(void *);
                void *val = malloc(size);
                memcpy(val, structData + position, size);
                [array addObject:(__bridge id)(val)];
                position += size;
                break;
            }
            case '{': {// 处理结构体嵌套场景
                NSString *structTypeStr = [typeString substringFromIndex:index];
                NSUInteger end = [structTypeStr rangeOfString:@"}"].location;
                if (end != NSNotFound) {
                    NSUInteger location = [structTypeStr rangeOfString:@"="].location + 1;
                    NSString *subStructTypes = [structTypeStr substringFromIndex:location];
                    NSArray *subArray = kkp_getArrayOfStructData(structData + position, subStructTypes.UTF8String);
                    [array addObject:subArray];
                    position += kkp_sizeOfStructTypes([subStructTypes UTF8String]);
                    index += end;
                    break;
                }
            }
        }
        index++;
    }
    return array;
}
