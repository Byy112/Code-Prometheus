//
//  CPAnnotationView.m
//  MAMapKit_static_demo
//
//  Created by songjian on 13-10-16.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import "CPAnnotationView.h"
#import "CPContactsDetailViewController.h"
#import <Masonry.h>


@implementation CPPointAnnotation
@end

@interface CPAnnotationView () <UITableViewDelegate>
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

#pragma mark - Override


- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.selected == selected) {
        return;
    }
    
    [super setSelected:selected animated:animated];
    
    if (selected)
    {
        self.image = [UIImage imageNamed:@"cp_map_2"];
        
        
        if (!self.delegate) {
            return;
        }
        
        if (self.calloutView == nil)
        {
            self.calloutView = [[CPCalloutTableView alloc] init];
            self.calloutView.delegate = self;
            self.calloutView.allowsSelection = NO;
            self.calloutView.cpData = [self.delegate calloutDataWithView:self];
            
            UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapInTable:)];
            [self.calloutView addGestureRecognizer:tap];
        }
        
        [self addSubview:self.calloutView];
        [self.calloutView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.mas_top);
            make.centerX.equalTo(self.mas_centerX);
        }];
    }
    else
    {
        self.image = [UIImage imageNamed:@"cp_map_3"];
        [self.calloutView removeFromSuperview];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    if (!inside && self.selected){
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    return inside;
}


-(void) tapInTable:(UIGestureRecognizer*)sender{
    NSIndexPath* path = [self.calloutView indexPathForRowAtPoint:[sender locationInView:self.calloutView]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectRowWithView:row:)]) {
        [self.delegate didSelectRowWithView:self row:path.row];
    }
}

#define CP_CELL_HEIGHT 29

#pragma mark - UITableViewDelegate
//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectRowWithView:row:)]) {
//        [self.delegate didSelectRowWithView:self row:indexPath.row];
//    }
//}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return CP_CELL_HEIGHT;
}
@end
