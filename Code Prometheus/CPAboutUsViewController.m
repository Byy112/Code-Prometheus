//
//  CPAboutUsViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-31.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPAboutUsViewController.h"
#import "CPFeedbackViewController.h"
#import <iRate.h>
#import <iVersion.h>

@interface CPAboutUsViewController ()

@end

@implementation CPAboutUsViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"关于我们";
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:{
            
            break;
        }
        case 1:{
            // 升级
            [[iVersion sharedInstance] openAppPageInAppStore];
            break;
        }
        case 2:{
            // 意见反馈
            CPFeedbackViewController* controller = [[CPFeedbackViewController alloc] initWithNibName:nil bundle:nil];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case 3:{
            // 打分
            [[iRate sharedInstance] openRatingsPageInAppStore];
            break;
        }
        default:
            break;
    }
}
@end
