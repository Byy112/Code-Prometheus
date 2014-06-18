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
#import <EAIntroView.h>

@interface CPAboutUsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation CPAboutUsViewController
-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.title = @"关于我们";
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.versionLabel.text = [NSString stringWithFormat:@"v%@",[[iVersion sharedInstance] applicationVersion]];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:{
            // 欢迎页
            EAIntroPage *page1 = [EAIntroPage pageWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"intro_01"]]];
            
            EAIntroPage *page2 = [EAIntroPage pageWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"intro_02"]]];
            
            EAIntroPage *page3 = [EAIntroPage pageWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"intro_03"]]];
            
            EAIntroPage *page4 = [EAIntroPage pageWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"intro_04"]]];
            
            EAIntroView *intro = [[EAIntroView alloc] initWithFrame:[[UIApplication sharedApplication] keyWindow].bounds andPages:@[page1,page2,page3,page4]];
            intro.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1];
            intro.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:95/255.0 green:206/255.0 blue:200/255.0 alpha:1];
            intro.pageControlY = 20;
            
            intro.skipButton = nil;
            [intro showInView:[[UIApplication sharedApplication] keyWindow] animateDuration:0.0];
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
