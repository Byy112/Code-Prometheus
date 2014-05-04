//
//  CustomCalloutView.m
//  Category_demo2D
//
//  Created by xiaoming han on 13-5-22.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import "CPCustomCalloutView.h"
#import <QuartzCore/QuartzCore.h>
#import <Masonry.h>

#define kArrorHeight    8

@interface CPCustomCalloutView ()
@property (nonatomic,weak) UIImageView* imgV;
@property (nonatomic,weak) UILabel* sLabel;
@end

@implementation CPCustomCalloutView

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

-(void) setUp{
    self.backgroundColor = [UIColor clearColor];
    UIImageView* imgV = [[UIImageView alloc] init];
    [self addSubview:imgV];
    [imgV mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(4));
        make.centerY.equalTo(self.mas_centerY).offset(-kArrorHeight/2);
    }];
    self.imgV = imgV;
    UILabel* sLabel = [[UILabel alloc] init];
    sLabel.textColor = [UIColor whiteColor];
    [self addSubview:sLabel];
    [sLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imgV.mas_right);
        make.centerY.equalTo(self.mas_centerY).offset(-kArrorHeight/2);
        make.right.equalTo(@(-4));
        make.width.lessThanOrEqualTo(@(160));
        make.height.equalTo(self.mas_height).offset(-kArrorHeight-8);
    }];
    self.sLabel = sLabel;
}



-(void)setImage:(UIImage *)image{
    _image = image;
    self.imgV.image = image;
}

-(void)setString:(NSString *)string{
    _string = string;
    self.sLabel.text = string;
}

#pragma mark - draw rect

- (void)drawRect:(CGRect)rect{
    [self drawInContext:UIGraphicsGetCurrentContext()];
}

- (void)drawInContext:(CGContextRef)context
{
    CGContextSetLineWidth(context, 2.0);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8].CGColor);
    [self getDrawPath:context];
    CGContextFillPath(context);
}

- (void)getDrawPath:(CGContextRef)context
{
    CGRect rrect = self.bounds;
    CGFloat radius = 6.0;
    CGFloat minx = CGRectGetMinX(rrect),
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect),
    maxy = CGRectGetMaxY(rrect)-kArrorHeight;
    
    CGContextMoveToPoint(context, midx+kArrorHeight, maxy);
    CGContextAddLineToPoint(context,midx, maxy+kArrorHeight);
    CGContextAddLineToPoint(context,midx-kArrorHeight, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}

@end
