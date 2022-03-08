//
//  ViewController.m
//  KKPExample
//
//  Created by karos li on 2022/3/8.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setMyView];
    [self requestAPI:^(NSString *result) {
        NSLog(@"【原生】获取网络请求结果:\n %@", result);
    }];
}

- (void)setMyView {
//    UIView *view = [UIView new];
//    [self.view addSubview:view];
//    view.backgroundColor = [UIColor greenColor];
//    [view mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(self.view);
//        make.width.offset(50);
//        make.height.offset(50);
//    }];
}

- (void)requestAPI:(void (^)(NSString *result))completion {
//    NSString *url = @"https://github.com/karosLi/kkp/blob/main/kkp/stdlib/init.lua";
//    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if (completion) {
//            completion([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//        }
//    }];
}

@end
