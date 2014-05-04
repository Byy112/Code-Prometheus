//
//  CPAnnotationView.h
//  MAMapKit_static_demo
//
//  Created by songjian on 13-10-16.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "CPCustomCalloutView.h"


typedef NS_ENUM(NSInteger, CPPointAnnotationType) {
    CPPointAnnotationTypeNone,
    CPPointAnnotationTypeFamily,
    CPPointAnnotationTypeCompany
};

@interface CPPointAnnotation : MAPointAnnotation
@property(nonatomic)NSString* uuid;
@property(nonatomic)CPPointAnnotationType type;
@end

@class CPAnnotationView;

typedef void (^CPAnnotationCalloutClickBlock)(CPAnnotationView* view);

@interface CPAnnotationView : MAAnnotationView
@property (nonatomic, strong) CPCustomCalloutView *calloutView;
@property (nonatomic, copy) CPAnnotationCalloutClickBlock block;
@end
