//
//  CPPolicyEditViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-4.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPPolicyEditViewController.h"
#import "CPPolicy.h"
#import <HPGrowingTextView.h>
#import <FDTakeController.h>
#import "CPImage.h"
#import <MWPhotoBrowser.h>
#import <NYXImagesKit.h>
#import "TDDatePickerController.h"
#import <PopoverView.h>
#import <TWMessageBarManager.h>
#import <Masonry.h>
#import <NSDate-Utilities.h>
#import <DateTools.h>

static char CPAssociatedKeyTag;

static NSString* const CP_DATE_TITLE_NULL = @"未定义";
static NSString* const CP_REMIND_DATE_NULL = @"–– 无 ––";

// 缴费方式
static NSString* const CP_POLICY_PAY_TYPE_TITLE_MONTH = @"月缴";
static NSString* const CP_POLICY_PAY_TYPE_TITLE_QUARTER = @"季度缴";
static NSString* const CP_POLICY_PAY_TYPE_TITLE_YEAR = @"年缴";
#define CP_POLICY_PAY_TYPE_TITLE_ITEM @[CP_POLICY_PAY_TYPE_TITLE_MONTH,CP_POLICY_PAY_TYPE_TITLE_QUARTER,CP_POLICY_PAY_TYPE_TITLE_YEAR]
// 付款方式
static NSString* const CP_POLICY_PAY_WAY_TITLE_E_BANK = @"网银";
static NSString* const CP_POLICY_PAY_WAY_TITLE_CASH = @"现金";
#define CP_POLICY_PAY_WAY_TITLE_ITEM @[CP_POLICY_PAY_WAY_TITLE_E_BANK,CP_POLICY_PAY_WAY_TITLE_CASH]

@interface CPPolicyEditViewController ()<HPGrowingTextViewDelegate,FDTakeDelegate,MWPhotoBrowserDelegate,PopoverViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *beginDateButton;
@property (weak, nonatomic) IBOutlet UIButton *endDateButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *isMyPolicySwitch;
@property (weak, nonatomic) IBOutlet UIView *descriptionLayoutView;
@property (weak, nonatomic) IBOutlet UIButton *payTypeButton;
@property (weak, nonatomic) IBOutlet UITextField *payAmountTextField;
@property (weak, nonatomic) IBOutlet UIButton *payWayButton;
@property (weak, nonatomic) IBOutlet UILabel *remindDateLabel;

@property (weak, nonatomic) IBOutlet UIView *photoLayoutView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLayoutViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoLayoutViewHeight;

// 添加图片button
@property (nonatomic)UIButton* addPhotoButton;
// 内容textview
@property (nonatomic)HPGrowingTextView* growingTextView;
// 照片选择或拍摄
@property (nonatomic)FDTakeController *takeController;
// 日期格式化
@property (nonatomic)NSDateFormatter* df;
// 日期选择器
@property(nonatomic) TDDatePickerController* datePickerView;
// 弹窗
@property (nonatomic) PopoverView* popoverView;

@property (nonatomic)CPPolicy* policy;
@property (nonatomic)NSMutableArray* files;
@end

