//
//  CPMettingEditViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-10.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPMettingEditViewController.h"

@interface CPMettingEditViewController ()<HPGrowingTextViewDelegate>

@end

@implementation CPMettingEditViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 内容textview
    self.growingTextView = [[HPGrowingTextView alloc] initWithFrame:self.meetingContentLayoutView.bounds];
    self.growingTextView.isScrollable = NO;
    self.growingTextView.minHeight = 37;
    self.growingTextView.maxHeight = NSIntegerMax;
	self.growingTextView.font = [UIFont systemFontOfSize:16];
    self.growingTextView.textColor = [UIColor blackColor];
	self.growingTextView.delegate = self;
	self.growingTextView.animateHeightChange = NO;
    [self.meetingContentLayoutView addSubview:self.growingTextView];
}
#pragma mark - HPGrowingTextViewDelegate
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    // layoutview高度
    float diff = (growingTextView.frame.size.height - height);
    float priorHeight = self.meetingContentLayoutView.frame.size.height;
    priorHeight -= diff;
    [self.meetingContentLayoutView removeConstraint:self.meetingContentLayoutViewHeight];
    self.meetingContentLayoutViewHeight = [NSLayoutConstraint constraintWithItem:self.meetingContentLayoutView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.meetingContentLayoutView.superview attribute:NSLayoutAttributeHeight multiplier:0 constant:priorHeight];
    [self.meetingContentLayoutView addConstraint:self.meetingContentLayoutViewHeight];
    [self.view layoutIfNeeded];
    CGRect frame = self.view.frame;
    frame.size.height -= diff;
    self.view.frame = frame;
    if (self.delegate && [self.delegate respondsToSelector:@selector(meetingContentTextViewWillChangeHeight:withDiff:)]) {
        [self.delegate meetingContentTextViewWillChangeHeight:self withDiff:diff];
    }
}
-(void) growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView{
    if (self.delegate && [self.delegate respondsToSelector:@selector(meetingContentTextViewDidEndEditing:withText:)]) {
        [self.delegate meetingContentTextViewDidEndEditing:self withText:growingTextView.text];
    }
}
@end
