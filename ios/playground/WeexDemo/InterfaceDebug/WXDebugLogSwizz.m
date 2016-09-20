//
//  WXDebugLogSwizz.m
//  WeexDemo
//
//  Created by 鲁强 on 16/8/15.
//  Copyright © 2016年 taobao. All rights reserved.
//

#import "WXDebugLogSwizz.h"

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WeexSDK/WeexSDK.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

@implementation WXDebugLogSwizz

+ (void)wxDebugLog:(WXDebugLogOptions)options {
    if (options & WXDebugLogFPS) {
        [self wxDebugLog_FPS];
    }
    if (options & WXDebugLogPerformance) {
        [self wxDebugLog_Performance];
    }
    if (options & WXDebugLogError) {
        [self wxDebugLog_Error];
    }
    if (options & WXDebugLogMemory) {
        [self wxDebugLog_Memory];
    }
}

#pragma mark - support method
+ (void)swizzClass:(id)originalClass selector:(SEL)originalSelector withClass:(id)swizzledClass selector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    
    IMP originalImp = method_getImplementation(originalMethod);
    IMP swizzledImp = method_getImplementation(swizzledMethod);
    
    const char *originalTypeEncoding = method_getTypeEncoding(originalMethod);
    const char *swizzledTypeEncoding = method_getTypeEncoding(swizzledMethod);
    
    // add swizzled method
    BOOL didAddMethod;
    didAddMethod = class_addMethod(originalClass, swizzledSelector, originalImp, originalTypeEncoding);
    
    // add original method
    didAddMethod = class_addMethod(originalClass, originalSelector, swizzledImp, swizzledTypeEncoding);
    if (didAddMethod) {
        class_replaceMethod(originalClass, swizzledSelector, originalImp, originalTypeEncoding);
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)printLog:(NSString *)logStr {
    
#ifdef NSLog
#undef NSLog
#define NSLog(...) NSLog(__VA_ARGS__)
    NSLog(@" <Weex> %@", logStr);
#undef NSLog
#ifdef DEBUG
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif
#else
    NSLog(@" <Weex> %@", logStr);
#endif
    
}

#pragma mark - FPS
CADisplayLink *_displayLink;
NSMutableArray *_fpsTimes;
NSTimeInterval _lastTime = 0;

// PFS - 实现
+ (void)wxDebugLog_FPS {
    
    // 环境初始化
    if ( nil == _fpsTimes ) {
        _fpsTimes = [[NSMutableArray alloc]init];
    }
    if (nil == _displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        _displayLink.paused = YES;
    }
    
    // hook到FPS的实现方法
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class originalClass = [UIScrollView class];
        Class swizzledClass = [WXDebugLogSwizz class];
        
        // 1.hook到scrollView的delegate
        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(wx_hook_setDelegate:);
        [WXDebugLogSwizz swizzClass:originalClass selector:originalSelector withClass:swizzledClass selector:swizzledSelector];
        
        // 2.wx_hook_didMoveToSuperview
        originalClass = [UIViewController class];
        originalSelector = @selector(viewDidAppear:);
        swizzledSelector = @selector(wx_hook_viewDidAppear:);
        [WXDebugLogSwizz swizzClass:originalClass selector:originalSelector withClass:swizzledClass selector:swizzledSelector];
        
        originalSelector = @selector(viewWillDisappear:);
        swizzledSelector = @selector(wx_hook_viewWillDisappear:);
        [WXDebugLogSwizz swizzClass:originalClass selector:originalSelector withClass:swizzledClass selector:swizzledSelector];
    });
}

// FPS - hook到UISCrollView的delegate
- (void)wx_hook_setDelegate:(id<UIScrollViewDelegate>) delegate {
    // iOS 7 增加的东西
    
    if ([delegate isKindOfClass:[UITableViewCell class]] ||
        delegate == nil) {
        [self wx_hook_setDelegate:delegate];
        return;
    }
    
    
    Class listClass = NSClassFromString(@"WXListComponent");
    if ([delegate isKindOfClass:[listClass class]]) {
        printf("123\n");
    }
    
    // swizz method
    Class originalClass = [delegate class];
    Class swizzledClass = [WXDebugLogSwizz class];
    
    SEL originalSelector = @selector(scrollViewWillBeginDragging:);
    SEL swizzledSelector = @selector(wx_hook_scrollViewWillBeginDragging:);
    [WXDebugLogSwizz swizzClass:originalClass selector:originalSelector withClass:swizzledClass selector:swizzledSelector];
    
    originalSelector = @selector(scrollViewDidEndDragging:willDecelerate:);
    swizzledSelector = @selector(wx_hook_scrollViewDidEndDragging:willDecelerate:);
    [WXDebugLogSwizz swizzClass:originalClass selector:originalSelector withClass:swizzledClass selector:swizzledSelector];
    
    originalSelector = @selector(scrollViewDidEndDecelerating:);
    swizzledSelector = @selector(wx_hook_scrollViewDidEndDecelerating:);
    [WXDebugLogSwizz swizzClass:originalClass selector:originalSelector withClass:swizzledClass selector:swizzledSelector];
    
    // set delegate
    [self wx_hook_setDelegate:delegate];
}