@implementation CPPolicyEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 日期格式化
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yy-MM-dd"];
    // 添加图片button
    self.addPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.addPhotoButton setBackgroundImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_POLICY_ADD_PHOTO] forState:UIControlStateNormal];
    [self.addPhotoButton addTarget:self action:@selector(addPictureButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.photoLayoutView addSubview:self.addPhotoButton];
    // 内容textview
    self.growingTextView = [[HPGrowingTextView alloc] initWithFrame:self.descriptionLayoutView.bounds];
    self.growingTextView.isScrollable = NO;
    self.growingTextView.minHeight = 37;
    self.growingTextView.maxHeight = NSIntegerMax;
	self.growingTextView.font = [UIFont systemFontOfSize:17.0f];
    self.growingTextView.textColor = [UIColor blueColor];
	self.growingTextView.delegate = self;
	self.growingTextView.animateHeightChange = NO;
    [self.descriptionLayoutView addSubview:self.growingTextView];
    // 照片
    self.takeController = [[FDTakeController alloc] init];
    self.takeController.delegate = self;
    
    [self loadPolicy];
    [self loadFiles];
    [self updateUI];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (!CP_IS_IOS7_AND_UP) {
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
    }
}
#pragma mark - private
-(void) loadPolicy{
    if (!self.policyUUID) {
        self.policy = [CPPolicy newAdaptDB];
        self.policy.cp_contact_uuid = self.contactsUUID;
        self.policy.cp_date_begin = @([[NSDate date] timeIntervalSince1970]);
        self.policy.cp_date_end = @([[NSDate date] timeIntervalSince1970] + D_YEAR);
    }else {
        self.policy = [[CPDB getLKDBHelperByUser] searchSingle:[CPPolicy class] where:@{@"cp_uuid":self.policyUUID} orderBy:nil];
    }
}
-(void) loadFiles{
    if (!self.policyUUID) {
        self.files = [NSMutableArray array];
    }else {
        self.files = [[CPDB getLKDBHelperByUser] search:[CPImage class] where:@{@"cp_r_uuid":self.policyUUID} orderBy:nil offset:0 count:-1];
    }
}
-(void) updateUI{
    // 日期
    if (self.policy.cp_date_begin) {
        [self.beginDateButton setTitle:[self.df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_begin.doubleValue]] forState:UIControlStateNormal];
    }else{
        [self.beginDateButton setTitle:CP_DATE_TITLE_NULL forState:UIControlStateNormal];
    }
    if (self.policy.cp_date_end) {
        [self.endDateButton setTitle:[self.df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_end.doubleValue]] forState:UIControlStateNormal];
    }else{
        [self.endDateButton setTitle:CP_DATE_TITLE_NULL forState:UIControlStateNormal];
    }
    // 名称
    if (self.policy.cp_name) {
        self.nameTextField.text = self.policy.cp_name;
    }
    // 我的保单
    if (self.policy.cp_my_policy && self.policy.cp_my_policy.integerValue==0) {
        self.isMyPolicySwitch.on = NO;
    }else{
        self.isMyPolicySwitch.on = YES;
    }
    // 详情
    if (self.policy.cp_description) {
        self.growingTextView.text = self.policy.cp_description;
    }
    // 缴费方式
    if (self.policy.cp_pay_type) {
        [self.payTypeButton setTitle:CP_POLICY_PAY_TYPE_TITLE_ITEM[self.policy.cp_pay_type.integerValue] forState:UIControlStateNormal];
    }
    // 缴费金额
    if (self.policy.cp_pay_amount) {
        self.payAmountTextField.text = [NSString stringWithFormat:@"%@",self.policy.cp_pay_amount];
    }
    // 付款方式
    if (self.policy.cp_pay_way) {
        [self.payWayButton setTitle:CP_POLICY_PAY_WAY_TITLE_ITEM[self.policy.cp_pay_way.integerValue] forState:UIControlStateNormal];
    }
    // 缴费提醒
    [self updateRemindDateUI];
    // 照片
    [self updatePhotoViews];
}

