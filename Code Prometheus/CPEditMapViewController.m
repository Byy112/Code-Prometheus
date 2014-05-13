//
//  CPEditMapViewController.m
//  Code Prometheus
//
//  Created by mirror on 13-12-6.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPEditMapViewController.h"
#import "CommonUtility.h"
#import <MBProgressHUD.h>
#import <TWMessageBarManager.h>
#import <BlocksKit.h>


static char CPAnnotationTypeKey;
typedef NS_ENUM(NSInteger, CPAnnotationType) {
    CPAnnotationTypeCPPointAnnotation,
    CPAnnotationTypeReGeocodeAnnotation,
    CPAnnotationTypePOIAnnotation
};


@interface CPEditMapViewController ()<UITableViewDataSource,UISearchBarDelegate,UISearchDisplayDelegate>
@property(nonatomic) MBProgressHUD* hud;
@property (nonatomic) BOOL goPoint;

// 数据库点
@property (nonatomic) NSMutableArray* annotationDB;
// 点击的点
@property (nonatomic) NSMutableArray* annotationTap;
// 搜索的点
@property (nonatomic) NSMutableArray* annotationSearch;

@property (nonatomic) NSArray* pois;
@end

@implementation CPEditMapViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (CP_IS_IOS7_AND_UP) {
        self.searchDisplayController.searchBar.searchBarStyle = UISearchBarStyleDefault;
    }
    // UI
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonClick:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonClick:)];
    self.navigationItem.leftBarButtonItem = leftButton;
