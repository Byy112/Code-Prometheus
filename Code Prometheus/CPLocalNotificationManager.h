//
//  CPLocalNotificationManager.h
//  Code Prometheus
//
//  Created by 管理员 on 14-5-21.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPLocalNotificationManager : NSObject
+ (instancetype) shared;
-(void) fire;
-(void) down;
@end