-(void)updateRemindDateUI{
    if (self.policy.cp_date_begin && self.policy.cp_pay_type) {
        NSDate* beginDate = [[NSDate alloc] initWithTimeIntervalSince1970:self.policy.cp_date_begin.doubleValue];
        NSDate* endDate = [[NSDate alloc] initWithTimeIntervalSince1970:self.policy.cp_date_end.doubleValue];
        NSDate* now = [NSDate date];

        if ([now isEqualToDateIgnoringTime:beginDate] || [now isEarlierThan:beginDate] || [now isEqualToDateIgnoringTime:endDate] || [now isLaterThan:endDate]) {
            self.remindDateLabel.text = CP_REMIND_DATE_NULL;
            return;
        }
        
        NSDate* remindDate = nil;
        NSInteger n = 1;
        while (YES) {
            switch (self.policy.cp_pay_type.integerValue) {
                case 0:
                    remindDate = [beginDate dateByAddingMonths:n];
                    break;
                case 1:
                    remindDate = [beginDate dateByAddingMonths:3*n];
                    break;
                case 2:
                    remindDate = [beginDate dateByAddingYears:n];
                    break;
                default:
                    break;
            }
            if ([remindDate isEqualToDateIgnoringTime:endDate] || [remindDate isLaterThan:endDate]) {
                self.remindDateLabel.text = CP_REMIND_DATE_NULL;
                break;
            }
            if ([remindDate isEqualToDateIgnoringTime:now] || [remindDate isLaterThan:now]) {
                self.remindDateLabel.text = [self.df stringFromDate:remindDate];
                break;
            }
            n++;
        }
    }else{
        self.remindDateLabel.text = CP_REMIND_DATE_NULL;
    }
}
-(void)updatePhotoViews{
    // 删除uiimageview
    for(UIView *subv in [self.photoLayoutView subviews])
    {
        if (subv != self.addPhotoButton) {
            [subv removeFromSuperview];
        }
    }
    if (self.files && self.files.count>0) {
        for (CPImage* image in self.files) {
            // Button
            UIButton* buttonImage = [[UIButton alloc] initWithFrame:CGRectZero];
            [buttonImage setImageWithCPImage:image];
            [buttonImage.imageView setContentMode:UIViewContentModeScaleAspectFit];
            buttonImage.tag = [self.files indexOfObject:image];
            // 长按手势
            UILongPressGestureRecognizer *btnLongTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(photoButtonLongClick:)];
            btnLongTap.minimumPressDuration = 0.5;
            [buttonImage addGestureRecognizer:btnLongTap];
            
            // 单击
            [buttonImage addTarget:self action:@selector(photoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.photoLayoutView addSubview:buttonImage];
        }
    }
    // 布局
    [self layoutPhotoViews];
}
// 布局计算
static const CGFloat kFramePadding = 10;
static const CGFloat kImageSpacing = 5;
- (void)layoutPhotoViews{
    CGFloat width = (self.photoLayoutView.frame.size.width-kFramePadding*2-kImageSpacing*2)/3;
    CGFloat height = width;
    int i=0;
    // 添加的图片
    for (UIView* view in self.photoLayoutView.subviews) {
        if (view == self.addPhotoButton) {
            continue;
        }
        view.frame = CGRectMake(kFramePadding+(i%3)*(width+kImageSpacing), kFramePadding+(i/3)*(height+kImageSpacing), width, height);
        i++;
    }
    // addButton
    self.addPhotoButton.frame = CGRectMake(kFramePadding+(i%3)*(width+kImageSpacing), kFramePadding+(i/3)*(height+kImageSpacing), width, height);
    // layoutview高度
    [self.photoLayoutView removeConstraint:self.photoLayoutViewHeight];
    self.photoLayoutViewHeight = [NSLayoutConstraint constraintWithItem:self.photoLayoutView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.photoLayoutView.superview attribute:NSLayoutAttributeHeight multiplier:0 constant:2*kFramePadding+(i/3)*(height+kImageSpacing)+height];
    [self.photoLayoutView addConstraint:self.photoLayoutViewHeight];
    [self.view setNeedsLayout];
}
#pragma mark - IBAction
- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:self.policyUUID?NO:YES];
}
- (IBAction)save:(id)sender {
    [self.view endEditing:YES];
    if (!self.policy.cp_name || [self.policy.cp_name isEqualToString:@""]) {
        [[TWMessageBarManager sharedInstance] hideAll];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:@"请填写名称"
                                                              type:TWMessageBarMessageTypeInfo];
        return;
    }
    self.policy.cp_timestamp = @([CPServer getServerTimeByDelta_t]);
    if (!self.policyUUID) {
        // 新增
        // 图片
        for (CPImage* image in self.files) {
            [[CPDB getLKDBHelperByUser] insertToDB:image];
        }
        // 保单
        [[CPDB getLKDBHelperByUser] insertToDB:self.policy];
        // 返回
        [self.navigationController popViewControllerAnimated:YES];
    } else{
        // 修改
        // 图片
        NSMutableArray* fileInDB = [[CPDB getLKDBHelperByUser] search:[CPImage class] where:@{@"cp_r_uuid":self.policyUUID} orderBy:nil offset:0 count:-1];
        // 添加图片
        for (CPImage* image in self.files) {
            if ([fileInDB containsObject:image]) {
                continue;
            }
            [[CPDB getLKDBHelperByUser] insertToDB:image];
        }
        // 删除图片
        for (CPImage* image in fileInDB) {
            if ([self.files containsObject:image]) {
                continue;
            }
            [[CPDB getLKDBHelperByUser] deleteToDB:image];
        }
        // 保单
        [[CPDB getLKDBHelperByUser] updateToDB:self.policy where:nil];
        // 返回
        [self.navigationController popViewControllerAnimated:NO];
    }
    // 同步
    [CPServer sync];
}
- (IBAction)beginDateButtonClick:(id)sender {
    [self.view endEditing:YES];
    self.datePickerView = [[TDDatePickerController alloc]initWithNibName:CP_RESOURCE_XIB_DATE_PICKER_DATE bundle:nil];
    self.datePickerView.delegate = self;
    if (self.policy.cp_date_begin) {
        self.datePickerView.date = [NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_begin.doubleValue];
    }
    objc_setAssociatedObject(self.datePickerView, &CPAssociatedKeyTag, @(0), OBJC_ASSOCIATION_RETAIN);
    [self presentSemiModalViewController:self.datePickerView];
}
- (IBAction)endDateButtonClick:(id)sender {
    [self.view endEditing:YES];
    self.datePickerView = [[TDDatePickerController alloc]initWithNibName:CP_RESOURCE_XIB_DATE_PICKER_DATE bundle:nil];
    self.datePickerView.delegate = self;
    if (self.policy.cp_date_end) {
        self.datePickerView.date = [NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_end.doubleValue];
    }
    objc_setAssociatedObject(self.datePickerView, &CPAssociatedKeyTag, @(1), OBJC_ASSOCIATION_RETAIN);
    [self presentSemiModalViewController:self.datePickerView];
}
- (IBAction)nameTextFieldValueChange:(UITextField*)sender {
    self.policy.cp_name = sender.text;
}
- (IBAction)isMyPolicySwitchValueChange:(UISwitch*)sender {
    self.policy.cp_my_policy = @(sender.on);
}

