//
//  CPTabBarController.m
//  Code Prometheus
//
//  Created by mirror on 13-11-22.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPTabBarController.h"

@interface CPTabBarController ()

@end

@implementation CPTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tabBar.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UITabBarItem* item = obj;
        [item setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], UITextAttributeTextColor, nil] forState:UIControlStateSelected];
//        item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
        switch (idx) {
            case 0:
                // 人脉
                [item setFinishedSelectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_CONTACTS_H] withFinishedUnselectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_CONTACTS]];
                item.title = @"首页";
                break;
            case 1:
                // 日程
                [item setFinishedSelectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_SCHEDULE_H] withFinishedUnselectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_SCHEDULE]];
                item.title = @"日程";
                break;
            case 2:
                // 地图
                [item setFinishedSelectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_MAP_H] withFinishedUnselectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_MAP]];
                item.title = @"地图";
                break;
            case 3:
                // 工具
                [item setFinishedSelectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_TOOLS_H] withFinishedUnselectedImage:[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_TOOLS]];
                item.title = @"更多";
                break;
            default:
                break;
        }
    }];
    if (CP_IS_IOS7_AND_UP) {
        
    }else{
        [self.tabBar setTintColor:[UIColor whiteColor]];
    }
}

@end