// FPS - hook到开始滚动，此时开始计时FPS
- (void)wx_hook_scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self respondsToSelector:@selector(wx_hook_scrollViewWillBeginDragging:)]) {
        [self wx_hook_scrollViewWillBeginDragging:scrollView];
    }
    [WXDebugLogSwizz pauseDisplayLink:NO];
}

// FPS - hook到停止滚动，此时停止计时FPS
- (void)wx_hook_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self respondsToSelector:@selector(wx_hook_scrollViewDidEndDragging:willDecelerate:)]) {
        [self wx_hook_scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    if (!decelerate) {
        [WXDebugLogSwizz pauseDisplayLink:YES];
    }
}

// FPS - hook到停止惯性滚动，此时停止计时FPS
- (void)wx_hook_scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self respondsToSelector:@selector(wx_hook_scrollViewDidEndDecelerating:)]) {
        [self wx_hook_scrollViewDidEndDecelerating:scrollView];
    }
    [WXDebugLogSwizz pauseDisplayLink:YES];
}

// FPS - hook到加入父视图
- (void)wx_hook_viewDidAppear:(BOOL)animated {
    [self wx_hook_viewDidAppear:animated];
    
    [WXDebugLogSwizz calculateFPS];
}

// FPS - hook到移出父视图
- (void)wx_hook_viewWillDisappear:(BOOL)animated {
    [self wx_hook_viewWillDisappear:animated];
    
    [WXDebugLogSwizz calculateFPS];
}


// FPS - 统计
+ (void)handleDisplayLink:(CADisplayLink *)displayLink {
    // 1.首个时间戳初始化
    static NSTimeInterval currentTime;
    
    currentTime = displayLink.timestamp;
    if (_lastTime == 0) {
        _lastTime = currentTime;
        return;
    }
    
    // 2.统计时间戳和计数
    [_fpsTimes addObject:@(currentTime - _lastTime)];
    _lastTime = currentTime;
}

// FPS - 暂停&单次统计
+ (void)pauseDisplayLink:(BOOL)paused {
    if (paused == YES) {
        //        NSNumber *totalTime = [_fpsTimes valueForKeyPath:@"@sum.floatValue"];
        //        NSUInteger count = _fpsTimes.count;
        //        if (count>0) {
        //            NSString *fpsStr = [NSString stringWithFormat:@"test:\n    count: %ld,\n    time: %.1f,\n    FPS: %.1f,", (unsigned long)_fpsTimes.count, totalTime.floatValue, count/totalTime.floatValue];
        //            [WXDebugLogSwizz printLog:fpsStr];
        //
        //        }
    } else {
        _lastTime = 0;
    }
    _displayLink.paused = paused;
    
}

// FPS - 销毁&完整统计
+ (void)calculateFPS {
    [WXDebugLogSwizz pauseDisplayLink:YES];
    
    if (_fpsTimes.count == 0) {
        return;
    }
    
    NSNumber *totalTime = [_fpsTimes valueForKeyPath:@"@sum.floatValue"];;
    NSUInteger count = _fpsTimes.count;
    NSString *fpsStr = [NSString stringWithFormat:@"Metrics:\n\tcount=%lu,\n\tFPS=%.1f,", (unsigned long)_fpsTimes.count, count/totalTime.floatValue];
    [WXDebugLogSwizz printLog:fpsStr];
    
    [_fpsTimes removeAllObjects];
}

#pragma mark - Performance
NSNumber *_componentCount;
// Performance - 实现
+ (void)wxDebugLog_Performance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL sel = NSSelectorFromString(@"printPerformance:");
        Class originalClass = NSClassFromString(@"WXMonitor");
        [self swizzClass:object_getClass(originalClass) selector:sel withClass:object_getClass(self) selector:@selector(wx_hook_printPerformance:)];
        
        // 获取节点数
        sel = NSSelectorFromString(@"performanceFinish:");
        originalClass = NSClassFromString(@"WXMonitor");
        [self swizzClass:object_getClass(originalClass) selector:sel withClass:object_getClass(self) selector:@selector(wx_hook_performanceFinish:)];
    });
}

+ (void)wx_hook_performanceFinish:(WXSDKInstance *)instance {
    _componentCount = @([instance numberOfComponents]);
    [self wx_hook_performanceFinish:instance];
}

+ (void)wx_hook_printPerformance:(NSDictionary *)commitDict {
    [self wx_hook_printPerformance:commitDict];
    
    // call back
    if (perfMemoryCallback) {
        perfMemoryCallback();
    }
    
    //func
    NSMutableString *performanceString = [NSMutableString stringWithString:@"Performance:"];
    for (NSString *commitKey in commitDict) {
        [performanceString appendFormat:@"\n\t%@=%@,", commitKey, commitDict[commitKey]];
    }
    if (_componentCount) {
        [performanceString appendFormat:@"\n\t%@=%@,", @"componentCount", _componentCount];
    }
    
    [WXDebugLogSwizz printLog:performanceString];
}


