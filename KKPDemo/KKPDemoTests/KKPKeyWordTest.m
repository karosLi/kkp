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
 测试在 lua 中的关键字
 */
@interface KKPKeyWordSuperTest : KKPXCTestCase

@end

@implementation KKPKeyWordSuperTest

- (NSString *)getString
{
    return @"SUPER getString";
}

@end

@interface KKPKeyWordTest : KKPKeyWordSuperTest
@end

@implementation KKPKeyWordTest

- (NSString *)getString
{
    return @"SELF getString";
}

+ (NSString *)getStaticString
{
    return @"SELF Static getString";
}

- (void)testSuperKeyWord {
    
    /// 测试 super 关键字
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPKeyWordTest"},
             function(_ENV)
                 function getString()
                       return self.super:getString()
                 end
             end)
             );
    
    kkp_runLuaString(script);
    NSString *string = [self getString];
    XCTAssert([string isEqualToString:@"SUPER getString"]);
}

- (void)testOriginKeyWord {
    
    /// 测试 super 关键字
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPKeyWordTest"},
             function(_ENV)
                 function getString()
                       return self.origin:getString()
                 end
             end)
             );
    
    kkp_runLuaString(script);
    NSString *string = [self getString];
    XCTAssert([string isEqualToString:@"SELF getString"]);
}

- (void)testClassKeyWord {
    
    /// 测试 class 关键字
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPKeyWordTest"},
             function(_ENV)
                 function getString()
                       return class:getStaticString()
                 end
             end)
             );
    
    kkp_runLuaString(script);
    NSString *string = [self getString];
    XCTAssert([string isEqualToString:@"SELF Static getString"]);
    
    
    /// 测试 类名调用
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPKeyWordTest"},
             function(_ENV)
                 function getString()
                       return KKPKeyWordTest:getStaticString()
                 end
             end)
             );
    
    kkp_runLuaString(script);
    string = [self getString];
    XCTAssert([string isEqualToString:@"SELF Static getString"]);
}

@end
