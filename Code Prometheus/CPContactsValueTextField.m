//
//  CPContactsValueTextField.m
//  Code Prometheus
//
//  Created by 管理员 on 14-6-13.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPContactsValueTextField.h"

@implementation CPContactsValueTextField

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
    self.textColor = [UIColor blackColor];
    self.font = [UIFont systemFontOfSize:16];
    self.clearButtonMode = UITextFieldViewModeWhileEditing;
}

@end
