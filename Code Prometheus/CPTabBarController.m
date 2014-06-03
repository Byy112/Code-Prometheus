//
//  CPTabBarController.m
//  Code Prometheus
//
//  Created by mirror on 13-11-22.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPTabBarController.h"
#import <NYXImagesKit.h>

@interface CPTabBarController ()

@end

#define CP_TAB_IMAGE_SIZE CGSizeMake(30,30)

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
                [item setFinishedSelectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_CONTACTS_H] scaleToSize:CP_TAB_IMAGE_SIZE] withFinishedUnselectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_CONTACTS] scaleToSize:CP_TAB_IMAGE_SIZE]];
                item.title = @"首页";
                break;
            case 1:
                // 日程
                [item setFinishedSelectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_SCHEDULE_H] scaleToSize:CP_TAB_IMAGE_SIZE] withFinishedUnselectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_SCHEDULE] scaleToSize:CP_TAB_IMAGE_SIZE]];
                item.title = @"日程";
                break;
            case 2:
                // 地图
                [item setFinishedSelectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_MAP_H] scaleToSize:CP_TAB_IMAGE_SIZE] withFinishedUnselectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_MAP] scaleToSize:CP_TAB_IMAGE_SIZE]];
                item.title = @"地图";
                break;
            case 3:
                // 工具
                [item setFinishedSelectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_TOOLS_H] scaleToSize:CP_TAB_IMAGE_SIZE] withFinishedUnselectedImage:[[UIImage imageNamed:CP_RESOURCE_IMAGE_TAB_TOOLS] scaleToSize:CP_TAB_IMAGE_SIZE]];
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