//    self.searchDisplayController.searchBar.text = self.name;
    
    // 长按手势
    UILongPressGestureRecognizer *btnLongTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    btnLongTap.minimumPressDuration = 0.5;
    [self.view addGestureRecognizer:btnLongTap];
    
    self.goUserLocation = self.cpAnnotation == nil;
    self.goPoint = self.cpAnnotation != nil;
    
    // 数据库点
    self.annotationDB = [NSMutableArray array];
    if (self.cpAnnotation) {
        [self.cpAnnotation bk_associateValue:@(CPAnnotationTypeCPPointAnnotation) withKey:&CPAnnotationTypeKey];
        [self.annotationDB addObject:self.cpAnnotation];
    }
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.goPoint) {
        [self.mapView setVisibleMapRect:MAMapRectMake(220880104, 101476980, 272496, 466656) animated:NO];
        [self.mapView setCenterCoordinate:[self.cpAnnotation coordinate] animated:YES];
        self.goPoint = NO;
        [self.mapView addAnnotation:self.cpAnnotation];
        [self.mapView selectAnnotation:self.cpAnnotation animated:NO];
    }
    [self updateMapView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // 需要搜索
    if (!self.cpAnnotation && self.name) {
        NSString* addressName = [self.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (![addressName isEqualToString:@""]) {
            [self.searchDisplayController setActive:YES animated:YES];
            [self.searchDisplayController.searchBar setText:addressName];
        }
    }
}

-(void) updateMapView{
    // 清空大头针
    NSMutableArray* annotationForRemove = [@[] mutableCopy];
    for (id <MAAnnotation> annotation in self.mapView.annotations) {
        NSObject* obje = annotation;
        CPAnnotationType type = [[obje bk_associatedValueForKey:&CPAnnotationTypeKey] integerValue];
        if (type == CPAnnotationTypeReGeocodeAnnotation || type == CPAnnotationTypePOIAnnotation) {
            [annotationForRemove addObject:annotation];
        }
    }
    id<MAAnnotation> selectAn = self.mapView.selectedAnnotations.firstObject;
    [self.mapView removeAnnotations:annotationForRemove];
    // 添加大头针
    [self.mapView addAnnotations:self.annotationDB];
    [self.mapView addAnnotations:self.annotationTap];
    [self.mapView addAnnotations:self.annotationSearch];
    if (selectAn) {
        for (id<MAAnnotation> objAn in self.mapView.annotations) {
            if ([[selectAn title] isEqualToString:[objAn title]] && selectAn.coordinate.latitude == objAn.coordinate.latitude && selectAn.coordinate.longitude == objAn.coordinate.longitude) {
                [self.mapView selectAnnotation:objAn animated:YES];
                break;
            }
        }
    }
}

#pragma mark - private
typedef NS_ENUM(NSInteger, CP_MAP_SEARCH_TYPE) {
    CP_MAP_SEARCH_TYPE_TIP,
    CP_MAP_SEARCH_TYPE_PLACE_UID,
    CP_MAP_SEARCH_TYPE_PLACE_KEY
};
/* 地点 搜索. */
- (void)searchPlaceWithKey:(NSString *)key type:(CP_MAP_SEARCH_TYPE)type{
    if (key.length == 0){
        return;
    }
    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    
    if (type == CP_MAP_SEARCH_TYPE_TIP) {
        request.searchType = AMapSearchType_PlaceKeyword;
        request.keywords = key;
        request.requireExtension = NO;
    }else if (type == CP_MAP_SEARCH_TYPE_PLACE_UID){
        request.searchType = AMapSearchType_PlaceID;
        request.uid = key;
        request.requireExtension = YES;
    }else if (type == CP_MAP_SEARCH_TYPE_PLACE_KEY){
        request.searchType = AMapSearchType_PlaceKeyword;
        request.keywords = key;
        request.requireExtension = YES;
    }
    if (CP_MAP_UTIL_CITY) {
        request.city = @[CP_MAP_UTIL_CITY];
    }
    [self.search AMapPlaceSearch:request];
}
#pragma mark - IBAction
-(IBAction) saveButtonClick:(UIButton*)sender{
    // 保存信息
    if (self.mapView.selectedAnnotations.count>0 && ![self.mapView.selectedAnnotations.firstObject isKindOfClass:[MAUserLocation class]]) {
        // 选点
        id<MAAnnotation> annotation = self.mapView.selectedAnnotations.lastObject;
        
        // 调用代理
        if (self.delegate) {
            [self.delegate saveAddress:self name:[annotation title] longitude:[NSString stringWithFormat:@"%f",annotation.coordinate.longitude] latitude:[NSString stringWithFormat:@"%f",annotation.coordinate.latitude]];
        }
        // 返回上个视图
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        // 没选点
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"请选点" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
}
-(IBAction)cancelButtonClick:(id)sender{
    // 返回上个视图
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - Action
- (void)tapGesture:(id)sender
{
    UILongPressGestureRecognizer* lp = sender;
    if(UIGestureRecognizerStateBegan != lp.state) {
        return;
    }
    // 启动进度条
    self.hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.view addSubview:self.hud];
    [self.hud show:YES];
    // 搜索逆向地理编码
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:[lp locationInView:self.view] toCoordinateFromView:self.mapView];
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [self.search AMapReGoecodeSearch:regeo];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tipCellIdentifier = @"tipCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tipCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:tipCellIdentifier];
    }
    
    AMapPOI *poi = self.pois[indexPath.row];
    
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    return cell;
}
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AMapPOI *poi = self.pois[indexPath.row];
    [self searchPlaceWithKey:poi.uid type:CP_MAP_SEARCH_TYPE_PLACE_UID];
    [self.searchDisplayController setActive:NO animated:YES];
    self.searchDisplayController.searchBar.text = poi.name;
}
#pragma mark - AMapSearchDelegate
// 搜索异常
- (void)search:(id)searchRequest error:(NSString*)errInfo{
    [super search:searchRequest error:errInfo];
    if (self.hud) {
        // hud消失
        [self.hud removeFromSuperview];
        self.hud = nil;
    }
}

