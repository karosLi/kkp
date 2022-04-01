//
//  main.m
//  KKPDemo
//
//  Created by karos li on 2022/3/8.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <kkp/kkp.h>

int main(int argc, char * argv[]) {
    // 测试单元用例时，需要关闭下面的代码
    
    // 设置日志处理
    kkp_setLuaLogHandler(^(NSString *log) {
     NSLog(@"【统一日志打印】 %@", log);
    });

    // 设置错误处理
    kkp_setLuaErrorHandler(^(NSString *error) {
     NSLog(@"【统一错误拦截】 %@", error);
    });
     
     // 添加调试
#ifdef DEBUG
    kkp_addExtensionDebug();
#endif
    // 启动
    kkp_start();
    // 执行测试脚本
    kkp_runLuaFile(@"test.lua");
     
    
//    // 清理 hook 的类
//    kkp_cleanAllClass();
//    // 重启
//    kkp_restart();
//    // 执行测试脚本
//    kkp_runLuaFile(@"test.lua");
    
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
