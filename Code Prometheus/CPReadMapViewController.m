//
//  CPReadMapViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-9.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPReadMapViewController.h"
#import <Masonry.h>
#import "CPContactsDetailViewController.h"
#import "CPContactsInMapTableViewController.h"


// 地图模式
typedef NS_ENUM(NSInteger, CPReadMapModel) {
    CPReadMapModelOnlySelfContacts,
    CPReadMapModelContactsInRegion
};


@interface CPReadMapViewController ()

// 显示的标记
@property (nonatomic) NSMutableArray* annotationArray;
// 地图模式
@property (nonatomic) CPReadMapModel model;

@property (nonatomic) BOOL goPoint;
@end

@implementation CPReadMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.goUserLocation = NO;
    self.goPoint = YES;
    self.model = CPReadMapModelOnlySelfContacts;
    
    // 右侧view
    UIButton* allContactsButton = [[UIButton alloc] init];
    [self.view addSubview:allContactsButton];
    [allContactsButton addTarget:self action:@selector(allContactsButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [allContactsButton setImage:[UIImage imageNamed:@"cp_map_all_contacts"] forState:UIControlStateNormal];
    [allContactsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(64));
        make.right.equalTo(@(-8));
    }];
    
    UIButton* localButton = [[UIButton alloc] init];
    [self.view addSubview:localButton];
    [localButton addTarget:self action:@selector(localButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [localButton setImage:[UIImage imageNamed:@"cp_map_local"] forState:UIControlStateNormal];
    [localButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(allContactsButton.mas_bottom).offset(8);
        make.right.equalTo(@(-8));
    }];
    
    UIButton* listButton = [[UIButton alloc] init];
    [self.view addSubview:listButton];
    [listButton addTarget:self action:@selector(listButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [listButton setImage:[UIImage imageNamed:@"cp_map_list"] forState:UIControlStateNormal];
    [listButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(localButton.mas_bottom).offset(8);
        make.right.equalTo(@(-8));
    }];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.goPoint) {
        [self.mapView setVisibleMapRect:MAMapRectMake(220880104, 101476980, 272496, 466656) animated:NO];
        [self.mapView setCenterCoordinate:[self.cpAnnotation coordinate] animated:YES];
        self.goPoint = NO;
    }
    [self loadModelAndUpdateUI];
}

-(void) loadModelAndUpdateUI{
    if (self.model == CPReadMapModelContactsInRegion) {
        [self findAnnotationInMapViewRegion];
    }else{
        self.annotationArray = [NSMutableArray array];
        [self.annotationArray addObject:self.cpAnnotation];
    }
    
    [self updateMapView];
}

