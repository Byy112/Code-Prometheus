//
//  CPSexSegmentedControl.m
//  Code Prometheus
//
//  Created by 管理员 on 14-6-12.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPSexSegmentedControl.h"

// 男女选择器颜色
#define CP_SEX_SC_BLUE [UIColor colorWithRed:76.0/255 green:161.0/255 blue:240.0/255 alpha:1]
#define CP_SEX_SC_RED [UIColor colorWithRed:222.0/255 green:92.0/255 blue:75.0/255 alpha:1]

@implementation CPSexSegmentedControl

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

-(id)initWithItems:(NSArray *)items{
    self = [super initWithItems:items];
    if (self) {
        [self setUp];
    }
    return self;
}

-(void)setUp{
    self.tintColor = CP_SEX_SC_BLUE;
    [self addObserver:self forKeyPath:@"selectedSegmentIndex" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSInteger new = [change[NSKeyValueChangeNewKey] integerValue];
    NSInteger old = [change[NSKeyValueChangeOldKey] integerValue];
    if (new != old) {
        self.tintColor = [change[NSKeyValueChangeNewKey] integerValue]?CP_SEX_SC_RED:CP_SEX_SC_BLUE;
    }
}

//-(void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex{
//    [super setSelectedSegmentIndex:selectedSegmentIndex];
//    self.tintColor = selectedSegmentIndex?CP_SEX_SC_RED:CP_SEX_SC_BLUE;
//}
@end
