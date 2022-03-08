//
//  KKPXCTestCase.m
//  kkpTests
//
//  Created by karos li on 2022/3/2.
//

#import "KKPXCTestCase.h"
#import <kkp/kkp.h>

@implementation KKPXCTestCase

- (void)setUp {
    // 设置日志处理
    kkp_setLuaLogHandler(^(NSString *log) {
        NSLog(@"【统一日志打印】 %@", log);
    });
    
    // 设置错误处理
    kkp_setLuaErrorHandler(^(NSString *error) {
        NSLog(@"【统一错误拦截】 %@", error);
    });
}

- (void)tearDown {
    kkp_end();
}

- (void)restartKKP {
    // 清理 hook 的类
    kkp_cleanAllClass();
    // 重启
    kkp_restart();
}

@end