- (IBAction)payTypeButtonClick:(id)sender {
    UIButton* button = sender;
    self.popoverView = [PopoverView showPopoverAtPoint:button.titleLabel.center inView:button.titleLabel withStringArray:CP_POLICY_PAY_TYPE_TITLE_ITEM delegate:self];
    self.popoverView.tag = 0;
}
- (IBAction)payAmountTextFieldValueChange:(UITextField*)sender {
    self.policy.cp_pay_amount = @(sender.text.integerValue);
}
- (IBAction)payWayButtonClick:(id)sender {
    UIButton* button = sender;
    self.popoverView = [PopoverView showPopoverAtPoint:button.titleLabel.center inView:button.titleLabel withStringArray:CP_POLICY_PAY_WAY_TITLE_ITEM delegate:self];
    self.popoverView.tag = 1;
}
#pragma mark - Action
#define CP_MAX_PICTURE 9
- (void)addPictureButtonClick:(id)sender {
    if (self.files.count>=CP_MAX_PICTURE) {
        [[TWMessageBarManager sharedInstance] hideAll];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:[NSString stringWithFormat:@"最多包含%d张图片",CP_MAX_PICTURE]
                                                              type:TWMessageBarMessageTypeInfo];
        return;
    }
    [self.takeController takePhotoOrChooseFromLibrary];
}
-(void)photoButtonClick:(id)sender{
    UIButton* button = sender;
    // 单击查看
	MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;
    browser.displayNavArrows = NO;
    browser.wantsFullScreenLayout = YES;
    browser.zoomPhotosToFill = YES;
    [browser setCurrentPhotoIndex:button.tag];
    // Show
    [self.navigationController pushViewController:browser animated:YES];
}
-(void)photoButtonLongClick:(id)sender{
    // 长按删除
    UILongPressGestureRecognizer* lp = sender;
    if(UIGestureRecognizerStateBegan != lp.state) {
        return;
    }
    UIButton* button = (UIButton*)[lp view];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"确认删除" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    alert.tag = [self.photoLayoutView.subviews indexOfObject:button];
    [alert show];
}
#pragma mark - HPGrowingTextViewDelegate
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    // layoutview高度
    float diff = (growingTextView.frame.size.height - height);
    float priorHeight = self.descriptionLayoutView.frame.size.height;
    priorHeight -= diff;
    
    [self.descriptionLayoutView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(priorHeight));
    }];
    [self.view layoutIfNeeded];
}
- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView{
    self.policy.cp_description = growingTextView.internalTextView.text;
}
#pragma mark - Date Picker Delegate
-(void)datePickerSetDate:(TDDatePickerController*)viewController {
	[self dismissSemiModalViewController:viewController];
    NSDate* date = viewController.datePicker.date;
    NSNumber* tag = objc_getAssociatedObject(viewController, &CPAssociatedKeyTag);
    switch (tag.integerValue) {
        case 0:{
            self.policy.cp_date_begin = @([date timeIntervalSince1970]);
            [self.beginDateButton setTitle:[self.df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_begin.doubleValue]] forState:UIControlStateNormal];
            break;
        }
        case 1:{
            self.policy.cp_date_end = @([date timeIntervalSince1970]);
            [self.endDateButton setTitle:[self.df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_end.doubleValue]] forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
    [self updateRemindDateUI];
}

-(void)datePickerClearDate:(TDDatePickerController*)viewController {
	[self dismissSemiModalViewController:viewController];
    NSNumber* tag = objc_getAssociatedObject(viewController, &CPAssociatedKeyTag);
    switch (tag.integerValue) {
        case 0:{
            self.policy.cp_date_begin = @([[NSDate date] timeIntervalSince1970]);
            [self.beginDateButton setTitle:[self.df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_begin.doubleValue]] forState:UIControlStateNormal];
            break;
        }
        case 1:{
            self.policy.cp_date_end = @([[NSDate date] timeIntervalSince1970] + D_YEAR);
            [self.endDateButton setTitle:[self.df stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.policy.cp_date_end.doubleValue]] forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
    [self updateRemindDateUI];
}

-(void)datePickerCancel:(TDDatePickerController*)viewController {
	[self dismissSemiModalViewController:viewController];
}
#pragma mark - PopoverViewDelegate
- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index{
    switch (popoverView.tag) {
        case 0:{
            self.policy.cp_pay_type = @(index);
            [self.payTypeButton setTitle:CP_POLICY_PAY_TYPE_TITLE_ITEM[index] forState:UIControlStateNormal];
            [self updateRemindDateUI];
            break;
        }
        case 1:{
            self.policy.cp_pay_way = @(index);
            [self.payWayButton setTitle:CP_POLICY_PAY_WAY_TITLE_ITEM[index] forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
    [self.popoverView dismiss];
    self.popoverView = nil;
}
#pragma mark - FDTakeDelegate
- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info{
    // 缩放
    photo = [photo scaleToFitSize:CP_UI_PHOTO_SIZE_BROWSE];
    // 旋转
    photo = [photo fixOrientation];
    CPImage* image = [CPImage newAdaptDB];
    image.cp_r_uuid = self.policy.cp_uuid;
    image.image = photo;
    [self.files addObject:image];
    // UI
    [self updatePhotoViews];
}
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        UIButton* button = [self.photoLayoutView.subviews objectAtIndex:alertView.tag];
        // file
        [self.files removeObjectAtIndex:button.tag];
        // 布局
        [self updatePhotoViews];
    }
}
#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    return self.files.count;
}
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index{
    CPImage* cpImage = [self.files objectAtIndex:index];
    UIImage* image = cpImage.image;
    if (image) {
        return [MWPhoto photoWithImage:[image scaleToFitSize:CP_UI_PHOTO_SIZE_BROWSE]];
    }
    if (cpImage.cp_url) {
        CPLogWarn(@"MWPhotoBrowser 警告：本地找不到图片(uuid=%@)。现从网上下载(url=%@)",cpImage.cp_uuid,cpImage.cp_url);
        return [MWPhoto photoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",URL_SERVER_ROOT,cpImage.cp_url]]];
    }
    CPLogError(@"找不到图片! uuid:%@",cpImage.cp_uuid);
    return [MWPhoto photoWithImage:[UIImage imageNamed:@"cp_null_photo"]];
}
@end
