//
//  kkp_struct.m
//  LearnLua
//
//  Created by karos li on 2022/2/23.
//

#import "kkp_struct.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "lauxlib.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_converter.h"

/// 用于保存注册的结构体，name, types, keys
static NSMutableDictionary *_KKPRegisteredStructs = nil;
NSMutableDictionary * kkp_struct_registeredStructs(void)
{
    if (!_KKPRegisteredStructs) {
        _KKPRegisteredStructs = [[NSMutableDictionary alloc] init];
    }
    
    return _KKPRegisteredStructs;
}

#pragma mark - 帮助方法
/// 根据字段的位置（从0开始），把 structUserdata->data  内存的数据转换并压入到  lua 栈中
static void kkp_struct_pushValueAt(lua_State *L, KKPStructUserdata *structUserdata, int varIndex) {
    const char *typeDescription = structUserdata->types;
    
    /// 根据偏移找到实际地址的偏移位置
    int offset = 0;
    // 创建一个字符数组，目的是临时替换第一个字符，这样 kkp_sizeOfStructTypes 计算的时候，不会计算多个类型的长度，而是计算一个类型的长度
    char type[2] = {typeDescription[0], '\0'};
    for (int i = 1; i <= varIndex; i++) {
        offset += kkp_sizeOfStructTypes(type);
        type[0] = typeDescription[i];
    }
    
    /// 根据偏移后的 buffer 指针和 当个 type 类型，把内存的数据转换并压入到  lua 栈中
    kkp_toLuaObjectWithBuffer(L, type, structUserdata->data + offset);
}

/// 根据字段的位置（从0开始），把 lua 栈中的数据赋值到 structUserdata->data 内存里
static void kkp_struct_setValueAt(lua_State *L, KKPStructUserdata *structUserdata, int varIndex, int stackIndex) {
    const char *typeDescription = structUserdata->types;
    
    int offset = 0;
    char type[2] = {typeDescription[0], '\0'};
    for (int i = 1; i <= varIndex; i++) {
        offset += kkp_sizeOfStructTypes(type);
        type[0] = typeDescription[i];
    }
    
    size_t size = kkp_sizeOfStructTypes(type);;
    void *value = kkp_toOCObject(L, type, stackIndex);
    memcpy(structUserdata->data + offset, value, size);
    free(value);
}

/// 创建结构体对应的 user data
/// 里面存储了类型描述和实际的数据
int kkp_struct_create_userdata(lua_State *L, const char *name, const char *typeDescription, void *structData)
{
    return kkp_safeInLuaStack(L, ^int{
        size_t nbytes = sizeof(KKPStructUserdata);
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)lua_newuserdata(L, nbytes);
        
        size_t size = kkp_sizeOfStructTypes(typeDescription);
        structUserdata->size = size;
        
        structUserdata->name = malloc(strlen(name) + 1);
        strcpy(structUserdata->name, name);
        
        structUserdata->types = malloc(strlen(typeDescription) + 1);
        strcpy(structUserdata->types, typeDescription);
        
        structUserdata->data = malloc(size);
        // 拷贝结构体数据到 structUserdata->data 里
        memcpy(structUserdata->data, structData, size);

        // 给 struct userdata 设置 元表
        luaL_getmetatable(L, KKP_STRUCT_USER_DATA_META_TABLE);
        lua_setmetatable(L, -2);
        
        // 给 struct userdata 设置一个关联表，关联表不等于元表，目前没有作用
        lua_newtable(L);
        lua_setuservalue(L, -2);
        return 1;
    });
}

/// 用于在 lua 中拷贝一个结构体实例
/// 第1个参数是一个 结构体 user data.
/// 比如：当使用  local size = CGSize({width=1,height=2})，然后 size:copy() 时，就会调用该闭包
static int kkp_struct_copy_userdata_closure(lua_State *L) {
    return kkp_safeInLuaStack(L, ^int{
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)luaL_checkudata(L, 1, KKP_STRUCT_USER_DATA_META_TABLE);
        kkp_struct_create_userdata(L, structUserdata->name, structUserdata->types, structUserdata->data);
        return 1;
    });
}

