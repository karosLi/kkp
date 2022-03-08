//
//  kkp_class.m
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import "kkp_class.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "lauxlib.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_runtime_helper.h"
#import "kkp_instance.h"
#import "kkp_converter.h"
#import "KKPBlockWrapper.h"

#pragma mark - 记录重写过的方法
/// 用于记录替换过的方法
@interface KKPClassMethodReplaceRecord : NSObject
@property(nonatomic, copy) NSString *className;
@property(nonatomic, copy) NSString *selecotorName;
@property(nonatomic, assign) BOOL isInstanceMethod;// 是否是实例方法，如果不是，那就是类方法
@property(nonatomic, assign) BOOL isReplaceMethod;// 是否是替换方法，如果不是，那就是添加方法
@end

@implementation KKPClassMethodReplaceRecord
@end

/// 用于记录替换过的方法
static NSMutableDictionary *_KKPOverrideMethods = nil;
static void kkp_class_recordOverideMethods(Class cls, NSString *selectorName, KKPClassMethodReplaceRecord *record)
{
    if (!_KKPOverrideMethods) {
        _KKPOverrideMethods = [[NSMutableDictionary alloc] init];
    }
    if (!_KKPOverrideMethods[cls]) {
        _KKPOverrideMethods[(id<NSCopying>)cls] = [[NSMutableDictionary<NSString *, KKPClassMethodReplaceRecord*> alloc] init];
    }
    
    _KKPOverrideMethods[cls][selectorName] = record;
}

static BOOL kkp_class_isReplaceByKKP(Class cls, NSString *selectorName)
{
    if (_KKPOverrideMethods) {
        if (_KKPOverrideMethods[cls]) {
            return _KKPOverrideMethods[cls][selectorName] ? YES : NO;
        }
    }
    
    return NO;
}

static void kkp_doesNotRecognizeSelector(id object, SEL _cmd) {
    [object doesNotRecognizeSelector:_cmd];
}

/// 用于清理 hook 过方法替换
void kkp_class_cleanClass(NSString *className)
{
    NSMutableArray *removedKeys = [NSMutableArray array];
    NSMutableDictionary *overrideMethodsDict = _KKPOverrideMethods;
    for (Class cls in overrideMethodsDict.allKeys) {
        if (className && ![className isEqualToString:NSStringFromClass(cls)]) {
            continue;
        }
        
        /// 恢复方法替换
        NSMutableDictionary<NSString *, KKPClassMethodReplaceRecord*> *methodsDict = _KKPOverrideMethods[cls];
        for (NSString *selectorName in methodsDict.allKeys) {
            KKPClassMethodReplaceRecord *record = methodsDict[selectorName];
            
            Class klass = record.isInstanceMethod ? cls : object_getClass(cls);
            SEL selector = NSSelectorFromString(selectorName);
            if (record.isReplaceMethod) {// 如果是替换方法，则恢复成原始方法的实现
                SEL originSelector = kkp_runtime_originForSelector(selector);
                Method originMethod = class_getInstanceMethod(klass, originSelector);
                const char *typeEncoding = method_getTypeEncoding(originMethod);
                IMP originIMP = method_getImplementation(originMethod);
                class_replaceMethod(klass, selector, originIMP, typeEncoding);
            } else {// 如果是添加方法，则恢复成一个空实现
                Method addMethod = class_getInstanceMethod(klass, selector);
                const char *typeEncoding = method_getTypeEncoding(addMethod);
                class_replaceMethod(klass, selector, (IMP)kkp_doesNotRecognizeSelector, typeEncoding);
            }
        }
        
        /// 恢复 forwardInvocation: 的实现
        const char *typeDescription = (char *)method_getTypeEncoding(class_getInstanceMethod(cls, @selector(forwardInvocation:)));
        IMP originForwardInvocationIMP = class_getMethodImplementation(cls, NSSelectorFromString(KKP_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME));
        if (originForwardInvocationIMP) {
            class_replaceMethod(cls, @selector(forwardInvocation:), originForwardInvocationIMP, typeDescription);
        }
        
        [removedKeys addObject:cls];
    }
    
    [_KKPOverrideMethods removeObjectsForKeys:removedKeys];
}

