//
//  CPFeedbackViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-31.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPFeedbackViewController.h"
#import <HPTextViewInternal.h>
#import <TWMessageBarManager.h>
#import <MBProgressHUD.h>

@interface CPFeedbackViewController ()<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet HPTextViewInternal *myTextView;

@end

@implementation CPFeedbackViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"意见反馈";
    // 内容textview
    self.myTextView.displayPlaceHolder = YES;
    [self.myTextView setPlaceholderColor:[UIColor lightGrayColor]];
    self.myTextView.placeholder = @"请在此输入您对保险助手的建议,限制1000个字";
    self.myTextView.layer.borderWidth = 1;
    self.myTextView.layer.borderColor = [UIColor grayColor].CGColor;
    self.myTextView.layer.cornerRadius = 8;
    self.myTextView.delegate = self;
}
- (IBAction)submit:(id)sender {
    
    [[TWMessageBarManager sharedInstance] hideAll];
    if (!self.myTextView.text || [self.myTextView.text isEqualToString:@""]) {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:@"请输入您的宝贵意见!"
                                                              type:TWMessageBarMessageTypeError];
        return;
    }
    // 启动进度条
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.removeFromSuperViewOnHide = YES;
	[self.view addSubview:hud];
    [hud show:YES];
    [CPServer feedBackByContact:self.myTextView.text feedback:@"" block:^(BOOL success, NSString *message) {
        if (success) {
            [self.navigationController popViewControllerAnimated:YES];
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"OK" description:@"感谢您的反馈" type:TWMessageBarMessageTypeSuccess];
        }else{
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:message
                                                                  type:TWMessageBarMessageTypeError];
            [hud hide:YES];
        }
    }];
}
#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView{
    HPTextViewInternal* myTextView = (HPTextViewInternal*)textView;
    BOOL display = myTextView.displayPlaceHolder;
    if (textView.text==nil || [textView.text isEqualToString:@""]) {
        myTextView.displayPlaceHolder = YES;
    }else{
        myTextView.displayPlaceHolder = NO;
    }
    if (display != myTextView.displayPlaceHolder) {
        [myTextView setNeedsDisplay];
    }
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    return [[textView text] length] - range.length + text.length <= 1000;
}
@end
