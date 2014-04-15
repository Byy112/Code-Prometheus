//
//  CPBindSafetyPhoneNumberViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-23.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPBindSafetyPhoneNumberViewController.h"
#import <TWMessageBarManager.h>
#import <MBProgressHUD.h>

@interface CPBindSafetyPhoneNumberViewController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *checkCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

// 定时器
@property (nonatomic,weak) NSTimer* timer;
@end

@implementation CPBindSafetyPhoneNumberViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"设置安全手机";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(back:)];
    // 更新UI
    [self updateUI];
    // 启动定时器刷新UI
    if (CPLastSendSMSTimeInterval!=0 && CPLastSendSMSTimeInterval+CP_SendSMSTimeInterval >= [[NSDate date] timeIntervalSince1970]) {
        [self fireTimer];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}
-(void)updateUI{
    if (CPLastSendSMSTimeInterval!=0 && CPLastSendSMSTimeInterval+CP_SendSMSTimeInterval >= [[NSDate date] timeIntervalSince1970]) {
        [self.sendButton setTitle:[NSString stringWithFormat:@"重新发送(%ds)",(NSInteger)(CPLastSendSMSTimeInterval+CP_SendSMSTimeInterval-[[NSDate date] timeIntervalSince1970])] forState:UIControlStateDisabled];
        self.sendButton.enabled = NO;
    }else{
        [self.sendButton setTitle:@"发送验证码到手机" forState:UIControlStateNormal];
        self.sendButton.enabled = YES;
    }
}

#define UpdateTimeInterval 1

-(void)fireTimer{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (CPLastSendSMSTimeInterval==0 || CPLastSendSMSTimeInterval+CP_SendSMSTimeInterval < [[NSDate date] timeIntervalSince1970]) {
        return;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:UpdateTimeInterval target:self selector:@selector(runLoopForTimer) userInfo:nil repeats:YES];
}
-(void) runLoopForTimer{
    // 更新UI
    [self updateUI];
    // 停止
    if (CPLastSendSMSTimeInterval==0 || CPLastSendSMSTimeInterval+CP_SendSMSTimeInterval < [[NSDate date] timeIntervalSince1970]) {
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    }
}

- (void)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendCheckcode:(id)sender {
    // 取消现有提示
    [[TWMessageBarManager sharedInstance] hideAll];
    // 启动进度条
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.removeFromSuperViewOnHide = YES;
	[self.view addSubview:hud];
    [hud show:YES];
    
    
    [CPServer sendSMSWithPhoneNumber:self.phoneNumberTextField.text block:^(BOOL success, NSString *message) {
        if (success) {
            // 设置最后发短信时间
            CPSetLastSendSMSTimeInterval([[NSDate date] timeIntervalSince1970]);
            // 刷新页面
            [self updateUI];
            // 启动定时器
            [self fireTimer];
            
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"OK"
                                                           description:@"发送成功"
                                                                  type:TWMessageBarMessageTypeSuccess];
            [hud hide:YES];
        }else{
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:message
                                                                  type:TWMessageBarMessageTypeError];
            [hud hide:YES];
        }
    }];
}
- (IBAction)confirm:(id)sender {
    // 取消现有提示
    [[TWMessageBarManager sharedInstance] hideAll];
    // 启动进度条
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.removeFromSuperViewOnHide = YES;
	[self.view addSubview:hud];
    [hud show:YES];
    
    [CPServer bindPhone:self.checkCodeTextField.text block:^(BOOL success, NSString *message) {
        if (success) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"OK"
                                                           description:@"绑定成功"
                                                                  type:TWMessageBarMessageTypeSuccess];
            [hud hide:YES];
        }else{
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:message
                                                                  type:TWMessageBarMessageTypeError];
            [hud hide:YES];
        }
    }];
}
@end
