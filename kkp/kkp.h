//
//  kkp.h
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import <Foundation/Foundation.h>
#import "lua.h"

#define KKP_LUA(x) #x // 方便定义 多行 lua 代码，比如 NSString *script = @KKP_LUA(function() end);
#define KKP_VERSION 0.01
#define KKP "kkp"

typedef void (*KKPCLibFunction) (lua_State *L);
typedef void (^KKPLuaLogHanlder)(NSString *log);
typedef void (^KKPLuaErrorHanlder)(NSString *error);

#pragma mark - 日志和错误处理
/// 设置 lua log 处理器，当 lua 脚本代码里使用 kkp.print 时就会触发这个处理器
extern void kkp_setLuaLogHandler(KKPLuaLogHanlder handler);
/// 获取 lua log  处理器
extern KKPLuaLogHanlder kkp_getLuaLogHandler(void);
/// 设置 lua error 处理器，当出现 lua 脚本语法错误，运行时错误时就会触发这个处理器
extern void kkp_setLuaErrorHandler(KKPLuaErrorHanlder handler);
/// 获取 lua error  处理器
extern KKPLuaErrorHanlder kkp_getLuaErrorHandler(void);

#pragma mark - 安装和运行
/// 配置外部库函数
extern void kkp_setExtensionCLib(KKPCLibFunction extensionCLibFunction);

/// 启动 kkp
extern void kkp_start(void);

/// 停止 kkp
extern void kkp_end(void);

/// 重启 kkp
extern void kkp_restart(void);

/// 获取当前状态机
extern lua_State *kkp_currentLuaState(void);

/// 运行 lua 脚本字符串
extern int kkp_runLuaString(NSString *script);

/// 运行 lua 脚本文件
extern int kkp_runLuaFile(NSString *fname);

/// 运行 lua 脚本字节码
extern int kkp_runLuaByteCode(NSData *data, NSString *name);

#pragma mark - 类型 hook 清理

/// 清理所有的类
extern void kkp_cleanAllClass(void);

/// 清理指定的类
extern void kkp_cleanClass(NSString *className);