#pragma mark - 运行时方法替换
/// 实例方法调用时，self 是 实例。类方法调用时，self 是 类
static void __KKP_ARE_BEING_CALLED__(__unsafe_unretained NSObject *self, SEL selector, NSInvocation *invocation)
{
    Class klass = [self class];
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    
    lua_State* L = kkp_currentLuaState();
    kkp_safeInLuaStack(L, ^int{
        if (kkp_class_isReplaceByKKP(klass, selectorName)) {// selector 是否已经被替换了
            int nresults = kkp_callLuaFunction(L, self, invocation.selector, invocation);
            if (nresults > 0) {
                NSMethodSignature *signature = [self methodSignatureForSelector:invocation.selector];
                void *pReturnValue = kkp_toOCObject(L, [signature methodReturnType], -1);
                if (pReturnValue != NULL) {
                    [invocation setReturnValue:pReturnValue];
                    free(pReturnValue);
                }
            }
        } else {
            // 调用原始消息转发方法
            SEL origin_selector = NSSelectorFromString(KKP_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME);
            ((void(*)(id, SEL, id))objc_msgSend)(self, origin_selector, invocation);
        }
        return 0;
    });
}

/// 重写方法，当 klass 是类时则替换实例方法。当 klass 是元类时，替换类方法
static void kkp_class_overrideMethod(Class klass, SEL sel, BOOL isInstanceMethod, const char *typeDescription)
{
    if (klass == nil || sel == nil) {
        return;
    }
    
    if (!typeDescription) {// 类型描述为空时，就从类里获取
        Method method = class_getInstanceMethod(klass, sel);
        typeDescription = (char *)method_getTypeEncoding(method);
    }
    
    /// 给类添加自定义的 forwardInvocation 方法实现，并替换掉旧的 forwardInvocation 方法
    kkp_runtime_swizzleForwardInvocation(klass, (IMP)__KKP_ARE_BEING_CALLED__);
    
    BOOL isReplaceMethod = YES;
    if (class_respondsToSelector(klass, sel)) {// 替换方法
        IMP originalImp = class_getMethodImplementation(klass, sel);
        SEL originSelector = kkp_runtime_originForSelector(sel);
        // 给类添加一个原始方法，方便被 hook 的方法内部调用原始的方法
        if (!class_respondsToSelector(klass, originSelector)) {
            class_addMethod(klass, originSelector, originalImp, typeDescription);
        }
        
        /// 把要 hook 的方法实现，直接替换成 _objc_msgForward，意味着 hook 的方法在调用时，直接走消息转发流程，不用经过 method list 查找流程
        /// 如果方法存在就替换，否则就是添加
        class_replaceMethod(klass, sel, kkp_runtime_getMsgForwardIMP(klass, typeDescription), typeDescription);
    } else {// 添加新方法（添加不存在方法，不管是现有类还是新创建的类）
        isReplaceMethod = NO;
        /// 把要 hook 的方法实现，直接替换成 _objc_msgForward，意味着 hook 的方法在调用时，直接走消息转发流程，不用经过 method list 查找流程
        /// 如果方法存在就替换，否则就是添加
        class_addMethod(klass, sel, kkp_runtime_getMsgForwardIMP(klass, typeDescription), typeDescription);
    }
    
    /// 把已经替换的方法记录下
    KKPClassMethodReplaceRecord *record = [KKPClassMethodReplaceRecord new];
    NSString *className = NSStringFromClass(klass);
    record.className = className;
    record.selecotorName = NSStringFromSelector(sel);
    record.isInstanceMethod = isInstanceMethod;
    record.isReplaceMethod = isReplaceMethod;
    kkp_class_recordOverideMethods(NSClassFromString(className), NSStringFromSelector(sel), record);
}