#pragma mark - struct userdata 提供的元API
/// 用于获取 struct 结构体的属性值
/// 因为 struct userdata 指针是不会存 key的，所以这里取值时会调用 struct_userdata[key]，1：userdata 指针，2：key
/// 也可以通过 struct_userdata.key 的形式获取值
static int LUserData_kkp_struct__index(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)luaL_checkudata(L, 1, KKP_STRUCT_USER_DATA_META_TABLE);
        
        NSInteger varIndex = NSNotFound;
        if (lua_isnumber(L, 2)) {
            varIndex = lua_tonumber(L, 2);
        } else {
            const char *name = lua_tostring(L, 2);
            if (strcmp(name, "copy") == 0) {// 如果名字是 copy 表示是要拷贝一个结构体
                lua_pushcclosure(L, kkp_struct_copy_userdata_closure, 0);
                return 1;
            }
            
            NSDictionary *structDefine = kkp_struct_registeredStructs()[[NSString stringWithUTF8String:structUserdata->name]];
            NSString *keys = structDefine[@"keys"];
            if (keys) {
                NSArray *itemKeys = [keys componentsSeparatedByString:@","];
                varIndex = (int)[itemKeys indexOfObject:[NSString stringWithUTF8String:name]];
            }
        }
        
        if (varIndex != NSNotFound) {
            kkp_struct_pushValueAt(L, structUserdata, (int)varIndex);
        }
        
        return 1;
    });
}

/// 用于给 struct 结构体的属性赋值
/// 因为 struct userdata 指针是不会存 key的，所以这里更新时会调用 struct_userdata[key] = value，1：userdata 指针，2：key，3：value
/// 也可以通过 struct_userdata.key = value 的形式获赋值
static int LUserData_kkp_struct__newIndex(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)luaL_checkudata(L, 1, KKP_STRUCT_USER_DATA_META_TABLE);
        
        NSInteger varIndex = NSNotFound;
        if (lua_isnumber(L, 2)) {
            varIndex = lua_tonumber(L, 2);
        } else {
            const char *name = lua_tostring(L, 2);
            
            NSDictionary *structDefine = kkp_struct_registeredStructs()[[NSString stringWithUTF8String:structUserdata->name]];
            NSString *keys = structDefine[@"keys"];
            if (keys) {
                NSArray *itemKeys = [keys componentsSeparatedByString:@","];
                varIndex = (int)[itemKeys indexOfObject:[NSString stringWithUTF8String:name]];
            }
        }
        
        if (varIndex != NSNotFound) {
            kkp_struct_setValueAt(L, structUserdata, (int)varIndex, 3);
        }
        
        return 0;
    });
}

/// 用于打印输出
static int LUserData_kkp_struct__tostring(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)luaL_checkudata(L, 1, KKP_STRUCT_USER_DATA_META_TABLE);
        
        NSDictionary *structDefine = kkp_struct_registeredStructs()[[NSString stringWithUTF8String:structUserdata->name]];
        
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        luaL_addstring(&b, structUserdata->name);
        luaL_addstring(&b, " {\n");
        
        NSString *keys = structDefine[@"keys"];
        if (keys) {
            NSArray *itemKeys = [keys componentsSeparatedByString:@","];
            for (int i = 0; i < itemKeys.count; i++) {
                luaL_addstring(&b, "\t");
                NSString *itemKey = itemKeys[i];
                luaL_addstring(&b, itemKey.UTF8String);
                luaL_addstring(&b, " : ");
                
                kkp_struct_pushValueAt(L, structUserdata, i);
                luaL_addstring(&b, lua_tostring(L, -1));
                luaL_addstring(&b, "\n");
                lua_pop(L, 1); // pops the value and the struct offset, keeps the key for the next iteration
            }
        } else {
            NSString *types = [NSString stringWithUTF8String:structUserdata->types];
            for (int i = 0; i < types.length; i++) {
                kkp_struct_pushValueAt(L, structUserdata, i);
                luaL_addstring(&b, lua_tostring(L, -1));
                luaL_addstring(&b, "\n");
                lua_pop(L, 1); // pops the value and the struct offset, keeps the key for the next iteration
            }
        }
        
        luaL_addstring(&b, "}");
        luaL_pushresult(&b);
        
        return 1;
    });
}

/// 触发了垃圾回收
static int LUserData_kkp_struct__gc(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        KKPStructUserdata *structUserdata = (KKPStructUserdata *)luaL_checkudata(L, 1, KKP_STRUCT_USER_DATA_META_TABLE);

        free(structUserdata->name);
        free(structUserdata->types);
        free(structUserdata->data);
        
        return 0;
    });
}

static const struct luaL_Reg UserDataMetaMethods[] = {
    {"__index", LUserData_kkp_struct__index},
    {"__newindex", LUserData_kkp_struct__newIndex},
    {"__tostring", LUserData_kkp_struct__tostring},// print(struct) 和 tostring(struct) 会触发
    {"__gc", LUserData_kkp_struct__gc},
    {NULL, NULL}
};

#pragma mark - struct 模块提供的API

