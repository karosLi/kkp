//
//  ProtocolLoader.h
//  kkp
//
//  Created by karos li on 2022/2/16.
//

#import <Foundation/Foundation.h>

/// 用于提前注册协议，方便 lua 在添加有参方法的时候，可以直接使用
@interface ProtocolLoader : NSObject <UIApplicationDelegate, UIWebViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, UITextViewDelegate, UITabBarControllerDelegate>
@end

@implementation ProtocolLoader
@end
