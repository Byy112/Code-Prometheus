//
//  CPRechargeViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-30.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPRechargeViewController.h"
#import <MBProgressHUD.h>
#import <TWMessageBarManager.h>
#import <Masonry.h>
#import "AlixLibService.h"
#import "AlixPayResult.h"
#import "CPAppDelegate.h"

static char CPAssociatedKeyRechargeItem;

@interface CPRechargeItem : NSObject
@property(nonatomic) NSString* itemId;
@property(nonatomic) NSString* title;
@property(nonatomic) NSNumber* price;
@property(nonatomic) NSNumber* amount;
@end
@implementation CPRechargeItem
@end


@interface CPRechargeViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *rechargeItemLayoutView;

@property (nonatomic) NSArray* rechargeItemArray;
// 脏数据,是否需要刷新
@property (nonatomic) BOOL dirty;
@property (nonatomic) NSString* selectRechargeItemId;

@property (nonatomic) BOOL needDisplayMessage;
@property (nonatomic) BOOL paySuccess;
@property (nonatomic) NSString* payMessage;
@end

@implementation CPRechargeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dirty = YES;
    self.navigationItem.title = @"充值";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:CP_HANDLE_OPEN_URL_Notification object:nil];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.dirty) {
        [self requestRechargeItem];
        self.dirty = NO;
    }
    // 解决 支付宝 内付 bug： 显示了隐藏的tabbar
    self.tabBarController.tabBar.hidden = YES;
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.needDisplayMessage) {
        if (self.paySuccess) {
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"YES"
                                                           description:self.payMessage
                                                                  type:TWMessageBarMessageTypeSuccess];
        }else{
            //失败
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:self.payMessage
                                                                  type:TWMessageBarMessageTypeError];
        }
        self.needDisplayMessage = NO;
    }
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (!CP_IS_IOS7_AND_UP) {
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
    }
}
- (void)updateUI{
    UIView* lastRootView = nil;
    for (CPRechargeItem* rechargeItem in self.rechargeItemArray) {
        // 根view
        UIView* rootView = [UIView new];
        [self.rechargeItemLayoutView addSubview:rootView];
        if (lastRootView) {
            [rootView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(lastRootView.mas_bottom);
                make.left.equalTo(@0);
                make.right.equalTo(@0);
                make.height.equalTo(@44);
            }];
        }else{
            [rootView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(@0);
                make.left.equalTo(@0);
                make.right.equalTo(@0);
                make.height.equalTo(@44);
            }];
        }
        lastRootView = rootView;
        // 单选按钮
        UIControl* myButton = [[UIControl alloc] init];
        objc_setAssociatedObject(myButton, &CPAssociatedKeyRechargeItem, rechargeItem, OBJC_ASSOCIATION_ASSIGN);
        [myButton addTarget:self action:@selector(changeRechargeItem:) forControlEvents:UIControlEventTouchUpInside];
        [rootView addSubview:myButton];
        [myButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@0);
            make.left.equalTo(@0);
            make.right.equalTo(@0);
            make.bottom.equalTo(@0);
        }];
        // 图片
        UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_RADIO_NO] highlightedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_RADIO_YES]];
        [myButton addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@20);
            make.centerY.equalTo(myButton.mas_centerY);
        }];
        // 需要豆数
        UILabel* amountLabel = [[UILabel alloc] init];
        amountLabel.font = [amountLabel.font fontWithSize:14];
        [myButton addSubview:amountLabel];
        amountLabel.text = [NSString stringWithFormat:@"%@豆",rechargeItem.amount];
        [amountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(imageView.mas_right);
            make.centerY.equalTo(myButton.mas_centerY);
        }];
        // 充值项描述
        UILabel* titleLabel = [[UILabel alloc] init];
        titleLabel.font = [titleLabel.font fontWithSize:14];
        [myButton addSubview:titleLabel];
        titleLabel.text = rechargeItem.title;
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(myButton.mas_centerX);
            make.centerY.equalTo(myButton.mas_centerY);
        }];
        // 价格
        UILabel* priceLabel = [[UILabel alloc] init];
        priceLabel.font = [priceLabel.font fontWithSize:14];
        [myButton addSubview:priceLabel];
        priceLabel.text = [NSString stringWithFormat:@"%d¥",[rechargeItem.price integerValue]/100];
        [priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@(-20));
            make.centerY.equalTo(myButton.mas_centerY);
        }];
    }
    if (lastRootView) {
        [lastRootView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@0);
        }];
    }
    [self updateMyButton];
}
-(void) updateMyButton{
    for (UIView* rootView in [self.rechargeItemLayoutView subviews]) {
        UIControl* myButton = rootView.subviews.lastObject;
        CPRechargeItem* item = objc_getAssociatedObject(myButton, &CPAssociatedKeyRechargeItem);
        if ([self.selectRechargeItemId isEqualToString:item.itemId]) {
            for (UIView* subView in myButton.subviews) {
                if ([subView isKindOfClass:[UIImageView class]]) {
                    UIImageView* imageView = (UIImageView*)subView;
                    imageView.highlighted = YES;
                }
                if ([subView isKindOfClass:[UILabel class]]) {
                    UILabel* label = (UILabel*)subView;
                    label.textColor = [UIColor blackColor];
                }
            }
        }else{
            for (UIView* subView in myButton.subviews) {
                if ([subView isKindOfClass:[UIImageView class]]) {
                    UIImageView* imageView = (UIImageView*)subView;
                    imageView.highlighted = NO;
                }
                if ([subView isKindOfClass:[UILabel class]]) {
                    UILabel* label = (UILabel*)subView;
                    label.textColor = [UIColor grayColor];
                }
            }
        }
    }
}
-(void) requestRechargeItem{
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.removeFromSuperViewOnHide = YES;
	[self.view addSubview:hud];
    [hud show:YES];
    [CPServer requestRechargeItem:^(BOOL success, NSString *message, NSMutableArray *results) {
        if (success) {
            NSMutableArray* rechargeItems = [NSMutableArray array];
            for (NSDictionary* dic in results) {
                CPRechargeItem* rechargeItem = [CPRechargeItem new];
                rechargeItem.itemId = [dic objectForKey:@"itemId"];
                rechargeItem.title = [dic objectForKey:@"title"];
                rechargeItem.price = [dic objectForKey:@"price"];
                rechargeItem.amount = [dic objectForKey:@"amount"];
                [rechargeItems addObject:rechargeItem];
            }
            self.rechargeItemArray = [NSArray arrayWithArray:rechargeItems];
            [self updateUI];
        }else{
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:message
                                                                  type:TWMessageBarMessageTypeError];
        }
        [hud hide:YES];
    }];
}
- (void)changeRechargeItem:(id)sender {
    CPRechargeItem* rechargeItem = objc_getAssociatedObject(sender, &CPAssociatedKeyRechargeItem);
    self.selectRechargeItemId = rechargeItem.itemId;
    [self updateMyButton];
}
- (IBAction)recharge:(id)sender {
    [[TWMessageBarManager sharedInstance] hideAll];
    if (!self.selectRechargeItemId) {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:@"请选择充值类型"
                                                              type:TWMessageBarMessageTypeError];
        return;
    }
    MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.view];
    hud.removeFromSuperViewOnHide = YES;
	[self.view addSubview:hud];
    [hud show:YES];
    [CPServer requestRechargeCreateWithItemID:self.selectRechargeItemId block:^(BOOL success, NSString *message, NSNumber *rechargeId, NSString *signInfo, NSString *sign) {
        if (success) {
            NSString *appScheme = @"com.mirror.Code-Prometheus";
            NSString* orderInfo = signInfo;
            NSString* signedStr = sign;
            NSString *orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                                     orderInfo, signedStr, @"RSA"];
            CPLogInfo(@"请求支付宝 orderString:%@",orderString);
            [AlixLibService payOrder:orderString AndScheme:appScheme seletor:@selector(paymentResult:) target:self];
        }else{
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:message
                                                                  type:TWMessageBarMessageTypeError];
        }
        [hud hide:YES];
    }];
}

