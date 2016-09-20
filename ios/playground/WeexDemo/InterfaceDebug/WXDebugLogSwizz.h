//
//  WXDebugLogSwizz.h
//  WeexDemo
//
//  Created by 鲁强 on 16/8/15.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, WXDebugLogOptions) {
    WXDebugLogFPS           = 1 << 0,
    WXDebugLogPerformance   = 1 << 1,
    WXDebugLogError         = 1 << 2,
    
    WXDebugLogMemory        = WXDebugLogFPS|WXDebugLogPerformance,
    
    WXDebugLogAll = -1,
};

@interface WXDebugLogSwizz : NSString

+ (void)wxDebugLog:(WXDebugLogOptions)options;

@end
