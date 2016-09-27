/**
 * Created by Weex.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "WXDatePickerModule.h"
#import <UIKit/UIDatePicker.h>

@interface WXDatePickerModule()

@property(nonatomic,copy)WXModuleCallback callback;
@property(nonatomic,strong)UIDatePicker *datePicker;

@end

@implementation WXDatePickerModule
@synthesize weexInstance;
@synthesize datePicker;

WX_EXPORT_METHOD(@selector(pick:option:callback:))


-(void)pick:(NSString *)type option:(NSDictionary *)option callback:(WXModuleCallback)callback
{
    
    datePicker=[[UIDatePicker alloc]init];
    datePicker.datePickerMode=UIDatePickerModeDate;
    UIToolbar *toolBar=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    [toolBar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn=[[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(confirm:)];
    UIBarButtonItem *cancelBtn=[[UIBarButtonItem alloc]initWithTitle:@"cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    [toolBar setItems:[NSArray arrayWithObjects:cancelBtn,doneBtn, nil]];
    self.callback = callback;
}


-(IBAction)cancel:(id)sender
{
    
}

-(IBAction)confirm:(id)sender
{
    
}


@end
