//
//  CPAccountRechargeViewController.h
//  Code Prometheus
//
//  Created by mirror on 13-12-27.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPAccountRechargeViewController : UITableViewController
@property (nonatomic) BOOL needDisplayMessage;
@property (nonatomic) BOOL paySuccess;
@property (nonatomic) NSString* payMessage;
@end
