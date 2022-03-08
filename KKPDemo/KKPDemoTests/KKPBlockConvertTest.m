//
//  KKPFunctionTest.m
//  kkpTests
//
//  Created by karos li on 2022/3/2.
//

#import <XCTest/XCTest.h>
#import <kkp/kkp.h>
#import "KKPXCTestCase.h"

@interface Person3 : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) int age;

@end

@implementation Person3

@end

typedef struct XPoint3 {
    int x;
    int y;
    double z;
} XPoint3;

/**
 测试原生 block 传给 lua 去调用
 */
@interface KKPBlockConvertTest : KKPXCTestCase

@property (nonatomic) char vChar;
@property (nonatomic) int vInt;
@property (nonatomic) short vShort;
@property (nonatomic) long vLong;
@property (nonatomic) long long vLongLong;
@property (nonatomic) float vFloat;
@property (nonatomic) double vDouble;
@property (nonatomic) CGFloat vCGFloat;
@property (nonatomic) bool vBool;
@property (nonatomic) char* vCharX;
@property (nonatomic) NSString* vNSString;
@property (nonatomic) NSNumber* vNSNumber;
@property (nonatomic) NSDictionary* vNSDictionary;
@property (nonatomic) NSArray* vNSArray;
@property (nonatomic) Person3* vPerson;
@property (nonatomic) XPoint3 vP;
@property (nonatomic) SEL vSel;

@end

@implementation KKPBlockConvertTest

- (void)argInChar:(char(^)(char c))block
{
    self.vChar = block('c');
}

- (void)argInInt:(int(^)(int c))block
{
    self.vInt = block(9);
}

- (void)argInShort:(short(^)(short c))block
{
    self.vShort = block(2);
}

- (void)argInLong:(long(^)(long l))block
{
    self.vLong = block(99);
}

- (void)argInLongLong:(long long(^)(long long l))block
{
    self.vLongLong = block(999);
}

- (void)argInFloat:(float(^)(float f))block
{
    self.vFloat = block(3.14f);
}

- (void)argInDouble:(double(^)(double df))block
{
    self.vDouble = block(3.14);
}

- (void)argInCGFloat:(CGFloat(^)(CGFloat df))block
{
    self.vCGFloat = block(3.14);
}

- (void)argInBool:(bool(^)(bool b))block
{
    self.vBool = block(true);
}

- (void)argInCharX:(char *(^)(char *))block
{
    self.vCharX = block("string");
}

- (void)argInNSString:(NSString *(^)(NSString *))block
{
    self.vNSString = block(@"NSString");
}

- (void)argInNSNumber:(NSNumber *(^)(NSNumber *))block
{
    self.vNSNumber = block(@1);
}

- (void)argInNSArray:(NSArray *(^)(NSArray *))block
{
    self.vNSArray = block(@[@1, @2]);
}

- (void)argInNSDictionary:(NSDictionary *(^)(NSDictionary *))block
{
    self.vNSDictionary = block(@{@"key1":@1, @"key2":@2});
}

- (void)argInPerson:(Person3 *(^)(Person3 *))block
{
    Person3* p = [[Person3 alloc] init];
    p.name = @"tom";
    p.age = 18;
    self.vPerson = block(p);
}

- (void)argInXPoint:(XPoint3(^)(XPoint3))block
{
    XPoint3 p;
    p.x = 2;
    p.y = 3;
    p.z = 8.8;
    self.vP = block(p);
}

- (void)argInSEL:(SEL(^)(SEL))block
{
    self.vSel = block(@selector(argInSEL:));
}

