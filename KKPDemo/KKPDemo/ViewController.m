//
//  ViewController.m
//  KKPDemo
//
//  Created by karos li on 2022/3/8.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <KKPDemo-Swift.h>

@interface ViewController () {
    NSInteger _aInteger;
}

@property(nonatomic, assign) NSInteger age;
@property(nonatomic, strong) UIButton *gotoButton;
@property(nonatomic, strong) UIButton *gotoSwiftButton;
@property (nonatomic) CGRect vRect;

@property (nonatomic) int index;

@end

@implementation ViewController

- (instancetype)init {
    self = [super init];
    _aInteger = 0;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    [self doSomeThing:@"做饭"];
    NSLog(@"【原生】ViewController 年龄 %zd", self.age);
    
    [self blockOneArg:^int(int i) {
        return i;
    }];
    NSLog(@"【原生】ViewController blockOneArg 期望的 index 是 12，目前 index 是 %d", self.index);
    NSLog(@"【原生】ViewController 私有变量 _aInteger %ld", _aInteger);
    
    NSString *value = [self blockReturnBoolWithString](@"xxx");
    NSLog(@"【原生】ViewController blockReturnBoolWithString 调用结果 %@", value);
    
    CGRect xrect;
    xrect.origin.x = 3.0;
    xrect.origin.y = 4.0;
    xrect.size.width = 5.0;
    xrect.size.height = 6.0;
    CGRect rect = [self argInRect:xrect];
    NSLog(@"【原生】ViewController argInRect 期望 x 是 10.0，目前 x 是 %f", rect.origin.x);
}

- (void)setup {
    self.view.backgroundColor = [UIColor greenColor];
    _gotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_gotoButton setTitle:@"跳转" forState:UIControlStateNormal];
    [_gotoButton addTarget:self action:@selector(onClickGotoButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.gotoButton];
    self.gotoButton.frame = CGRectMake(100, 200, 100, 40);
    
    _gotoSwiftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_gotoSwiftButton setTitle:@"跳转到Swift页面" forState:UIControlStateNormal];
    [_gotoSwiftButton addTarget:self action:@selector(onClickGotoSwiftButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.gotoSwiftButton];
    self.gotoSwiftButton.frame = CGRectMake(100, 250, 200, 40);
}

- (void)doSomeThing:(NSString *)thingName {
    NSLog(@"【原生】ViewController 原始调用 doSomeThing %@", thingName);
}

- (NSString *)getHello {
    return @"ViewController Hello World!";
}

+ (void)printHello {
    NSLog(@"【原生】ViewController print in OC %@", @"Hello World!");
}

+ (void)testStatic {
    NSLog(@"【原生】ViewController testStatic in OC %@", @"testStatic");
}

- (void)onClickGotoButton {
    NSLog(@"onClickGotoButton");
}

/// lua 脚本 hook 这个方法
- (void)blockOneArg:(int(^)(int i))block {
     self.index = block(11);
}

/// lua 脚本 hook 这个方法，并由 lua 返回 一个 oc block
- (NSString *(^)(NSString *))blockReturnBoolWithString {
    return ^(NSString *arg1){
        return @"hh";
    };
}

- (CGSize)getViewSize {
    return self.view.frame.size;
}

- (CGRect)argInRect:(CGRect)vRect
{
    return vRect;
}

- (void)onClickGotoSwiftButton {
    ViewController1 *vc1 = [ViewController1 new];
    [self.navigationController pushViewController:vc1 animated:YES];
}

@end