#pragma mark - 帮助方法
int kkp_class_create_userdata(lua_State *L, Class klass)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *klass_name = NSStringFromClass(klass).UTF8String;
        
        // 从类列表元表里获取 class_name 对应 class userdata，并压栈，如果没有的话，压入会是一个 nil
        luaL_getmetatable(L, KKP_CLASS_USER_DATA_LIST_TABLE);
        lua_getfield(L, -1, klass_name);
        
        // 如果还没有创建 class userdata
        if (lua_isnil(L, -1)) {
            Class klass = objc_getClass(klass_name);
            if (klass == nil) {
                return 0;// 没有结果返回，在 lua 中做条件判断时，会返回 false
            }
            size_t nbytes = sizeof(KKPInstanceUserdata);
            KKPInstanceUserdata *userData = (KKPInstanceUserdata *)lua_newuserdata(L, nbytes);
            userData->instance = klass;
            userData->isClass = true;
            userData->isCallSuper = false;
            userData->isCallOrigin = false;
            userData->isBlock = false;
            
            // 给 class userdata 设置 元表
            luaL_getmetatable(L, KKP_CLASS_USER_DATA_META_TABLE);
            lua_setmetatable(L, -2);
            
            // 给 class userdata 设置一个关联表，关联表不等于元表
            // 关联表用于存储 lua 函数的名字和函数体，方便 oc 调用 lua 函数
            lua_newtable(L);
            lua_setuservalue(L, -2);
            
            // 把栈顶的 class userdata 复制一遍，然后再放到栈顶，目的是为了设置 KKP_CLASS_LIST_TABLE 的值
            lua_pushvalue(L, -1);
            // -4 的位置是 KKP_CLASS_LIST_TABLE，目的是标记这个类已经加载过了
            lua_setfield(L, -4, klass_name);
        }
        return 1;
    });
}

#pragma mark - class userdata 提供的元API
/// 因为 class userdata 指针是不会存 key的，所以这里取值时会调用 class_userdata[key]，1：userdata 指针，2：key
/// lua 调用原生类方法
static int LUserData_kkp_class__index(lua_State *L)
{
    // 获取要检索的 key，也就是函数名
    const char* func = lua_tostring(L, -1);
    if (func == NULL) {
        return 0;
    }
    
    // 获取 class user data
    KKPInstanceUserdata *userdata = lua_touserdata(L, -2);
    if (userdata == NULL || userdata->instance == NULL) {
        return 0;
    }
    
    // 是否是 alloc 函数，返回一个 alloc 调用闭包
    if (kkp_isAllocMethod(func)) {
        lua_pushcclosure(L, kkp_alloc_closure, 1);
        return 1;
    }
    
    // 返回一个普通函数调用闭包
    Class klass = object_getClass(userdata->instance);
    if ([klass instancesRespondToSelector:NSSelectorFromString([NSString stringWithFormat:@"%s", kkp_toObjcSel(func)])]) {
        lua_pushcclosure(L, kkp_invoke_closure, 1);
        return 1;
    }
    return 0;
}