- (void)testExample {
    /// 原生 block，入参为 char
    [self restartKKP];
    NSString *script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInChar_(blk)
                       self:setVChar_(blk('d'))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInChar:^char(char c) {
        return c;
    }];
    XCTAssert(self.vChar == 'd');
    
    
    /// 原生 block，入参为 int
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInInt_(blk)
                       self:setVInt_(blk(10))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInInt:^int(int c) {
        return c;
    }];
    XCTAssert(self.vInt == 10);
    
    
    /// 原生 block，入参为 short
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInShort_(blk)
                       self:setVShort_(blk(1))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInShort:^short(short c) {
        return c;
    }];
    XCTAssert(self.vShort == 1);
    
    
    /// 原生 block，入参为 long
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInLong_(blk)
                       self:setVLong_(blk(999))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInLong:^long(long c) {
        return c;
    }];
    XCTAssert(self.vLong == 999);
    
    
    /// 原生 block，入参为 long long
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInLongLong_(blk)
                       self:setVLongLong_(blk(9999))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInLongLong:^long long(long long c) {
        return c;
    }];
    XCTAssert(self.vLongLong == 9999);
    
    
    /// 原生 block，入参为 float
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInFloat_(blk)
                       self:setVFloat_(blk(4.18))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInFloat:^float(float c) {
        return c;
    }];
    XCTAssert(self.vFloat == 4.18f);
    
    
    /// 原生 block，入参为 double
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInDouble_(blk)
                       self:setVDouble_(blk(5.72))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInDouble:^double(double c) {
        return c;
    }];
    XCTAssert(self.vDouble == 5.72);
    
    
    /// 原生 block，入参为 CGFloat
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInCGFloat_(blk)
                       self:setVCGFloat_(blk(5.72))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInCGFloat:^CGFloat(CGFloat c) {
        return c;
    }];
    XCTAssert(self.vCGFloat == (CGFloat)5.72);
    
    
    /// 原生 block，入参为 bool
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInBool_(blk)
                       self:setVBool_(blk(false))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInBool:^bool(bool c) {
        return c;
    }];
    XCTAssert(self.vBool == false);
    
    
    /// 原生 block，入参为 char *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInCharX_(blk)
                       self:setVCharX_(blk("sstring"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInCharX:^char *(char * s) {
        return s;
    }];
    XCTAssert(strcmp(self.vCharX, "sstring") == 0);
    
    
    /// 原生 block，入参为 NSString *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInNSString_(blk)
                       self:setVNSString_(blk("NSNSString"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInNSString:^NSString *(NSString * s) {
        return s;
    }];
    XCTAssert([self.vNSString isEqualToString:@"NSNSString"]);
    
    
    /// 原生 block，入参为 NSNumber *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInNSNumber_(blk)
                       self:setVNSNumber_(blk(2))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInNSNumber:^NSNumber *(NSNumber * s) {
        return s;
    }];
    XCTAssert([self.vNSNumber isEqualToNumber:@2]);
    
    
    /// 原生 block，入参为 NSArray *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInNSArray_(blk)
                       self:setVNSArray_(blk({2, 3}))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInNSArray:^NSArray *(NSArray * s) {
        return s;
    }];
    id array = @[@2, @3];
    XCTAssert([self.vNSArray isEqualToArray:array]);
    
    
    /// 原生 block，入参为 NSDictionary *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInNSDictionary_(blk)
                       self:setVNSDictionary_(blk({key1=2, key2=3}))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInNSDictionary:^NSDictionary *(NSDictionary * s) {
        return s;
    }];
    id dict = @{@"key1":@2, @"key2":@3};
    XCTAssert([self.vNSDictionary isEqualToDictionary:dict]);
    
    
    /// 原生 block，入参为 Person3 *
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInPerson_(blk)
                       local p = Person3:alloc():init()
                       p:setName_("tom2")
                       p:setAge_(22)
                       self:setVPerson_(blk(p))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInPerson:^Person3 *(Person3* s) {
        return s;
    }];
    XCTAssert([self.vPerson.name isEqualToString:@"tom2"]);
    XCTAssert(self.vPerson.age == 22);
    
    
    /// 原生 block，入参为 XPoint3 结构体
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_struct({name = "XPoint3", types = "int,int,double", keys = "x,y,z"})
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInXPoint_(blk)
                       self:setVP_(blk(XPoint3({x=3, y=4, z=9.9})))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInXPoint:^XPoint3(XPoint3 xp) {
        return xp;
    }];
    XCTAssert(self.vP.x == 3);
    XCTAssert(self.vP.y == 4);
    XCTAssert(self.vP.z == 9.9);
    
    
    /// 原生 block，入参为 SEL
    [self restartKKP];
    script =
    @KKP_LUA(
             kkp_class({"KKPBlockConvertTest"},
             function(_ENV)
                 function argInSEL_(blk)
                       self:setVSel_(blk("argInXPoint:"))
                 end
             end)
             );
    
    kkp_runLuaString(script);
    [self argInSEL:^SEL(SEL sel) {
        return sel;
    }];
    XCTAssert(self.vSel == @selector(argInXPoint:));
}

@end
