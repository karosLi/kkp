//
//  KKPFunctionTest.m
//  kkpTests
//
//  Created by karos li on 2022/3/2.
//

#import <XCTest/XCTest.h>
#import <kkp/kkp.h>
#import "KKPXCTestCase.h"

@interface Person2 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) NSNumber* age;

@end

@implementation Person2

@end

typedef struct XPoint2 {
    int x;
    int y;
} XPoint2;

/**
 测试创建实例并返回给原生
 */
@interface KKPNewInstanceTest : KKPXCTestCase

@end

@implementation KKPNewInstanceTest

- (char)argInChar
{
    return 'c';
}

- (int)argInInt
{
    return 9;
}

- (short)argInShort
{
    return 9;
}

- (long)argInLong
{
    return 9;
}

- (long long)argInLongLong
{
    return 9;
}

- (float)argInFloat
{
    return 3.14f;
}

- (double)argInDouble
{
    return 3.14f;
}

- (bool)argInBool
{
    return true;
}

- (char *)argInCharX
{
    return "string";
}

- (NSString *)argInString
{
    return @"NSString";
}

- (NSNumber *)argInNSNumber
{
    return @9;
}

- (NSArray *)argInNSArray
{
    return @[@1, @2];
}

- (NSDictionary *)argInNSDictionary
{
    return @{@"key1":@1, @"key2":@2};
}

- (Person2 *)argInPerson
{
    Person2* p = [[Person2 alloc] init];
    p.name = @"joy";
    p.age = @18;
    return p;
}

- (XPoint2)argInXPoint
{
    XPoint2 p;
    p.x = 3;
    p.y = 4;
    return p;
}

- (SEL)argInSel
{
    return @selector(argInSel);
}

- (void)testExample {
    /// 返回自定义结构体 XPoint2
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_struct({name = "XPoint2", types = "int,int", keys = "x,y"})
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInXPoint()
                       return XPoint2({x=3, y=4})
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInXPoint].x == 3);
    XCTAssert([self argInXPoint].y == 4);
    
    
    /// 返回 char
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInChar()
                       return 'c'
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInChar] == 'c');
    
    
    /// 返回 int
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInInt()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInInt] == 9);
    
    
    /// 返回 short
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInShort()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInShort] == 9);
    
    
    /// 返回 long
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInLong()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInLong] == 9);
    
    
    /// 返回 long long
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInLongLong()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInLongLong] == 9);
    
    
    /// 返回 float
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInFloat()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInFloat] == 9);
    
    
    /// 返回 double
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInDouble()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInDouble] == 9);
    
    
    /// 返回 bool
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInBool()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInBool] == true);
    
    
    /// 返回 char *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInCharX()
                       return "string"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert(strcmp([self argInCharX], "string") == 0);
    
    
    /// 返回 NSString *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInString()
                       return "NSString"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([[self argInString] isEqualToString:@"NSString"]);
    
    
    /// 返回 NSNumber *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInNSNumber()
                       return 9
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([[self argInNSNumber] isEqualToNumber:@9]);
    
    
    /// 返回 NSArray *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInNSArray()
                       return {1, 2}
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([[[self argInNSArray] objectAtIndex:0] isEqualToNumber:@1]);
    XCTAssert([[[self argInNSArray] objectAtIndex:1] isEqualToNumber:@2]);
    
    
    /// 返回 NSDictionary *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInNSDictionary()
                       return {key1=1, key2=2}
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([[[self argInNSDictionary] objectForKey:@"key1"] isEqualToNumber:@1]);
    XCTAssert([[[self argInNSDictionary] objectForKey:@"key2"] isEqualToNumber:@2]);
    
    
    /// 返回 Person2 *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInPerson()
                       local p = Person2:alloc():init()
                       p:setName_("joy")
                       p:setAge_(18)
                       return p
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([[self argInPerson].name isEqualToString:@"joy"]);
    XCTAssert([[self argInPerson].age isEqualToNumber:@18]);
    
    
    /// 返回 SEL
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPNewInstanceTest"},
             function(_ENV)
                 function argInSel()
                       return "argInSel"
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self argInSel] == @selector(argInSel));
}

@end
