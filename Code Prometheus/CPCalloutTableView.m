//
//  CPCalloutTableView.m
//  Code Prometheus
//
//  Created by 管理员 on 14-6-24.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPCalloutTableView.h"
#import <Masonry.h>
#import "CPCalloutTableViewCell.h"
#import "CPCalloutTableViewCellNoImage.h"
#import "CPAnnotationView.h"

#define kArrorHeight    8

@interface CPCalloutTableView ()<UITableViewDataSource>

@end

@implementation CPCalloutTableView

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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self setUp];
    }
    return self;
}

-(void) setUp{
    self.backgroundColor = [UIColor clearColor];
    self.dataSource = self;
}

#define CP_CELL_HEIGHT 29

-(void)setCpData:(NSArray *)cpData{
    _cpData = cpData;
    
    // 计算宽度
    NSString* theLongestStr = nil;
    for (CPPointAnnotation* pa in self.cpData) {
        NSString* string = pa.title;
        if (!theLongestStr || theLongestStr.length<string.length) {
            theLongestStr = string;
        }
    }
    CGSize size = [theLongestStr sizeWithFont:[UIFont systemFontOfSize:15]];
    CGFloat width = size.width;
    
    static CGFloat maxWidth_0 = 0;
    static CGFloat maxWidth_1 = 0;
    if (maxWidth_0 == 0) {
        maxWidth_0 = [@"最多有六个字" sizeWithFont:[UIFont systemFontOfSize:15]].width;
    }
    if (maxWidth_1 == 0) {
        maxWidth_1 = 160;
    }
    if ([(CPPointAnnotation*)self.cpData[0] type] == CPPointAnnotationTypeNone) {
        if (width > maxWidth_1) {
            width = maxWidth_1;
        }
        width += 16;
    }else{
        if (width > maxWidth_0) {
            width = maxWidth_0;
        }
        width += 41;
    }
    // 计算高度
    CGFloat height = 0;
    if (self.cpData.count == 0) {
        height = 0;
    }else if(self.cpData.count <= 3){
        height = CP_CELL_HEIGHT * self.cpData.count;
    }else{
        height = CP_CELL_HEIGHT * 3;
    }
    // 约束
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(width));
        make.height.equalTo(@(height));
    }];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // 背景
    UIView* back = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    CALayer *cyanLayer = [CALayer layer];
    cyanLayer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6].CGColor;
    cyanLayer.frame = CGRectMake(0, 0, width, height);
    [back.layer addSublayer:cyanLayer];
    self.backgroundView = back;
    self.layer.cornerRadius = 5;
    
    // 其他
    if (cpData.count>1) {
        self.bounces = YES;
    }else{
        self.bounces = NO;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.cpData.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell_in_map";
    static NSString *identifier_no_image = @"cell_in_map_no_image";
    
    CPPointAnnotation* pa = self.cpData[indexPath.row];
    
    UITableViewCell *cell = nil;
    if ([pa type] == CPPointAnnotationTypeNone) {
        cell = [tableView dequeueReusableCellWithIdentifier:identifier_no_image];
        if (!cell) {
            cell = [[CPCalloutTableViewCellNoImage alloc] init];
            cell = [[[NSBundle mainBundle] loadNibNamed:@"CPCalloutTableViewCellNoImage" owner:nil options:nil] lastObject];
            [(UILabel*)[cell viewWithTag:10001] setText:[pa title]];
        }
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"CPCalloutTableViewCell" owner:nil options:nil] lastObject];
        }
        if ([pa type] == CPPointAnnotationTypeFamily) {
            [(UIImageView*)[cell viewWithTag:10000] setImage:[UIImage imageNamed:@"cp_map_family"]];
        }else if ([pa type] == CPPointAnnotationTypeCompany){
            [(UIImageView*)[cell viewWithTag:10000] setImage:[UIImage imageNamed:@"cp_map_company"]];
        }
        
        [(UILabel*)[cell viewWithTag:10001] setText:[pa title]];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
@end
