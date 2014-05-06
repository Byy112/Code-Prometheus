//
//  CPAnnotationView.m
//  MAMapKit_static_demo
//
//  Created by songjian on 13-10-16.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import "CPAnnotationView.h"
#import "CPCustomCalloutView.h"
#import "CPContactsDetailViewController.h"
#import <Masonry.h>


@implementation CPPointAnnotation
@end

@interface CPAnnotationView ()
@end

@implementation CPAnnotationView

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self){
        self.image = [UIImage imageNamed:@"cp_map_3"];
        self.canShowCallout   = NO;
        self.draggable        = NO;
        self.centerOffset = CGPointMake(0, -self.image.size.height/4);
    }
    return self;
}


#pragma mark - Handle Action

- (void)btnAction{
    if (self.block) {
        self.block(self);
    }
}

#pragma mark - Override


- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected == selected)
    {
        return;
    }
    
    if (selected)
    {
        self.image = [UIImage imageNamed:@"cp_map_2"];
        if (self.calloutView == nil)
        {
            /* Construct custom callout. */
            self.calloutView = [[CPCustomCalloutView alloc] init]; 
            if ([self.annotation isKindOfClass:[CPPointAnnotation class]]) {
                switch ([(CPPointAnnotation*)self.annotation type]) {
                    case CPPointAnnotationTypeFamily:
                        self.calloutView.image = [UIImage imageNamed:@"cp_map_family"];
                        break;
                    case CPPointAnnotationTypeCompany:
                        self.calloutView.image = [UIImage imageNamed:@"cp_map_company"];
                        break;
                    default:
                        break;
                }
            }else{
                self.calloutView.image = nil;
            }
            
            self.calloutView.string = [self.annotation title];
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(btnAction)];
            [self.calloutView addGestureRecognizer:tapGesture];
        }
        
        [self addSubview:self.calloutView];
        [self.calloutView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_top);
            make.centerX.equalTo(@(0));
        }];
    }
    else
    {
        self.image = [UIImage imageNamed:@"cp_map_3"];
        [self.calloutView removeFromSuperview];
    }
    
    [super setSelected:selected animated:animated];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    if (!inside && self.selected){
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    return inside;
}

@end