/* POI 搜索回调. */
- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)respons
{
    
    if (request.searchType == AMapSearchType_PlaceKeyword && request.requireExtension == NO) {
//        CPLogVerbose(@"输入提示回调 %@",respons);
        self.pois = respons.pois;
        [self.searchDisplayController.searchResultsTableView reloadData];
    }else if(request.searchType == AMapSearchType_PlaceID || (request.searchType == AMapSearchType_PlaceKeyword && request.requireExtension == YES)){
//        CPLogVerbose(@"POI回调 %@",respons);
        if (respons.pois.count == 0)
        {
            [[TWMessageBarManager sharedInstance] hideAll];
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:@"无结果"
                                                                  type:TWMessageBarMessageTypeInfo];
            return;
        }
        NSMutableArray *annotations = [NSMutableArray array];
        
        [respons.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
            CPPointAnnotation* annotation = [[CPPointAnnotation alloc] init];
            annotation.uuid = nil;
            annotation.title = obj.name;
            annotation.subtitle = nil;
            annotation.coordinate = CLLocationCoordinate2DMake(obj.location.latitude, obj.location.longitude) ;
            annotation.type = CPPointAnnotationTypeNone;
            [annotation bk_associateValue:@(CPAnnotationTypePOIAnnotation) withKey:&CPAnnotationTypeKey];
            [annotations addObject:annotation];
        }];
        
        if (annotations.count == 1)
        {
            [self.mapView setRegion:MACoordinateRegionMake([annotations[0] coordinate], MACoordinateSpanMake(0.01, 0.01)) animated:YES];
        }
        else
        {
            [self.mapView setVisibleMapRect:[CommonUtility minMapRectForAnnotations:annotations] edgePadding:UIEdgeInsetsMake(160, 60, 60, 60) animated:YES];
        }
        self.annotationSearch = annotations;
        [self updateMapView];
        [self.mapView selectAnnotation:annotations[0] animated:YES];
    }
}
/* 逆地理编码回调. */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
//    CPLogVerbose(@"逆地理编码回调 %@",response);
    // hud消失
    if (self.hud) {
        [self.hud removeFromSuperview];
        self.hud = nil;
    }
    if (response.regeocode != nil)
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(request.location.latitude, request.location.longitude);
        CPPointAnnotation* annotation = [[CPPointAnnotation alloc] init];
        annotation.uuid = nil;
        annotation.title = [NSString stringWithFormat:@"%@%@%@%@",response.regeocode.addressComponent.district,response.regeocode.addressComponent.township,response.regeocode.addressComponent.neighborhood,response.regeocode.addressComponent.building];
        if (annotation.title.length == 0) {
            [[TWMessageBarManager sharedInstance] hideAll];
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                           description:@"无结果"
                                                                  type:TWMessageBarMessageTypeInfo];
            return;
        }
        annotation.subtitle = nil;
        annotation.coordinate = coordinate;
        annotation.type = CPPointAnnotationTypeNone;
        [annotation bk_associateValue:@(CPAnnotationTypeReGeocodeAnnotation) withKey:&CPAnnotationTypeKey];
        self.annotationTap = [@[annotation] mutableCopy];
        [self updateMapView];
        [self.mapView selectAnnotation:annotation animated:YES];
    }
}

#pragma mark - MAMapViewDelegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    static NSString *customReuseIndetifier = @"customReuseIndetifier";
    if ([annotation isKindOfClass:[CPPointAnnotation class]])
    {
        CPAnnotationView *annotationView = (CPAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:customReuseIndetifier];
        if (annotationView == nil){
            annotationView = [[CPAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:customReuseIndetifier];
        }
        return annotationView;
    }
    return nil;
}

#pragma mark - UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if (self.searchDisplayController.active) {
        [self searchPlaceWithKey:searchString type:CP_MAP_SEARCH_TYPE_TIP];
    }
    return NO;
}
- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    controller.searchBar.text = controller.searchBar.text;
}
-(void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        CGRect statusBarFrame =  [[UIApplication sharedApplication] statusBarFrame];
        statusBarFrame.size.height += 20;
        [UIView animateWithDuration:0.25 animations:^{
            for (UIView *subview in self.view.subviews)
                subview.transform = CGAffineTransformMakeTranslation(0, statusBarFrame.size.height);
        }];
    }
}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [UIView animateWithDuration:0.25 animations:^{
            for (UIView *subview in self.view.subviews)
                subview.transform = CGAffineTransformIdentity;
        }];
    }
}
#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    NSString *key = searchBar.text;
    [self searchPlaceWithKey:key type:CP_MAP_SEARCH_TYPE_PLACE_KEY];
    [self.searchDisplayController setActive:NO animated:YES];
    self.searchDisplayController.searchBar.text = key;
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    self.searchDisplayController.searchResultsTableView.contentInset = UIEdgeInsetsZero;
}
@end