/// 用于在 lua 中创建一个结构体实例
/// upvalues (name)
/// 第1个参数是一个 lua table 字典。因为是直接调用的，没有使用 ：语法糖
/// 比如：当使用 CGSize({width=3, height=4}) 时，就会调用该闭包
static int kkp_struct_create_userdata_closure(lua_State *L) {
    return kkp_safeInLuaStack(L, ^int{
        if (!lua_istable(L, 1)) {// 必须是一个 table 字典
            NSString *error = @"Couldn't new struct. The argument must be table with key";
            KKP_ERROR(L, error);
        }
        
        const char *name = lua_tostring(L, lua_upvalueindex(1));
        NSDictionary *structDefine = kkp_struct_registeredStructs()[[NSString stringWithUTF8String:name]];
        
        NSString *realTypeDescription = structDefine[@"types"];
        NSString *keys = structDefine[@"keys"];
       
        /// 把 lua table 转成字典
        void *arg = kkp_toOCObject(L, "@", 1);
        __unsafe_unretained NSDictionary *structDict;
        structDict = (__bridge id)(*(void **)arg);
        free(arg);
        
        if (![structDict isKindOfClass:NSDictionary.class] || structDict.count != realTypeDescription.length) {
            NSString *error = [NSString stringWithFormat:@"Couldn't new struct. Received %lu arguments for struct with type description '%@'", (unsigned long)structDict.count, realTypeDescription];
            KKP_ERROR(L, error);
        }
        
        /// 把字典里的数据填充到结构体指向的内存里
        const char *typeDescription = realTypeDescription.UTF8String;
        size_t size = kkp_sizeOfStructTypes(typeDescription);
        void *structData = malloc(size);
        
        /// 按 key 的顺序添加数据
        NSMutableArray *structArray = [NSMutableArray array];
        NSArray *itemKeys = [keys componentsSeparatedByString:@","];
        for (int i = 0; i < itemKeys.count; i++) {
            [structArray addObject:structDict[itemKeys[i]]];
        }
        
        kkp_getStructDataOfArray(structData, structArray, typeDescription);
        
        /// 根据结构体指针创建一个 struct user data
        kkp_struct_create_userdata(L, name, typeDescription, structData);
        free(structData);

        return 1;
    });
}

/// 注册一个 结构体
/// 入参是一个 lua table 字典
/// 比如：{name = "CGSize", types = "CGFloat,CGFloat", keys = "width", "height"}
static int LF_kkp_struct_register_struct(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        if (lua_istable(L, 1)) {// 一定是一个 table
            
            /// 找到 name，types，keys
            const char *name = NULL;
            const char *types = NULL;
            const char *keys = NULL;
            lua_pushnil(L);  // 压入一个key，nil 表示按序号遍历一个 table 数组
            while (lua_next(L, 1)) {// 遍历 table 数组，并把键值压栈。1 表示表的位置
                const char *key = luaL_checkstring(L, -2);
                const char *value = luaL_checkstring(L, -1);
                if (strcmp("name", key) == 0) {
                    name = value;
                } else if (strcmp("types", key) == 0) {
                    types = value;
                } else if (strcmp("keys", key) == 0) {
                    keys = value;
                }
                
                lua_pop(L, 1);
            }
            
            if (name != NULL && types != NULL && keys != NULL) {
                NSString *realTypeDescription = kkp_create_real_signature([NSString stringWithUTF8String:types], YES, NO);
                /// 注册结构体类型信息
                kkp_struct_registeredStructs()[[NSString stringWithUTF8String:name]] = @{
                    @"types" : realTypeDescription,
                    @"keys" : [NSString stringWithUTF8String:keys]
                };
                
                /// 把 name 定义成一个全局函数，比如：name 是 CGSize
                lua_pushstring(L, name);
                lua_pushcclosure(L, kkp_struct_create_userdata_closure, 1);// 比如：当使用 CGSize() 时，就会调用该闭包
                lua_setglobal(L, name);
            }
        }
        
        return 0;
    });
}

static const struct luaL_Reg Methods[] = {
    {"registerStruct", LF_kkp_struct_register_struct},
    {NULL, NULL}
};

static const struct luaL_Reg MetaMethods[] = {
    {NULL, NULL}
};

LUAMOD_API int luaopen_kkp_struct(lua_State *L)
{
    /// 创建 struct user data 元表，并添加元方法
    luaL_newmetatable(L, KKP_STRUCT_USER_DATA_META_TABLE);// 新建元表用于存放元方法
    luaL_setfuncs(L, UserDataMetaMethods, 0); //给元表设置函数
    
    /// 新建 struct 模块
    luaL_newlib(L, Methods);// 创建库函数
    
    /// 新建 struct 模块元表
    luaL_newmetatable(L, KKP_STRUCT_META_TABLE);
    luaL_setfuncs(L, MetaMethods, 0); //给元表设置函数
    lua_setmetatable(L, -2);
    
    return 1;
}
