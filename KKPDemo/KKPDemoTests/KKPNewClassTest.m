//
//  KKPFunctionTest.m
//  kkpTests
//
//  Created by karos li on 2022/3/2.
//

#import <XCTest/XCTest.h>
#import <kkp/kkp.h>
#import "KKPXCTestCase.h"

/**
 测试添加新类，和定义协议为新方法增加方法签名
 */
@interface KKPNewClassTest : KKPXCTestCase

@end

@implementation KKPNewClassTest

- (void)testExample {
    /// 创建一个新类
    [self restartKKP];
    Class newClass = NSClassFromString(@"KKPNewClass");
    XCTAssertNil(newClass);
    NSString *script =
    @KKP_LUA(
             kkp_protocol("KKPNewClassProtocol", {
                 refreshView = "NSString*,void",
             },{
                 refreshData_ = "NSDictionary*,NSDictionary*"
             })
             kkp_class({"KKPNewClass", "NSObject", protocols={"KKPNewClassProtocol"}},
             function(_ENV)
                 function refreshView()
                       return "有事"
                 end
             end,
             function(_ENV)
                 function refreshData_(data)
                       data.thingName = "有事"
                       return data
                 end
             end)
          );
    
    kkp_runLuaString(script);
    newClass = NSClassFromString(@"KKPNewClass");
    XCTAssertNotNil(newClass);
    
    /// 调用实例方法
    id instance = [[newClass alloc] init];
    XCTAssertEqualObjects([instance performSelector:NSSelectorFromString(@"refreshView")], @"有事");
    
    /// 调用类方法
    NSDictionary *data = @{
        @"thingName": @"没事"
    };
    XCTAssertEqualObjects([newClass performSelector:NSSelectorFromString(@"refreshData:") withObject:data][@"thingName"], @"有事");
}

@end
