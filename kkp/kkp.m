//
//  kkp.m
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import "kkp.h"
#import <UIKit/UIKit.h>
#import "lualib.h"
#import "lauxlib.h"
#import "kkp_stdlib.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_class.h"
#import "kkp_instance.h"
#import "kkp_struct.h"
#import "kkp_converter.h"
#import "kkp_global_config.h"
#import "kkp_global_util.h"

static void kkp_setup(void);
static void kkp_addGlobals(lua_State *L);
LUALIB_API void kkp_open_libs(lua_State *L);

#pragma mark - 状态机
static lua_State *kkp_currentL;
lua_State *kkp_currentLuaState(void) {
    if (!kkp_currentL)
        kkp_currentL = luaL_newstate();
    
    return kkp_currentL;
}

#pragma mark - 日志错误处理相关
static KKPLuaLogHanlder kkp_lua_log_handler;
/// 设置 lua log 处理器
void kkp_setLuaLogHandler(KKPLuaLogHanlder handler)
{
    kkp_lua_log_handler = handler;
}
/// 获取 lua log  处理器
KKPLuaLogHanlder kkp_getLuaLogHandler(void)
{
    return kkp_lua_log_handler;
}

static KKPLuaErrorHanlder kkp_lua_error_handler;
/// 设置 lua error 处理器
void kkp_setLuaErrorHandler(KKPLuaErrorHanlder handler)
{
    kkp_lua_error_handler = handler;
}

/// 获取 lua error  处理器
KKPLuaErrorHanlder kkp_getLuaErrorHandler(void)
{
    return kkp_lua_error_handler;
}

/// 错误处理函数
static int kkp_panic(lua_State *L) {
    NSString *log = [NSString stringWithFormat:@"%s\n", lua_tostring(L, -1)];
    
    if (kkp_getLuaErrorHandler()) {
        kkp_getLuaErrorHandler()(log);
    }
    
    printf("%s\n", log.UTF8String);
    lua_pop(L, 1);
    return 0;
}

#pragma mark - 启动 kkp 相关

/// 配置外部库函数
static KKPCLibFunction kkp_extensionCLibFunction;
void kkp_setExtensionCLib(KKPCLibFunction extensionCLibFunction)
{
    kkp_extensionCLibFunction = extensionCLibFunction;
}

/// 启动 kkp
void kkp_start(void)
{
    // 安装 lua c 标准库 和 kkp c 库
    kkp_setup();
    
    lua_State *L = kkp_currentLuaState();
    
    // 加载 c 扩展库，为了方便添加外部 c 模块
    if (kkp_extensionCLibFunction) {
        kkp_extensionCLibFunction(L);
    }
    
    // 加载 kkp lua 脚本标准库
    char stdlib[] = KKP_STDLIB;// 编译好的字节码，字节码减少了编译过程，能更快加载；如果修改了 stdlib 里的 lua 文件，就需要重新 build，重新生成新的字节码
    size_t stdlibSize = sizeof(stdlib);
    if (luaL_loadbuffer(L, stdlib, stdlibSize, "loading kkp lua stdlib") || lua_pcall(L, 0, LUA_MULTRET, 0)) {
        NSString *log = [NSString stringWithFormat:@"[KKP] PANIC: opening kkp lua stdlib failed: %s\n", lua_tostring(L, -1)];
        KKP_ERROR(L, log);
        return;
    }
}

/// 停止 kkp
void kkp_end(void)
{
    lua_State *L = kkp_currentLuaState();
    lua_close(L);
    kkp_currentL = nil;
}

/// 重启 kkp
void kkp_restart(void)
{
    kkp_end();
    kkp_start();
}

/// 安装 lua c 标准库 和 kkp c 库
static void kkp_setup()
{
    // 切换到应用主根目录，为了 lua 可以寻找到 lua 脚本
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 默认为 bundle 目录
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    [fileManager changeCurrentDirectoryPath:bundlePath];
    
    // 创建状态机
    lua_State *L = kkp_currentLuaState();
    // 设置错误处理函数
    lua_atpanic(L, kkp_panic);
    // 打开 lua c 标准库
    luaL_openlibs(L);
    
    // 打开 kkp c 标准库
    kkp_open_libs(L);
    
    // 添加全局变量
    kkp_addGlobals(L);
}

