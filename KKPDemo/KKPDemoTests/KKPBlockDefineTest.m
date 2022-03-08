//
//  KKPFunctionTest.m
//  kkpTests
//
//  Created by karos li on 2022/3/2.
//

#import <XCTest/XCTest.h>
#import <kkp/kkp.h>
#import "KKPXCTestCase.h"

@interface Person4 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) NSNumber* age;

@end

@implementation Person4

@end

typedef struct XPoint4 {
    int x;
    int y;
} XPoint4;


/**
 测试在 lua 定义 block 返回给原生
 */
@interface KKPBlockDefineTest : KKPXCTestCase

@property (nonatomic) char vChar;
@property (nonatomic) int vInt;
@property (nonatomic) short vShort;
@property (nonatomic) long vLong;
@property (nonatomic) long long vLongLong;
@property (nonatomic) float vFloat;
@property (nonatomic) double vDouble;
@property (nonatomic) double vCGFloat;
@property (nonatomic) bool vBool;
@property (nonatomic) char* vCharX;
@property (nonatomic) NSString* vNSString;
@property (nonatomic) NSNumber* vNSNumber;
@property (nonatomic) NSDictionary* vNSDictionary;
@property (nonatomic) NSArray* vNSArray;
@property (nonatomic) Person4* vPerson;
@property (nonatomic) XPoint4 vP;
@property (nonatomic) CGRect rect;
@property (nonatomic) SEL vSel;

@end

@implementation KKPBlockDefineTest

- (void(^)(void))blkVoidVoid
{
    return nil;
}

- (void(^)(int))blkVoidOne
{
    return nil;
}

- (int(^)(void))blkOneVoid
{
    return nil;
}

- (void(^)(char, int, short, long, long long, float, double, CGFloat, bool, char*, NSString*, NSNumber*, NSDictionary*, NSArray*, Person4*))blkVoidTotal
{
    return nil;
}

- (void(^)(XPoint4))blkVoidStruct
{
    return nil;
}

- (void(^)(XPoint4, CGRect))blkVoidStruct2
{
    return nil;
}

- (void)testExample {
    /// 返回 无参无返回值 block
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkVoidVoid()
                       return kkp_block(function()
                                            self:setVInt_(1)
                                        end, "void,void")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self blkVoidVoid]();
    XCTAssert(self.vInt == 1);
    
    
    /// 返回 一个入参无返回值 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkVoidOne()
                       return kkp_block(function(i)
                                            self:setVInt_(i)
                                        end, "void,int")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self blkVoidOne](2);
    XCTAssert(self.vInt == 2);
    
    
    /// 返回 无参一个返回值 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkOneVoid()
                       return kkp_block(function()
                                            return 5
                                        end, "int,void")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkOneVoid]() == 5);
}

- (void)testTotal {
    /// 返回 多入参无返回值 block
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkVoidTotal()
                       return kkp_block(function(c, i, s, l, q, f, d, g, B, ss, ns_string, ns_number, ns_dict, ns_array, person)
                                        self:setVChar_(c)
                                        self:setVInt_(i)
                                        self:setVShort_(s)
                                        self:setVLong_(l)
                                        self:setVLongLong_(q)
                                        self:setVFloat_(f)
                                        self:setVDouble_(d)
                                        self:setVCGFloat_(g)
                                        self:setVBool_(B)
                                        self:setVCharX_(ss)
                                        self:setVNSString_(ns_string)
                                        self:setVNSNumber_(ns_number)
                                        self:setVNSDictionary_(ns_dict)
                                        self:setVNSArray_(ns_array)
                                        self:setVPerson_(person)
                                        end, "void,char,int,short,long,long long,float,double,CGFloat,bool,char *,NSString *,NSNumber *,NSDictionary *,NSArray *,@")
                 end
             end)
             );
    
    Person4 *p = [[Person4 alloc] init];
    p.name = @"kk";
    p.age = @99;
    
    kkp_runLuaString(script);
    [self blkVoidTotal]('o', 1, 2, 3, 4, 5.5f, 5.5, 5.7, true, "bbq", @"nsstring", @9, @{@"key1":@1, @"key2":@2}, @[@1, @2], p);
    XCTAssert(self.vChar == 'o');
    XCTAssert(self.vInt == 1);
    XCTAssert(self.vShort == 2);
    XCTAssert(self.vLong == 3);
    XCTAssert(self.vLongLong == 4);
    XCTAssert(self.vFloat == 5.5f);
    XCTAssert(self.vDouble == 5.5);
    XCTAssert(self.vCGFloat == (CGFloat)5.7);
    XCTAssert(self.vBool == true);
    XCTAssert(strcmp(self.vCharX, "bbq") == 0);
    XCTAssert([self.vNSString isEqualToString:@"nsstring"]);
    XCTAssert([self.vNSNumber isEqualToNumber:@9]);
    id dict = @{@"key1":@1, @"key2":@2};
    XCTAssert([self.vNSDictionary isEqualToDictionary:dict]);
    id array = @[@1, @2];
    XCTAssert([self.vNSArray isEqualToArray:array]);
    XCTAssert([self.vPerson.name isEqualToString:@"kk"]);
    XCTAssert([self.vPerson.age isEqualToNumber:@99]);
}