/// 用于替换和添加 OC 类方法
/// 因为 class userdata 指针是不会存 key的，所以这里更新时会调用 class_userdata[key] = value，1：userdata 指针，2：key，3：value（函数）
static int LUserData_kkp_class__newIndex(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char* key = lua_tostring(L, 2);
        if (strcmp(key, [KKP_ENV_SCOPE UTF8String]) == 0) {// 说明是保存环境，把环境保存到关联表里，为了在实例方法调用时，设置 self 关键字
            // 获取 class userdata 的关联表，并压栈
            lua_getuservalue(L, 1);
            // 压入 key
            lua_pushstring(L, [KKP_ENV_SCOPE UTF8String]);
            // 把环境值压栈
            lua_pushvalue(L, 3);
            // 把环境值保存到关联表里，相当于 associated_table["_SCOPE"] = scope
            lua_rawset(L, -3);
        } else if (lua_type(L, 3) == LUA_TFUNCTION) {// 只能 hook 函数
            KKPInstanceUserdata *userdata = lua_touserdata(L, 1);
            if (userdata) {
                const char* func = lua_tostring(L, 2);
                Class klass = userdata->instance;
                Class metaClass = object_getClass(klass);
                BOOL isInstanceMethod = YES;// 是否是实例对象方法
                const char *typeDescription = nil;
                
                NSString *selectorName = [NSString stringWithFormat:@"%s", kkp_toObjcSel(func)];
                SEL sel = NSSelectorFromString(selectorName);
                if ([selectorName hasPrefix:KKP_STATIC_PREFIX]) {// lua 脚本里如果方法名是以 STATIC 为前缀，说明一个静态方法，此时就需要找到 OC 类的元类
                    selectorName = [selectorName substringFromIndex:[KKP_STATIC_PREFIX length]];
                    sel = NSSelectorFromString(selectorName);
                    klass = metaClass;
                    isInstanceMethod = NO;
                }
                
                if (class_respondsToSelector(klass, sel)) {// 能响应就替换方法
                    /// 替换方法
                    kkp_class_overrideMethod(klass, sel, isInstanceMethod, NULL);
                } else {// 否则添加新方法
                    /// 添加新方法之前，需要先确定方法的签名。可以通过遍历 class 的协议列表来找到方法签名
                    BOOL foundSignature = NO;
                    uint count;
                    __unsafe_unretained Protocol **protocols = class_copyProtocolList(userdata->instance, &count);
                    for (int i = 0; i < count; i++) {
                        Protocol *protocol = protocols[i];
                        NSString *types = kkp_runtime_methodTypesInProtocol(protocol, selectorName, isInstanceMethod, YES);
                        if (!types) types = kkp_runtime_methodTypesInProtocol(protocol, selectorName, isInstanceMethod, NO);
                        if (types) {
                            typeDescription = types.UTF8String;
                            foundSignature = YES;
                            break;
                        }
                    }
                    if (protocols != NULL) {
                        free(protocols);
                    }
                    
                    /// 如果没有找到，就设置默认方法签名
                    if (!foundSignature) {
                        /// 计算参数个数，通过偏离 : 符号来确定个数
                        int argCount = 0;
                        const char *match = selectorName.UTF8String;
                        while ((match = strchr(match, ':'))) {
                            match += 1; // Skip past the matched char
                            argCount++;
                        }
                        
                        // 前三个是 返回类型，self 和 :，后面都是参数了。比如 @@: 表示返回类型是对象，self 和 sel
                        NSMutableString *typeDescStr = [@"@@:" mutableCopy];
                        for (int i = 0; i < argCount; i ++) {
                            [typeDescStr appendString:@"@"];
                        }
                        
                        typeDescription = typeDescStr.UTF8String;
                    }
                    
                    /// 添加方法
                    kkp_class_overrideMethod(klass, sel, isInstanceMethod, typeDescription);
                }
                
                // 获取 class userdata 的关联表，并压栈
                lua_getuservalue(L, 1);
                
                /**
                 此时的栈
                 4/-1: type=table
                 value=
                 {
                 }

                 3/-2: type=function
                 2/-3: type=string value=doSomeThing
                 1/-4: type=userdata
                 */
                
                // 把关联表移动到 第二个 索引上
                lua_insert(L, 2);
                
                /**
                 此时的栈
                 
                 4/-1: type=function
                 3/-2: type=string value=doSomeThing
                 2/-3: type=table
                 value=
                 {
                 }
                 1/-4: type=userdata
                 */
                // 把 索引 3 作为 key，索引 4 作为 value，设置到关联表上
                lua_rawset(L, 2);
                /**
                 此时的栈
                 2/-3: type=table
                 value=
                 {
                 doSomeThing = function
                 }
                 1/-4: type=userdata
                 */
            }
        } else {
            KKP_ERROR(L, @"type must function");
        }
        return 0;
    });
}

static int LUserData_kkp_class__tostring(lua_State *L) {
    KKPInstanceUserdata *instanceUserdata = (KKPInstanceUserdata *)luaL_checkudata(L, 1, KKP_CLASS_USER_DATA_META_TABLE);
    lua_pushstring(L, [[NSString stringWithFormat:@"(%p => %p) %@", instanceUserdata, instanceUserdata->instance, instanceUserdata->instance] UTF8String]);
    
    return 1;
}

static int LUserData_kkp_class__eq(lua_State *L) {
    KKPInstanceUserdata *o1 = (KKPInstanceUserdata *)luaL_checkudata(L, 1, KKP_CLASS_USER_DATA_META_TABLE);
    KKPInstanceUserdata *o2 = (KKPInstanceUserdata *)luaL_checkudata(L, 1, KKP_CLASS_USER_DATA_META_TABLE);
    
    lua_pushboolean(L, [o1->instance isEqual:o2->instance]);
    return 1;
}