/// 添加全局 lua 函数
static void kkp_addGlobals(lua_State *L)
{
    kkp_safeInLuaStack(L, ^int{
        lua_getglobal(L, KKP);
        if (lua_isnil(L, -1)) {
            lua_pop(L, 1); // 弹出 nil
            lua_newtable(L);
            lua_setglobal(L, KKP);
            lua_getglobal(L, KKP);
        }
        
        /// 设置 kkp.version 版本号
        lua_pushnumber(L, KKP_VERSION);
        lua_setfield(L, -2, "version");
        
        /// 设置 kkp.setConfig() 函数
        /// 比如： kkp.setConfig({openBindOCFunction="true", mobdebug="true"}
        lua_pushcfunction(L, kkp_global_setConfig);
        lua_setfield(L, -2, "setConfig");
        
        /// 设置 kkp.isNull() 函数
        lua_pushcfunction(L, kkp_global_isNull);
        lua_setfield(L, -2, "isNull");
        
        /// 设置 kkp.root() 函数
        lua_pushcfunction(L, kkp_global_root);
        lua_setfield(L, -2, "root");

        /// 设置 kkp.print() 函数
        lua_pushcfunction(L, kkp_global_print);
        lua_setfield(L, -2, "print");
        
        /// 设置 kkp.exit() 函数
        lua_pushcfunction(L, kkp_global_exitApp);
        lua_setfield(L, -2, "exit");
        
        /// 设置 kkp.appVersion 版本号
        lua_pushstring(L, [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String]);
        lua_setfield(L, -2, "appVersion");
        
        /// 设置全局 NSDocumentDirectory
        lua_pushstring(L, [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] UTF8String]);
        lua_setglobal(L, "NSDocumentDirectory");
        
        /// 设置全局 NSLibraryDirectory
        lua_pushstring(L, [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] UTF8String]);
        lua_setglobal(L, "NSLibraryDirectory");
        
        /// 设置全局 NSCacheDirectory
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        lua_pushstring(L, [cachePath UTF8String]);
        lua_setglobal(L, "NSCacheDirectory");

        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes: nil error:&error];
        
        
        /// os 相关
        lua_newtable(L);
        lua_setfield(L, -2, "os");
        lua_getfield(L, -1, "os");
        
        /// 设置 kkp.os.systemVersion 版本号
        lua_pushstring(L, [UIDevice currentDevice].systemVersion.UTF8String);
        lua_setfield(L, -2, "systemVersion");
        
        /// 设置 kkp.os.geOS() 函数
        lua_pushcfunction(L, kkp_global_isGreaterThanOS);
        lua_setfield(L, -2, "geOS");
        lua_pop(L, 1);// pop os
        
        
        /// device 相关
        lua_newtable(L);
        lua_setfield(L, -2, "device");
        lua_getfield(L, -1, "device");
        
        /// 设置 kkp.device.screenWidth
        lua_pushnumber(L, (double)[UIScreen mainScreen].bounds.size.width);
        lua_setfield(L, -2, "screenWidth");
        
        /// 设置 kkp.device.screenHeight
        lua_pushnumber(L, (double)[UIScreen mainScreen].bounds.size.height);
        lua_setfield(L, -2, "screenHeight");
        
        /// 设置 kkp.device.screenScale
        lua_pushnumber(L, (double)[UIScreen mainScreen].scale);
        lua_setfield(L, -2, "screenScale");
        lua_pop(L, 1);// pop device
        
        
        return 0;
    });
}

#pragma mark - 运行 lua 脚本相关

int kkp_runLuaString(NSString *script)
{
    lua_State *L = kkp_currentLuaState();
    return kkp_safeInLuaStack(L, ^int{
        return kkp_dostring(L, script.UTF8String);
    });
}

int kkp_runLuaFile(NSString *fname)
{
    lua_State *L = kkp_currentLuaState();
    return kkp_safeInLuaStack(L, ^int{
        return kkp_dofile(L, fname.UTF8String);
    });
}

int kkp_runLuaByteCode(NSData *data, NSString *name)
{
    lua_State *L = kkp_currentLuaState();
    return kkp_safeInLuaStack(L, ^int{
        return kkp_dobuffer(L, data, name.UTF8String);
    });
}

#pragma mark - 类型 hook 清理

/// 获取 lua error  处理器
void kkp_cleanAllClass(void)
{
    kkp_class_cleanClass(nil);
}

/// 获取 lua error  处理器
void kkp_cleanClass(NSString *className)
{
    kkp_class_cleanClass(className);
}

#pragma mark - 库加载相关方法
static const luaL_Reg kkp_libs[] = {
    {KKP_CLASS, luaopen_kkp_class},
    {KKP_INSTANCE, luaopen_kkp_instance},
    {KKP_STRUCT, luaopen_kkp_struct},
    {NULL, NULL}
};

/// 加载 kkp 库
LUALIB_API void kkp_open_libs(lua_State *L)
{
    const luaL_Reg *lib;
    for (lib = kkp_libs; lib->func; lib++) {
        /**
         执行完后，package.loaded 新增一个字段
         package.loaded[libname] = lib {
            注册的函数名：注册函数指针
            其他函数
         }
         
         并且 全局注册表中的loaded表新增一个字段，因为 lua 安装 package 标准库的时候，就已经设置了 register["loaded"] = package.loaded
         register["loaded"] = {
            libname: lib,
            其他库
         }
         
         最后一个参数表示是否需要设置成全局标量，如果为1，表示就是全局变量,
         相当于 _G[libname] = lib，那么在 lua 脚本中也不需要 require 就可以直接使用这个模块
         */
        luaL_requiref(L, lib->name, lib->func, 0);
        lua_pop(L, 1);  /* remove lib */
    }
}