- (void)testStruct {
    /// 返回 一个结构体入参无返回值 block
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_struct({name = "XPoint4", types = "int,int", keys = "x,y"})
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkVoidStruct()
                       return kkp_block(function(point)
                                            print(tostring(point))
                                            self:setVP_(point)
                                        end, "void,{XPoint4=int,int}")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XPoint4 p;
    p.x = 3;
    p.y = 4;
    [self blkVoidStruct](p);
    XCTAssert(self.vP.x == 3);
    XCTAssert(self.vP.y == 4);
    
    
    /// 返回 两个结构体入参无返回值 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_struct({name = "XPoint4", types = "int,int", keys = "x,y"})
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkVoidStruct2()
                       return kkp_block(function(point, rect)
                                            self:setVP_(point)
                                            self:setRect_(rect)
                                        end, "void,{XPoint4=int,int},{CGRect=CGFloat,CGFloat,CGFloat,CGFloat}")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XPoint4 p2;
    p2.x = 6;
    p2.y = 8;
    [self blkVoidStruct2](p, CGRectMake(1, 2, 3, 4));
    XCTAssert(self.vP.x == 3);
    XCTAssert(self.vP.y == 4);
    XCTAssert(self.rect.origin.x == 1);
    XCTAssert(self.rect.origin.y == 2);
    XCTAssert(self.rect.size.width == 3);
    XCTAssert(self.rect.size.height == 4);
}



- (BOOL(^)(void))blkReturnBool
{
    return nil;
}

- (char *(^)(void))blkReturnCharX
{
    return nil;
}

- (SEL(^)(void))blkReturnSEL
{
    return nil;
}

- (Class(^)(void))blkReturnClass
{
    return nil;
}

- (char(^)(void))blkReturnChar
{
    return nil;
}

- (int(^)(void))blkReturnInt
{
    return nil;
}

- (long(^)(void))blkReturnLong
{
    return nil;
}

- (short(^)(void))blkReturnShort
{
    return nil;
}

- (float(^)(void))blkReturnFloat
{
    return nil;
}

- (double(^)(void))blkReturnDouble
{
    return nil;
}

- (long long(^)(void))blkReturnLongLong
{
    return nil;
}

- (CGFloat(^)(void))blkReturnCGFloat
{
    return nil;
}

- (XPoint4(^)(void))blkReturnXPoint
{
    return nil;
}

- (void)testReturn {
    /// 返回 无参带BOOL返回值的 block
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnBool()
                       return kkp_block(function()
                                           return true
                                        end, "BOOL")
                 end
             end)
             );

    kkp_runLuaString(script);
    XCTAssert([self blkReturnBool]() == true);

    
    /// 返回 无参带char*返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnCharX()
                       return kkp_block(function()
                                           return "string"
                                        end, "char *")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert(strcmp([self blkReturnCharX](), "string") == 0);
    
    
    /// 返回 无参带SEL返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnSEL()
                       return kkp_block(function()
                                           return "selector"
                                        end, "char *")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert(strcmp(sel_getName([self blkReturnSEL]()) ,"selector") == 0);
    
    
    /// 返回 无参带Class返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnClass()
                       return kkp_block(function()
                                           return UIColor
                                        end, "@")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnClass]() == NSClassFromString(@"UIColor"));
    
    
    /// 返回 无参带char返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnChar()
                       return kkp_block(function()
                                           return 'c'
                                        end, "char")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnChar]() == 'c');
    
    
    /// 返回 无参带int返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnInt()
                       return kkp_block(function()
                                           return 1
                                        end, "int")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnInt]() == 1);
    
    
    /// 返回 无参带long返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnLong()
                       return kkp_block(function()
                                           return 100
                                        end, "long")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnLong]() == 100);
    
    
    /// 返回 无参带short返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnShort()
                       return kkp_block(function()
                                           return 10
                                        end, "short")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnShort]() == 10);
    
    
    /// 返回 无参带float返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnFloat()
                       return kkp_block(function()
                                           return 3.14
                                        end, "float")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnFloat]() == 3.14f);
    
    
    /// 返回 无参带double返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnDouble()
                       return kkp_block(function()
                                           return 7.14
                                        end, "double")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnDouble]() == 7.14);
    
    
    /// 返回 无参带longlong返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnLongLong()
                       return kkp_block(function()
                                           return 70000
                                        end, "long long")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnLongLong]() == 70000);
    
    
    /// 返回 无参带CGFloat返回值的 block
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnCGFloat()
                       return kkp_block(function()
                                           return 5.12
                                        end, "CGFloat")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XCTAssert([self blkReturnCGFloat]() == (CGFloat)5.12);
}

- (void)testReturnStruct {
    /// 返回 无参带结构体返回值的 block
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_struct({name = "XPoint4", types = "int,int", keys = "x,y"})
             kkp_class({"KKPBlockDefineTest"},
             function(_ENV)
                 function blkReturnXPoint()
                       return kkp_block(function()
                                            return XPoint4({x=3, y=4})
                                        end, "{XPoint4=int,int}")
                 end
             end)
             );
    
    kkp_runLuaString(script);
    XPoint4 xp = [self blkReturnXPoint]();
    XCTAssert(xp.x == 3 && xp.y == 4);
}

@end