#pragma mark - 支付宝 外付 回调

- (void) receiveNotification:(NSNotification*) notification{
    CPLogInfo(@"解析 Open URL");
    NSURL* url = notification.object;
    AlixPayResult* result = [self handleOpenURL:url];
    CPLogWarn(@"支付宝外付回调结果:%@ statusCode:%d",result.statusMessage,result.statusCode);
    [self doWithPayResult:result];
}

- (AlixPayResult *)handleOpenURL:(NSURL *)url {
	AlixPayResult * result = nil;
	
	if (url != nil && [[url host] compare:@"safepay"] == 0) {
		result = [self resultFromURL:url];
	}
    
	return result;
}
- (AlixPayResult *)resultFromURL:(NSURL *)url {
	NSString * query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#if ! __has_feature(objc_arc)
    return [[[AlixPayResult alloc] initWithString:query] autorelease];
#else
	return [[AlixPayResult alloc] initWithString:query];
#endif
}

-(void)doWithPayResult:(AlixPayResult *)result{
    if (result && result.statusCode == 9000) {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"YES"
                                                       description:result.statusMessage
                                                              type:TWMessageBarMessageTypeSuccess];
        // 检查License
        [CPServer checkLicenseBlock:^(BOOL success, NSString *message,NSTimeInterval expirationDate) {
            if (success) {
                if (!CPMemberLicense || CPMemberLicense != expirationDate) {
                    CPLogInfo(@"更新 license :%@->%@",[NSDate dateWithTimeIntervalSince1970:CPMemberLicense],[NSDate dateWithTimeIntervalSince1970:expirationDate]);
                    CPSetMemberLicense(expirationDate);
                }else{
                    CPLogVerbose(@"不用更新 license %@",[NSDate dateWithTimeIntervalSince1970:CPMemberLicense]);
                }
            }else{
                CPLogWarn(@"check lisence 失败:%@",message);
            }
        }];
        [self.navigationController popViewControllerAnimated:NO];
    }else{
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:result?result.statusMessage:@"交易失败"
                                                              type:TWMessageBarMessageTypeError];
    }
}

