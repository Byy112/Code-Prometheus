//
//  CPNavigationController.m
//  Code Prometheus
//
//  Created by mirror on 13-11-21.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPNavigationController.h"
#import <NYXImagesKit.h>

#define CP_NAV_IMAGE_SIZE CGSizeMake(24,24)

@interface CPNavigationController ()<UINavigationControllerDelegate>

@end

@implementation CPNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.titleTextAttributes = @{UITextAttributeFont:CP_Navigation_Title_Font,UITextAttributeTextColor:CP_Navigation_Title_Color};
    
    self.navigationBar.translucent = NO;
    
	if(CP_IS_IOS7_AND_UP)
    {
        [UINavigationBar appearance].tintColor = [UIColor whiteColor];
        [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:0.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
        
        [UINavigationBar appearance].backIndicatorImage = [UIImage imageNamed:@"cp_back_normal"];
        [UINavigationBar appearance].backIndicatorTransitionMaskImage = [UIImage imageNamed:@"cp_back_normal"];
        
//        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"cp_back_normal"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
    else
    {
        self.navigationBar.tintColor = [UIColor colorWithRed:0.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
    }
    
    self.delegate = self;
    
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (viewController.navigationItem.backBarButtonItem.tag == 10000) {
        return;
    }
    
    if (CP_IS_IOS7_AND_UP) {
        viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }else{
        viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cp_back_normal"] style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    
    viewController.navigationItem.backBarButtonItem.tag = 10000;

    if (viewController.navigationItem.leftBarButtonItem) {
        [self changeStyleWithLeft:YES navig:viewController.navigationItem];
    }
    
    if (viewController.navigationItem.rightBarButtonItem) {
        [self changeStyleWithLeft:NO navig:viewController.navigationItem];
    }
}

-(void) changeStyleWithLeft:(BOOL)left navig:(UINavigationItem*) navig{
    UIBarButtonItem* old = left ? navig.leftBarButtonItem : navig.rightBarButtonItem;
    
    NSNumber *value = [old valueForKey:@"systemItem"];
    UIBarButtonSystemItem style = [value integerValue];
    
    UIBarButtonItem* new = nil;
    switch (style) {
        case UIBarButtonSystemItemAdd:
            new = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"cp_add_normal"] scaleToSize:CP_NAV_IMAGE_SIZE] style:UIBarButtonItemStylePlain target:old.target action:old.action];
            break;
        case UIBarButtonSystemItemEdit:
            new = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"cp_edit_normal"] scaleToSize:CP_NAV_IMAGE_SIZE] style:UIBarButtonItemStylePlain target:old.target action:old.action];
            break;
        case UIBarButtonSystemItemSave:
            new = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"cp_save_normal"] scaleToSize:CP_NAV_IMAGE_SIZE] style:UIBarButtonItemStylePlain target:old.target action:old.action];
            break;
        case UIBarButtonSystemItemCancel:
            new = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"cp_cancel_normal"] scaleToSize:CP_NAV_IMAGE_SIZE] style:UIBarButtonItemStylePlain target:old.target action:old.action];
            break;
        default:
            break;
    }
    if (new) {
        if (left) {
            navig.leftBarButtonItem = new;
        }else{
            navig.rightBarButtonItem = new;
        }
    }
}
@end
