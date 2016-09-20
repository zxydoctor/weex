//
//  InterfaceDebug.m
//  TBWeex
//
//  Created by 鲁强 on 16/8/17.
//  Copyright © 2016年 rocky. All rights reserved.
//

#import "InterfaceDebug.h"
#import "WXDebugLogSwizz.h"

@implementation InterfaceDebug

+ (void)executeTestMethod {
    // 1.weex debug log
    [WXDebugLogSwizz wxDebugLog:WXDebugLogAll];
}

@end
