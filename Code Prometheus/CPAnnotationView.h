//
//  CPAnnotationView.h
//  MAMapKit_static_demo
//
//  Created by songjian on 13-10-16.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import "CPCalloutTableView.h"


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

@protocol CPAnnotationViewDelegate <NSObject>
-(NSArray*) calloutDataWithView:(CPAnnotationView*)view;
@optional
-(void) didSelectRowWithView:(CPAnnotationView*)view row:(NSUInteger)row;
@end

@interface CPAnnotationView : MAAnnotationView
@property (nonatomic, strong) CPCalloutTableView *calloutView;
@property (nonatomic, weak) id<CPAnnotationViewDelegate> delegate;
@end
