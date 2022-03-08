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
 测试实例方法和静态方法替换
 */
@interface KKPMethodTest : KKPXCTestCase

@property (nonatomic, copy) NSString *thingName;

@end

@implementation KKPMethodTest

- (void)noArgNoResult {
    self.thingName = @"没事";
}

- (void)oneArgNoResult:(NSString *)thingName {
    self.thingName = thingName;
}

- (NSString *)noArgOneResult {
    return @"没事";
}

- (NSString *)oneArgOneResult:(NSString *)thingName {
    return @"没事";
}

- (NSString *)manyArgs:(NSString *)t1 t2:(NSString *)t2 t3:(NSString *)t3 t4:(NSString *)t4 t5:(NSString *)t5 t6:(NSString *)t6 t7:(NSString *)t7 t8:(NSString *)t8 t9:(NSString *)t9 {
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@", t1, t2, t3, t4, t5, t6, t7, t8, t9];
}

+ (NSString *)staticNoArgOneResult {
    return @"没事";
}

- (void)testExample {
    /// 无参数无结果
    [self restartKKP];
    [self noArgNoResult];
    XCTAssertEqualObjects(self.thingName, @"没事");
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPMethodTest"},
             function(_ENV)
                 function noArgNoResult()
                       self:setThingName_("有事")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self noArgNoResult];
    XCTAssertEqualObjects(self.thingName, @"有事");
    
    
    /// 一个参数无结果
    [self restartKKP];
    [self oneArgNoResult:@"没事"];
    XCTAssertEqualObjects(self.thingName, @"没事");
    script =
    @KKP_LUA(
             kkp_class({"KKPMethodTest"},
             function(_ENV)
                 function oneArgNoResult_(thingName)
                       self:setThingName_("有事")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self oneArgNoResult:@"没事"];
    XCTAssertEqualObjects(self.thingName, @"有事");
    
    
    /// 无参数一个结果
    [self restartKKP];
    XCTAssertEqualObjects([self noArgOneResult], @"没事");
    script =
    @KKP_LUA(
             kkp_class({"KKPMethodTest"},
             function(_ENV)
                 function noArgOneResult()
                       return "有事"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssertEqualObjects([self noArgOneResult], @"有事");
    
    
    /// 一个参数一个结果
    [self restartKKP];
    XCTAssertEqualObjects([self oneArgOneResult:@"没事"], @"没事");
    script =
    @KKP_LUA(
             kkp_class({"KKPMethodTest"},
             function(_ENV)
                 function oneArgOneResult_(thingName)
                       return "有事"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssertEqualObjects([self oneArgOneResult:@"没事"], @"有事");
    
    
    /// 许多参数
    [self restartKKP];
    XCTAssertEqualObjects([self manyArgs:@"t1" t2:@"t2" t3:@"t3" t4:@"t4" t5:@"t5" t6:@"t6" t7:@"t7" t8:@"t8" t9:@"t9"], @"t1t2t3t4t5t6t7t8t9");
    script =
    @KKP_LUA(
             kkp_class({"KKPMethodTest"},
             function(_ENV)
                 function manyArgs_t2_t3_t4_t5_t6_t7_t8_t9_(t1, t2, t3, t4, t5, t6, t7, t8, t9)
                       return t1..t2..t3..t4..t5..t6..t7..t8..t9.."t10"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssertEqualObjects([self manyArgs:@"t1" t2:@"t2" t3:@"t3" t4:@"t4" t5:@"t5" t6:@"t6" t7:@"t7" t8:@"t8" t9:@"t9"], @"t1t2t3t4t5t6t7t8t9t10");
    
    
    /// 静态方法 无参数一个结果
    [self restartKKP];
    XCTAssertEqualObjects([[self class] staticNoArgOneResult], @"没事");
    script =
    @KKP_LUA(
             kkp_class({"KKPMethodTest"},
             function(_ENV)
             end,
             function(_ENV)
                 function staticNoArgOneResult()
                       return "有事"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssertEqualObjects([[self class] staticNoArgOneResult], @"有事");
}

@end
