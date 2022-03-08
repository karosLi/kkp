//
//  KKPFunctionTest.m
//  kkpTests
//
//  Created by karos li on 2022/3/2.
//

#import <XCTest/XCTest.h>
#import <kkp/kkp.h>
#import "KKPXCTestCase.h"

@interface KKPCFunctionTest : KKPXCTestCase
@property (nonatomic) int index;
@end

@implementation KKPCFunctionTest

- (void)dispatchAfter {}

- (void)test_dispatch_after {
    /// 测试 dispatch_after
    [self restartKKP];
    self.index = 0;
    NSString *script =
    @KKP_LUA(
             kkp.setConfig({openBindOCFunction=true})
             kkp_class({"KKPCFunctionTest"},
             function(_ENV)
                 function dispatchAfter()
                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(),
                                      kkp_block(function()
                                                    self:setIndex_(2)
                                                end, "void,void"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self dispatchAfter];
    XCTAssert(self.index == 0);
    XCTestExpectation *exp = [self expectationWithDescription:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssert(self.index == 2);
        [exp fulfill];
    });
    // 5秒内必须收到 [exp fulfill]，表示测试成功，否则表示测试失败
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)dispatchAsync {}
- (void)test_dispatch_async {
    /// 测试 dispatch_async
    [self restartKKP];
    self.index = 0;
    NSString *script =
    @KKP_LUA(
             kkp.setConfig({openBindOCFunction=true})
             kkp_class({"KKPCFunctionTest"},
             function(_ENV)
                 function dispatchAsync()
                       dispatch_async(dispatch_get_main_queue(),
                                      kkp_block(function()
                                                    self:setIndex_(2)
                                                end, "void,void"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self dispatchAsync];
    XCTAssert(self.index == 0);
    XCTestExpectation *exp = [self expectationWithDescription:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssert(self.index == 2);
        [exp fulfill];
    });
    // 5秒内必须收到 [exp fulfill]，表示测试成功，否则表示测试失败
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    
    /// 测试 dispatch_async 派发到全局队列
    [self restartKKP];
    self.index = 0;
    script =
    @KKP_LUA(
             kkp.setConfig({openBindOCFunction=true})
             kkp_class({"KKPCFunctionTest"},
             function(_ENV)
                 function dispatchAsync()
                       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                                      kkp_block(function()
                                                    self:setIndex_(2)
                                                end, "void,void"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self dispatchAsync];
    XCTAssert(self.index == 0);
    exp = [self expectationWithDescription:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssert(self.index == 2);
        [exp fulfill];
    });
    // 5秒内必须收到 [exp fulfill]，表示测试成功，否则表示测试失败
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)dispatchSync {}
- (void)test_dispatch_sync {
    /// 测试 dispatch_sync
    [self restartKKP];
    self.index = 0;
    NSString *script =
    @KKP_LUA(
             kkp.setConfig({openBindOCFunction=true})
             kkp_class({"KKPCFunctionTest"},
             function(_ENV)
                 function dispatchSync()
                       local queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                       dispatch_sync(queue,
                                      kkp_block(function()
                                                    self:setIndex_(2)
                                                end, "void,void"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self dispatchSync];
    XCTAssert(self.index == 2);
}

@end