static const struct luaL_Reg UserDataMetaMethods[] = {
    {"__index", LUserData_kkp_class__index},
    {"__newindex", LUserData_kkp_class__newIndex},
    {"__tostring", LUserData_kkp_class__tostring},
    {"__eq", LUserData_kkp_class__eq},
    {NULL, NULL}
};

#pragma mark - class 模块提供的API
/// 查找一个 OC class user data
static int LF_kkp_class_find_userData(lua_State *L)
{
    const char* klass_name = lua_tostring(L, 1);
    Class klass = objc_getClass(klass_name);
    if (klass == nil) {
        return 0;// 没有结果返回，在 lua 中做条件判断时，会返回 false
    }
    return kkp_class_create_userdata(L, klass);
}

/// 定义一个 oc block，用于把 lua 函数转成一个 oc block 做的前置工作，主要是先保存 lua 函数的 返回和参数类型
/// arg1 是 lua 函数，arg2 是 返回类型，arg3 是参数类型(一个 lua table  数组，可选)
static int LF_kkp_class_define_block(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        if (!lua_isfunction(L, 1)) {
            NSString* error = @"Can not get lua function when define block";
            KKP_ERROR(L, error);
        }
        
        NSString *typeEncoding = @"void,void";
        const char* type_encoding = lua_tostring(L, 2);
        if (type_encoding) {
            typeEncoding = [NSString stringWithUTF8String:type_encoding];
        }
        
        NSString *realTypeEncoding = kkp_create_real_signature(typeEncoding, NO, YES);
        KKPBlockWrapper *block = [[KKPBlockWrapper alloc] initWithTypeEncoding:realTypeEncoding state:L funcIndex:1];
        void *ptr = [block blockPtr];
        // 把 block 指针压栈
        lua_pushlightuserdata(L, ptr);
        return 1;
    });
}

/// 定义一个 oc protocl，
/// arg1 是 协议名，arg2 是 实例方法声明的 table 字典，arg3 是 类方法声明的 table 字典
static int LF_kkp_class_define_protocol(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        // 协议名
        const char *protocolName = luaL_checkstring(L, 1);
        
        Protocol* newprotocol = objc_allocateProtocol(protocolName);
        if (newprotocol) {
            if (lua_istable(L, 2)) {// 实例方法声明的 table 字典
                lua_pushnil(L);  // 压入一个key，nil 表示按序号遍历一个 table 数组
                while (lua_next(L, 2)) {// 遍历 table 数组，并把键值压栈。2 表示表的位置
                    NSString *methodName = [NSString stringWithFormat:@"%s", kkp_toObjcSel(luaL_checkstring(L, -2))];
                    NSString *methodEncoding = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                    
                    BOOL isInstanceMethod = YES;// 是否是实例对象方法
                    NSString *realMethodEncoding = kkp_create_real_signature(methodEncoding, NO, NO);
                    SEL sel = NSSelectorFromString(methodName);
                    const char* type = [realMethodEncoding UTF8String];
                    protocol_addMethodDescription(newprotocol, sel, type, YES, isInstanceMethod);
                    lua_pop(L, 1);
                }
            }
            
            if (lua_istable(L, 3)) {// 类方法声明的 table 字典
                lua_pushnil(L);  // 压入一个key，nil 表示按序号遍历一个 table 数组
                while (lua_next(L, 3)) {// 遍历 table 数组，并把键值压栈。3 表示表的位置
                    NSString *methodName = [NSString stringWithFormat:@"%s", kkp_toObjcSel(luaL_checkstring(L, -2))];
                    NSString *methodEncoding = [NSString stringWithUTF8String:luaL_checkstring(L, -1)];
                    
                    BOOL isInstanceMethod = NO;
                    NSString *realMethodEncoding = kkp_create_real_signature(methodEncoding, NO, NO);
                    SEL sel = NSSelectorFromString(methodName);
                    const char* type = [realMethodEncoding UTF8String];
                    protocol_addMethodDescription(newprotocol, sel, type, YES, isInstanceMethod);
                    lua_pop(L, 1);
                }
            }
            
            objc_registerProtocol(newprotocol);
        }
        
        return 0;
    });
}

/// 查找一个 OC 类，并创建 OC 类的 class user data
static int LM_kkp_class__index(lua_State *L)
{
    return LF_kkp_class_find_userData(L);
}