-(void) updateMapView{
    // 清空大头针
    NSMutableArray* annotationForRemove = [@[] mutableCopy];
    for (id <MAAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
            [annotationForRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationForRemove];
    
    // 添加大头针
    [self.mapView addAnnotations:self.annotationArray];
}

-(void) findAnnotationInMapViewRegion{
    MAMapView* mapView = self.mapView;
    CLLocationCoordinate2D coordinate;
    coordinate = [mapView convertPoint:CGPointMake(-60, 0) toCoordinateFromView:mapView];
    double left = coordinate.longitude;
    double top = coordinate.latitude;
    coordinate = [mapView convertPoint:CGPointMake(mapView.frame.size.width+60, mapView.frame.size.height+80) toCoordinateFromView:mapView];
    double right = coordinate.longitude;
    double bottom = coordinate.latitude;
    CPLogVerbose(@"加载地图区域数据 left,right,top,bottom (%f,%f,%f,%f)",left,right,top,bottom);
    
    self.annotationArray = [NSMutableArray array];
    
    // 家庭地址
    [[CPDB getLKDBHelperByUser] executeDB:^(FMDatabase *db) {
        FMResultSet* set = [db executeQuery:@"SELECT c.cp_uuid,c.cp_name,f.cp_longitude,f.cp_latitude,f.cp_address_name FROM cp_contacts c INNER JOIN cp_family f ON f.cp_contact_uuid = c.cp_uuid WHERE f.cp_invain NOTNULL AND f.cp_invain == 1 AND CAST(f.cp_longitude AS NUMERIC)>=? AND CAST(f.cp_longitude AS NUMERIC) <=? AND CAST(f.cp_latitude AS NUMERIC)>=? AND CAST(f.cp_latitude AS NUMERIC)<=?" withArgumentsInArray:@[@(left),@(right),@(bottom),@(top)]];
        
        
        int columeCount = [set columnCount];
        while ([set next]) {
            CPPointAnnotation* annotation = [[CPPointAnnotation alloc] init];
            CLLocationDegrees longitude = 0;
            CLLocationDegrees latitude = 0;
            for (int i=0; i<columeCount; i++) {
                NSString* sqlValue = [set stringForColumnIndex:i];
                switch (i) {
                    case 0:{
                        annotation.uuid = sqlValue;
                        break;
                    }
                    case 1:{
                        annotation.title = sqlValue;
                        break;
                    }
                    case 2:{
                        longitude = sqlValue.doubleValue;
                        break;
                    }
                    case 3:{
                        latitude = sqlValue.doubleValue;
                        break;
                    }
                    case 4:{
                        annotation.subtitle = sqlValue;
                        break;
                    }
                    default:
                        break;
                }
            }
            annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            annotation.type = CPPointAnnotationTypeFamily;
            [self.annotationArray addObject:annotation];
        }
        [set close];
    }];
    
    // 公司地址
    [[CPDB getLKDBHelperByUser] executeDB:^(FMDatabase *db) {
        FMResultSet* set = [db executeQuery:@"SELECT c.cp_uuid,c.cp_name,f.cp_longitude,f.cp_latitude,f.cp_address_name FROM cp_contacts c INNER JOIN cp_company f ON f.cp_contact_uuid = c.cp_uuid WHERE f.cp_invain NOTNULL AND f.cp_invain == 1 AND CAST(f.cp_longitude AS NUMERIC)>=? AND CAST(f.cp_longitude AS NUMERIC) <=? AND CAST(f.cp_latitude AS NUMERIC)>=? AND CAST(f.cp_latitude AS NUMERIC)<=?" withArgumentsInArray:@[@(left),@(right),@(bottom),@(top)]];
        
        int columeCount = [set columnCount];
        while ([set next]) {
            CPPointAnnotation* annotation = [[CPPointAnnotation alloc] init];
            CLLocationDegrees longitude = 0;
            CLLocationDegrees latitude = 0;
            for (int i=0; i<columeCount; i++) {
                NSString* sqlValue = [set stringForColumnIndex:i];
                switch (i) {
                    case 0:{
                        annotation.uuid = sqlValue;
                        break;
                    }
                    case 1:{
                        annotation.title = sqlValue;
                        break;
                    }
                    case 2:{
                        longitude = sqlValue.doubleValue;
                        break;
                    }
                    case 3:{
                        latitude = sqlValue.doubleValue;
                        break;
                    }
                    case 4:{
                        annotation.subtitle = sqlValue;
                        break;
                    }
                    default:
                        break;
                }
            }
            annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            annotation.type = CPPointAnnotationTypeCompany;
            [self.annotationArray addObject:annotation];
        }
        [set close];
    }];
}

#pragma mark - Action

-(void) allContactsButtonClick:(id)sender{
    switch (self.model) {
        case CPReadMapModelContactsInRegion:
            self.model = CPReadMapModelOnlySelfContacts;
            break;
        case CPReadMapModelOnlySelfContacts:
            self.model = CPReadMapModelContactsInRegion;
        default:
            break;
    }
    [self loadModelAndUpdateUI];
}
-(void) localButtonClick:(id)sender{
    if ([self.mapView.userLocation location]) {
        [self.mapView setRegion:MACoordinateRegionMake(self.mapView.userLocation.coordinate, MACoordinateSpanMake(0.01, 0.01)) animated:YES];
    }
}
-(void) listButtonClick:(id)sender{
    CPContactsInMapTableViewController* controller = [[CPContactsInMapTableViewController alloc] initWithNibName:nil bundle:nil];
    controller.annotationArray = self.annotationArray;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - MAMapViewDelegate
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[CPPointAnnotation class]])
    {
        static NSString *customReuseIndetifier = @"customReuseIndetifier";
        CPAnnotationView *annotationView = (CPAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:customReuseIndetifier];
        if (annotationView == nil){
            annotationView = [[CPAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:customReuseIndetifier];
            annotationView.block =  ^(CPAnnotationView* view) {
                CPPointAnnotation* annotation = view.annotation;
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                CPContactsDetailViewController* controller = [mainStoryboard instantiateViewControllerWithIdentifier:@"CPContactsDetailViewController"];
                controller.contactsUUID = annotation.uuid;
                [self.navigationController pushViewController:controller animated:YES];
            };
        }
        return annotationView;
    }
    return nil;
}
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (self.model == CPReadMapModelContactsInRegion) {
        [self loadModelAndUpdateUI];
    }
}
@end
