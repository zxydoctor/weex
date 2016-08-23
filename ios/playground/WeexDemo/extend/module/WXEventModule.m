/**
 * Created by Weex.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "WXEventModule.h"
#import "WXDemoViewController.h"
#import <WeexSDK/WXBaseViewController.h>

@implementation WXEventModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(openURL:))
WX_EXPORT_METHOD(@selector(openBrowser:))

- (void)openURL:(NSString *)url
{
    NSString *newURL = url;
    if ([url hasPrefix:@"//"]) {
        newURL = [NSString stringWithFormat:@"http:%@", url];
    } else if (![url hasPrefix:@"http"]) {
        // relative path
        newURL = [NSURL URLWithString:url relativeToURL:weexInstance.scriptURL].absoluteString;
    }
    
    UIViewController *controller = [[WXDemoViewController alloc] init];
    ((WXDemoViewController *)controller).url = [NSURL URLWithString:newURL];
    
    [[weexInstance.viewController navigationController] pushViewController:controller animated:YES];
}

- (void)openBrowser:(NSString *)url
{
    NSURL * URL = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    if (URL) {
        [[UIApplication sharedApplication] openURL:URL];
    }
}

- (void)refresh:(NSString*)url
{
    
}

@end

