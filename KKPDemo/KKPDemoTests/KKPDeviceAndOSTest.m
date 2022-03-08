//
//  KKPDeviceAndOSTest.m
//  kkpTests
//
//  Created by karos li on 2022/3/7.
//

#import <XCTest/XCTest.h>
#import <kkp/kkp.h>
#import "KKPXCTestCase.h"

/**
 测试系统和设备信息
 */
@interface KKPDeviceAndOSTest : KKPXCTestCase
@end

@implementation KKPDeviceAndOSTest

- (NSString *)systemVersion {
    return nil;
}

- (BOOL)systemVersionGE {
    return NO;
}

- (void)testOS {
    /// 测试 获取系统版本号
    /// -- return UIDevice:currentDevice():systemVersion()
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPDeviceAndOSTest"},
             function(_ENV)
                 function systemVersion()
                       return kkp.os.systemVersion
                 end
             end)
             );
    
    kkp_runLuaString(script);
    NSString *systemVersion = [self systemVersion];
    XCTAssertNotNil(systemVersion);
    
    
    /// 测试 大于等于目标系统版本号
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPDeviceAndOSTest"},
             function(_ENV)
                 function systemVersionGE()
                       return kkp.os.geOS(9)
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self systemVersionGE]);
}

- (NSDictionary *)deviceInfo {
    return nil;
}

- (void)testDevice {
    /// 测试 获取设备信息
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPDeviceAndOSTest"},
             function(_ENV)
                 function deviceInfo()
                       return kkp.device
                 end
             end)
             );
    
    kkp_runLuaString(script);
    NSDictionary *deviceInfo = [self deviceInfo];
    
    /**
     deviceInfo: {
         screenHeight = 568;
         screenScale = 2;
         screenWidth = 320;
     }
     */
    NSLog(@"deviceInfo: %@", deviceInfo);
    XCTAssertNotNil(deviceInfo);
}

@end
