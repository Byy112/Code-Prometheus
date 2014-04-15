//
//  CPResetPasswordViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-24.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPResetPasswordViewController.h"
#import <TWMessageBarManager.h>
#import <MBProgressHUD.h>

@interface CPResetPasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *originalPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmTextField;
@end

@implementation CPResetPasswordViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"修改密码";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(back:)];
}
- (void)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)confirm:(id)sender {
    // 取消现有提示
    [[TWMessageBarManager sharedInstance] hideAll];
    // 确认密码
    if (![self.passwordTextField.text isEqualToString:self.passwordConfirmTextField.text]) {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:@"两次输入的密码不同,请确认"
                                                              type:TWMessageBarMessageTypeError];
        return;
    }
    // 启动进度条
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.removeFromSuperViewOnHide = YES;
	[self.view addSubview:hud];
    [hud show:YES];
    
    [CPServer resetPasswordWithOriginalPassword:self.originalPasswordTextField.text newPassword:self.passwordTextField.text block:^(BOOL success, NSString *newPassword, NSString *message) {
        if (success) {
            // 修改密码
            CPSetPassword(newPassword);
            // 提示
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"OK" description:@"修改成功" type:TWMessageBarMessageTypeSuccess];
            [hud hide:YES];
            
            // 返回上一级目录
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            // 提示
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:message
                                                                  type:TWMessageBarMessageTypeError];
            [hud hide:YES];
        }
    }];
}
@end
