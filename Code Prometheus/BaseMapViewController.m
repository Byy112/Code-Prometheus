//
//  BaseMapViewController.m
//  SearchV3Demo
//
//  Created by songjian on 13-8-14.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import "BaseMapViewController.h"

@interface BaseMapViewController ()
@property (nonatomic) NSArray* annotations;
@property (nonatomic) MACoordinateRegion region;
@property (nonatomic) NSArray *selectedAnnotations;
@end

@implementation BaseMapViewController

@synthesize mapView = _mapView;
@synthesize search  = _search;

- (void)viewDidLoad{
    [super viewDidLoad];
    _goUserLocation = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // 初始化
    self.mapView = [CPMapUtil sharedMapView];
    self.search  = [CPMapUtil sharedMapSearchAPI];
    
    [self initMapView];
    [self initSearch];
    // 恢复状态
    if (self.annotations) {
        [self.mapView addAnnotations:self.annotations];
    }
    if (self.region.center.latitude != 0 && self.region.center.longitude != 0) {
        [self.mapView setRegion:self.region animated:NO];
    }
    if (self.selectedAnnotations && self.selectedAnnotations.count) {
        [self.mapView selectAnnotation:self.selectedAnnotations[0] animated:NO];
    }
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    // 保存状态
    self.annotations = [self.mapView.annotations copy];
    self.region = self.mapView.region;
    self.selectedAnnotations = [self.mapView.selectedAnnotations copy];
    // 清除数据
    [self clearMapView];
    [self clearSearch];
}

#pragma mark - private

- (void)initMapView
{
    CGRect frame = self.view.bounds;
//    if (self.navigationController) {
//        CGFloat height = self.navigationController.toolbar.frame.size.height;
////        frame.origin.y += height;
//        frame.size.height -= height;
//    }
//    if (self.tabBarController && !self.tabBarController.tabBar.hidden) {
//        CGFloat height = self.tabBarController.tabBar.frame.size.height;
//        frame.size.height -= height;
//    }
    self.mapView.frame = frame;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
//    self.mapView.visibleMapRect = MAMapRectMake(220880104, 101476980, 272496, 466656);
    self.mapView.showsUserLocation = YES;
//    if (self.mapView.userLocation.location) {
//        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:NO];
//    }
}

- (void)initSearch
{
    self.search.delegate = self;
}

- (void)clearMapView
{
    self.mapView.showsUserLocation = NO;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    self.mapView.delegate = nil;
}

- (void)clearSearch
{
    self.search.delegate = nil;
}

#pragma mark - MAMapViewDelegate
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
    // 如果非地理位置变化,则返回
    if (!updatingLocation) {
        return;
    }
    CLLocationCoordinate2D coordinate = userLocation.location.coordinate;
    if (_goUserLocation && [self.mapView.userLocation location]) {
        [self.mapView setRegion:MACoordinateRegionMake(coordinate, MACoordinateSpanMake(0.01, 0.01)) animated:YES];
        _goUserLocation = NO;
    }
    [CPMapUtil updateCityAndLocation:userLocation];
}
static BOOL CP_SHOW_LOCATE_ERROR = YES;
- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    _goUserLocation = NO;
    CPLogWarn(@"定位失败! error:%@",error);
    if (error.code == 1 && CP_SHOW_LOCATE_ERROR) {
        CPLogWarn(@"定位失败原因：用户关闭定位权限");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"请在设置-隐私中打开\"定位服务\"来允许\"保险家\"确定您的位置" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alert show];
        [mapView setVisibleMapRect:MAMapRectMake(220880104, 101476980, 272496, 466656) animated:NO];
        CP_SHOW_LOCATE_ERROR = NO;
    }
}

#pragma mark - AMapSearchDelegate
- (void)search:(id)searchRequest error:(NSString *)errInfo
{
    CPLogWarn(@"%s: searchRequest = %@, errInfo= %@", __func__, [searchRequest class], errInfo);
}
@end
