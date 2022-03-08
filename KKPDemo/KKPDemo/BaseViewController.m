//
//  BaseViewController.m
//  kkp
//
//  Created by karos li on 2022/2/8.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)doSomeThing:(NSString *)thindName {
    NSLog(@"【原生】BaseViewController 父类调用 doSomeThing %@", thindName);
}

@end
