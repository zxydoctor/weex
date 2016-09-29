/**
 * Created by Weex.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "WXDatePickerModule.h"
#import <UIKit/UIDatePicker.h>

#define WXPickerHeight 266

@interface WXDatePickerModule()

@property(nonatomic,copy)WXModuleCallback callback;
@property(nonatomic,strong)UIDatePicker *datePicker;
@property(nonatomic,strong)UIView *backgroudView;
@property(nonatomic,strong)UIView *datePickerView;
@property(nonatomic)BOOL isAnimating;



@end

@implementation WXDatePickerModule
@synthesize weexInstance;
@synthesize datePicker;

WX_EXPORT_METHOD(@selector(pick:option:callback:))


-(void)pick:(NSString *)type option:(NSDictionary *)dateInfo callback:(WXModuleCallback)callback
{
    if(!self.backgroudView)
    {
        self.backgroudView = [self createBackgroudView];
        UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideDatePicker)];
        [self.backgroudView addGestureRecognizer:tapGesture];
    }
    
    if(!self.datePickerView)
    {
        self.datePickerView = [self createDatePickerView];
    }
    
    if(!datePicker)
    {
        datePicker = [[UIDatePicker alloc]init];
    }
    
    
    
    datePicker.datePickerMode=UIDatePickerModeDate;
    CGRect pickerFrame = CGRectMake(0, 44, [UIScreen mainScreen].bounds.size.width, WXPickerHeight-44);
    datePicker.backgroundColor = [UIColor whiteColor];
    datePicker.frame = pickerFrame;
    UIToolbar *toolBar=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    [toolBar setBackgroundColor:[UIColor whiteColor]];
    UIBarButtonItem* noSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    noSpace.width=10;
    UIBarButtonItem* doneBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* cancelBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    [toolBar setItems:[NSArray arrayWithObjects:noSpace,cancelBtn,flexSpace,doneBtn,noSpace, nil]];
    self.callback = callback;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [self.datePickerView addSubview:datePicker];
    [self.datePickerView addSubview:toolBar];
    [self.backgroudView addSubview:self.datePickerView];
    [window addSubview:self.backgroudView];
    [self configDatePicker:type dateInfo:dateInfo];
    [self showDatePicker];
    
}


-(void)configDatePicker:(NSString *)type dateInfo:(NSDictionary *)dateInfo
{
    if(type && [type isEqualToString:@"time"])
    {
        NSString *timeStr = [NSString stringWithFormat:@"%@:%@",[dateInfo objectForKey:@"hour"],[dateInfo objectForKey:@"minute"]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:@"HH:mm"];
        NSDate *date=[formatter dateFromString:timeStr];
        self.datePicker.date = date;
        self.datePicker.datePickerMode = UIDatePickerModeTime;
    }else if(type && [type isEqualToString:@"date"])
    {
        self.datePicker.datePickerMode = UIDatePickerModeDate;
        self.datePicker.date = [self converDate:[dateInfo objectForKey:@"date"]];
        self.datePicker.minimumDate = [self converDate:[dateInfo objectForKey:@"minDate"]];
        self.datePicker.maximumDate = [self converDate:[dateInfo objectForKey:@"maxDate"]];
        
    }
    
}

// jsbridge 和 ponydebugbridge 转换的格式不一样，需要分开处理
-(NSDate *)converDate:(id)date
{
    if(date && [date isKindOfClass:[NSString class]])
    {
        return [self stringToDate:date];
    }
    return date;
    
}

-(UIView *)createBackgroudView
{
    UIView *view = [UIView new];
    view.frame = [UIScreen mainScreen].bounds;
    view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];
    return view;
}

-(UIView *)createDatePickerView
{
    UIView *view = [UIView new];
    view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, WXPickerHeight);
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

-(void)showDatePicker
{
    if(self.isAnimating)
    {
        return;
    }
    self.isAnimating = YES;
    self.backgroudView.hidden = NO;
    [UIView animateWithDuration:0.35f animations:^{
        self.datePickerView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - WXPickerHeight, [UIScreen mainScreen].bounds.size.width, WXPickerHeight);
        self.backgroudView.alpha = 1;
    } completion:^(BOOL finished) {
        self.isAnimating = NO;
    }];
}

-(void)hideDatePicker
{
    if(self.isAnimating)
    {
        return;
    }
    self.isAnimating = YES;
    [UIView animateWithDuration:0.35f animations:^{
        self.datePickerView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, WXPickerHeight);
        self.backgroudView.alpha = 0;
    } completion:^(BOOL finished) {
        self.backgroudView.hidden = YES;
        self.isAnimating = NO;
        [self.backgroudView removeFromSuperview];
    }];
}

-(IBAction)cancel:(id)sender
{
    [self hideDatePicker];
}

-(IBAction)done:(id)sender
{
    [self hideDatePicker];
    
    NSMutableDictionary *dic = [NSMutableDictionary new];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    NSDateComponents *comps  = [calendar components:unitFlags fromDate:self.datePicker.date];
    [dic setValue:[NSNumber numberWithInteger:[comps year]] forKey:@"year"];
    [dic setValue:[NSNumber numberWithInteger:[comps month]-1] forKey:@"month"];
    [dic setValue:[NSNumber numberWithInteger:[comps day]] forKey:@"date"];
    [dic setValue:[NSNumber numberWithInteger:[comps hour]] forKey:@"hour"];
    [dic setValue:[NSNumber numberWithInteger:[comps minute]] forKey:@"minute"];
    [dic setValue:[NSNumber numberWithBool:true] forKey:@"set"];
    
    self.callback(dic);
    self.callback = nil;
}


-(NSDate *)stringToDate:(NSString *)dateString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *date=[formatter dateFromString:dateString];
    return date;
}

@end
