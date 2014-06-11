//
//  CPSeparatorView.m
//  Code Prometheus
//
//  Created by 管理员 on 14-6-11.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPSeparatorView.h"

@implementation CPSeparatorView

-(id)init{
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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

-(void)setUp{
    self.backgroundColor = [UIColor colorWithRed:200.0/255 green:199.0/255 blue:204.0/255 alpha:1];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if([self.constraints count] == 0) {
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        if(width == 1) {
            width = width / [UIScreen mainScreen].scale;
        }
        if (height == 0) {
            height = 1 / [UIScreen mainScreen].scale;
        }
        
        if(height == 1) {
            height = height / [UIScreen mainScreen].scale;
        }
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, height);
    }
    else {
        for(NSLayoutConstraint *constraint in self.constraints) {
            if((constraint.firstAttribute == NSLayoutAttributeWidth || constraint.firstAttribute == NSLayoutAttributeHeight) && constraint.constant == 1) {
                constraint.constant /=[UIScreen mainScreen].scale;
            }
        }
    }
}

@end