/// 创建一个新的 OC 类，并创建 OC 类的 class user data
/// 解释下 __call 元方法
/// __call: 函数调用操作 func(args)。 当 Lua 尝试调用一个非函数的值的时候会触发这个事件 （即 func 不是一个函数）。 查找 func 的元方法， 如果找得到，就调用这个元方法， func 作为第一个参数传入，原来调用的参数（args）后依次排在后面。
/// 比如 a = {}
/// meta_table = { __call = function(self, arg1, arg2, arg3...) print(self, arg1, arg2, arg3) end}
/// setmetatable(a, meta_table)
/// a("ViewController", "BaseViewController", protocols = {"UITableViewDelegate"})
/// 这里 arg1 是 a, arg2 是 "ViewController", arg3 是 "BaseViewController"， arg4 是 protocols = {"UITableViewDelegate"}，那么栈索引1是 arg1，栈索引2是 arg2，栈索引3是 arg3，栈索引4是 arg4
static int LM_kkp_class__call(lua_State *L)
{
    const char *className = luaL_checkstring(L, 2);
    Class klass = objc_getClass(className);
    
    if (!klass) {// 类不存在，就创建新 OC 类
        /// 获取父类
        Class superClass;
        if (lua_isnoneornil(L, 3)) {// 如果没有指定父类，就默认父类是 NSObject
            superClass = [NSObject class];
        } else {// 如果指定了父类
            const char *superClassName = luaL_checkstring(L, 3);
            superClass = objc_getClass(superClassName);
        }
        
        if (!superClass) {
            NSString* error = [NSString stringWithFormat:@"Failed to create '%s'. Unknown superclass \"%s\" received.", className, luaL_checkstring(L, 3)];
            KKP_ERROR(L, error);
        }
        
        /// 创建新类
        klass = objc_allocateClassPair(superClass, className, 0);
        objc_registerClassPair(klass);
    }
    
    /// 添加协议的目的，是为了给类添加新方法时可以找到方法签名的依据
    if (lua_istable(L, 4)) {
        lua_pushnil(L);  // 压入一个key，nil 表示按序号遍历一个 table 数组
        while (lua_next(L, 4)) {// 遍历 table 数组，并把键值压栈。2 表示表的位置
            const char *protocolName = luaL_checkstring(L, -1);
            NSString *trimProtolName = kkp_trim([NSString stringWithUTF8String:protocolName]);
            Protocol *protocol = objc_getProtocol(trimProtolName.UTF8String);
            if (!protocol) {
                NSString *error = [NSString stringWithFormat:@"Could not find protocol named '%@'\nHint: Sometimes the runtime cannot automatically find a protocol. Try adding it (via xCode) to the file ProtocolLoader.h", trimProtolName];
                KKP_ERROR(L, error);
            }
            class_addProtocol(klass, protocol);
            lua_pop(L, 1);
        }
    }
    
    return kkp_class_create_userdata(L, klass);
}

static const struct luaL_Reg Methods[] = {
    {"findUserData", LF_kkp_class_find_userData},
    {"defineBlock", LF_kkp_class_define_block},
    {"defineProtocol", LF_kkp_class_define_protocol},
    {NULL, NULL}
};

static const struct luaL_Reg MetaMethods[] = {
    {"__index", LM_kkp_class__index},
    {"__call", LM_kkp_class__call},
    {NULL, NULL}
};

LUAMOD_API int luaopen_kkp_class(lua_State *L)
{
    /// 创建 class user data 元表，并添加元方法
    luaL_newmetatable(L, KKP_CLASS_USER_DATA_META_TABLE);// 新建元表用于存放元方法
    luaL_setfuncs(L, UserDataMetaMethods, 0); //给元表设置函数
    
    /// 新建元表用于存放所有 class user data
    luaL_newmetatable(L, KKP_CLASS_USER_DATA_LIST_TABLE);
    
    /// 新建 class 模块
    luaL_newlib(L, Methods);// 创建库函数
    
    /// 新建 class 模块元表
    luaL_newmetatable(L, KKP_CLASS_META_TABLE);
    luaL_setfuncs(L, MetaMethods, 0); //给元表设置函数
    lua_setmetatable(L, -2);
    
    return 1;
}
