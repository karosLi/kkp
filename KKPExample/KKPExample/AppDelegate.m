//
//  AppDelegate.m
//  KKPExample
//
//  Created by karos li on 2022/3/8.
//

#import "AppDelegate.h"
#import <kkp/kkp.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 设置日志处理
    kkp_setLuaLogHandler(^(NSString *log) {
        NSLog(@"【统一日志打印】 %@", log);
    });
    
    // 设置错误处理
    kkp_setLuaErrorHandler(^(NSString *error) {
        NSLog(@"【统一错误拦截】 %@", error);
    });
    
    // 启动
    kkp_start();
    // 执行测试脚本
    kkp_runLuaFile(@"ViewController.lua");
    
    return YES;
}

@end
