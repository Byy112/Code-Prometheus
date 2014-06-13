//
//  CPContactsKeyTextLabel.m
//  Code Prometheus
//
//  Created by 管理员 on 14-6-13.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPContactsKeyTextLabel.h"

#define CP_KEY_COLOR [UIColor colorWithRed:100.0/255 green:100.0/255 blue:100.0/255 alpha:1]

@implementation CPContactsKeyTextLabel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

-(void)setUp{
    self.textColor = CP_KEY_COLOR;
    self.font = [UIFont systemFontOfSize:16];
}

@end