#pragma mark - 支付宝 内付 回调
-(void)paymentResult:(NSString *)resultd
{
    //结果处理
    AlixPayResult* result = [[AlixPayResult alloc] initWithString:resultd];
    CPLogWarn(@"支付宝内付回调结果:%@ statusCode:%d",result.statusMessage,result.statusCode);
	if (result && result.statusCode == 9000) {
        // 检查License
        [CPServer checkLicenseBlock:^(BOOL success, NSString *message,NSTimeInterval expirationDate) {
            if (success) {
                if (!CPMemberLicense || CPMemberLicense != expirationDate) {
                    CPLogInfo(@"更新 license :%@->%@",[NSDate dateWithTimeIntervalSince1970:CPMemberLicense],[NSDate dateWithTimeIntervalSince1970:expirationDate]);
                    CPSetMemberLicense(expirationDate);
                }else{
                    CPLogVerbose(@"不用更新 license %@",[NSDate dateWithTimeIntervalSince1970:CPMemberLicense]);
                }
            }else{
                CPLogWarn(@"check lisence 失败:%@",message);
            }
        }];
        if (self.cpAccountRechargeViewController) {
            self.cpAccountRechargeViewController.needDisplayMessage = YES;
            self.cpAccountRechargeViewController.paySuccess = YES;
            self.cpAccountRechargeViewController.payMessage = result.statusMessage;
        }
        [self.navigationController popViewControllerAnimated:NO];
    }else{
        self.needDisplayMessage = YES;
        self.paySuccess = NO;
        self.payMessage = result?result.statusMessage:@"交易失败";
    }
}
@end