#pragma mark - Error
+ (void)wxDebugLog_Error {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL sel = NSSelectorFromString(@"monitoringPoint:didFailWithError:onPage:");
        Class originalClass = NSClassFromString(@"WXMonitor");
        [self swizzClass:object_getClass(originalClass) selector:sel withClass:object_getClass(self) selector:@selector(wx_hook_monitoringPoint:didFailWithError:onPage:)];
    });
}


+ (void)wx_hook_monitoringPoint:(WXMonitorTag)tag didFailWithError:(NSError *)error onPage:(NSString *)pageName {
    [self wx_hook_monitoringPoint:tag didFailWithError:error onPage:pageName];
    
    NSString *errorLog = [NSString stringWithFormat:@"error:\n\t%@", error.localizedDescription];
    [WXDebugLogSwizz printLog:errorLog];
}

#pragma mark - memory
NSNumber *baseMemory;
void (^baseMemoryCallback)();
NSNumber *perfMemory;
void (^perfMemoryCallback)();
NSNumber *finalMemory;
NSNumber *destroyMemory;
void (^destroyMemoryCallback)();

+ (void)wxDebugLog_Memory {
    // swizz
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSel = NSSelectorFromString(@"destroyInstance");
        SEL swizzedSel = @selector(wx_hook_destroyInstance);
        Class originalClass = NSClassFromString(@"WXSDKInstance");
        Class swizzedClass = [WXDebugLogSwizz class];
        [self swizzClass:originalClass selector:originalSel withClass:swizzedClass selector:swizzedSel];
        
        originalSel = NSSelectorFromString(@"renderView:options:data:");
        swizzedSel = @selector(wx_hook_renderView:options:data:);
        [self swizzClass:originalClass selector:originalSel withClass:swizzedClass selector:swizzedSel];
    });
    
    // call back
    baseMemoryCallback = ^(){
        baseMemory = @([WXDebugLogSwizz getUsedMemory]);
    };
    perfMemoryCallback = ^(){
        perfMemory = @([WXDebugLogSwizz getUsedMemory]);
    };
    destroyMemoryCallback = ^(){
        finalMemory = @([WXDebugLogSwizz getUsedMemory]);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NSThread sleepForTimeInterval:10];
            destroyMemory = @([WXDebugLogSwizz getUsedMemory]);
            
            // print log
            if (baseMemory && perfMemory && finalMemory && destroyMemory) {
                NSInteger pageMemory = perfMemory.integerValue - baseMemory.integerValue;
                NSInteger pageinMemory = finalMemory.integerValue - perfMemory.integerValue;
                NSInteger increaseMemory = destroyMemory.integerValue - finalMemory.integerValue;
                
                NSMutableString *memoryLog = [[NSMutableString alloc]init];
                [memoryLog appendString:@"Memory:"];
                [memoryLog appendFormat:@"\n\tpageMemory=%.3f MB,",pageMemory/1024.0/1024.0];
                [memoryLog appendFormat:@"\n\tpageinMemory=%.3f MB,",pageinMemory/1024.0/1024.0];
                [memoryLog appendFormat:@"\n\tincreaseMemory=%.3f MB,",increaseMemory/1024.0/1024.0];
                [memoryLog appendFormat:@"\n\tbaseMemory=%.3f MB,",baseMemory.integerValue/1024.0/1024.0];
                [memoryLog appendFormat:@"\n\tperfMemory=%.3f MB,",perfMemory.integerValue/1024.0/1024.0];
                [memoryLog appendFormat:@"\n\tfinalMemory=%.3f MB,",finalMemory.integerValue/1024.0/1024.0];
                [memoryLog appendFormat:@"\n\tdestroyMemory=%.3f MB,",destroyMemory.integerValue/1024.0/1024.0];
                
                [WXDebugLogSwizz printLog:memoryLog];
            } else {
                baseMemory = nil;
                perfMemory = nil;
                finalMemory = nil;
                destroyMemory = nil;
            }
            
            
        });
        
    };
}

- (void)wx_hook_renderView:(NSString *)source options:(NSDictionary *)options data:(id)data {
    [self wx_hook_renderView:source options:options data:data];
    
    // call back
    if (baseMemoryCallback) {
        baseMemoryCallback();
    }
}

- (void)wx_hook_destroyInstance {
    [self wx_hook_destroyInstance];
    
    // call back
    if (destroyMemoryCallback) {
        destroyMemoryCallback();
    }
}

+ (NSInteger)getUsedMemory {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),
                                         TASK_BASIC_INFO,
                                         (task_info_t)&taskInfo,
                                         &infoCount);
    
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    
    return taskInfo.resident_size;
}

@end
