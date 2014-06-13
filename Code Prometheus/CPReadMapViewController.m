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
#import <TWMessageBarManager.h>

@interface CPReadMapViewController ()

// 地图模式
@property (nonatomic) BOOL showAround;

// 显示的标记
@property (nonatomic) NSMutableArray* annotationArray;

// 地图范围内人脉读取线程池
@property (nonatomic) NSOperationQueue* queue;

@property (nonatomic) BOOL goPoint;
@end

@implementation CPReadMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.goUserLocation = NO;
    self.goPoint = YES;
    self.showAround = NO;
    
    // 队列
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    self.queue = queue;
    
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
        [self.mapView setRegion:MACoordinateRegionMake([self.cpAnnotation coordinate], MACoordinateSpanMake(0.01, 0.01)) animated:YES];
        [self.mapView addAnnotation:self.cpAnnotation];
        [self.mapView selectAnnotation:self.cpAnnotation animated:NO];
        self.goPoint = NO;
    }
}

#pragma mark - private
-(void) updateUI{
    [self doItInQueue:^{
        [self findAnnotationInMapViewRegion];
        [self performSelectorOnMainThread:@selector(updateMapView) withObject:nil waitUntilDone:YES];
    } cancelFrontBlock:YES];
}
-(void) doItInQueue:(void (^)(void))block cancelFrontBlock:(BOOL)cancelBlock{
    if (cancelBlock) {
        // 取消以前的操作
        [self.queue cancelAllOperations];
    }
    // 创建最新的操作
    NSOperation* op = [NSBlockOperation blockOperationWithBlock:block];
    [self.queue addOperation:op];
}

#pragma mark - private ui
-(void) updateMapView{
    // 计算需要清空的大头针
    NSMutableArray* annotationForRemove = [@[] mutableCopy];
    for (id <MAAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
            [annotationForRemove addObject:annotation];
        }
    }
    // 选中的点
    id<MAAnnotation> selectAn = self.mapView.selectedAnnotations.firstObject;
    // 清空大头针
    [self.mapView removeAnnotations:annotationForRemove];
    // 添加，选中需要选中的点（如果有）
    if (selectAn) {
        [self.mapView addAnnotation:selectAn];
        [self.mapView selectAnnotation:selectAn animated:YES];
    }
    if (self.showAround && !(!CPMemberLicense || CPMemberLicense<=[[NSDate date] timeIntervalSince1970]) && !(fabs(CPDelta_T) > 86400)) {
        // 显示周边人脉
        id<MAAnnotation> objDelete = nil;
        for (id<MAAnnotation> objAn in self.annotationArray) {
            if ([[selectAn title] isEqualToString:[objAn title]] && selectAn.coordinate.latitude == objAn.coordinate.latitude && selectAn.coordinate.longitude == objAn.coordinate.longitude) {
                objDelete = objAn;
                break;
            }
        }
        if (objDelete) {
            [self.annotationArray removeObject:objDelete];
        }
        [self.mapView addAnnotations:self.annotationArray];
    }
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
//    CPLogVerbose(@"加载地图区域数据 left,right,top,bottom (%f,%f,%f,%f)",left,right,top,bottom);
    
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
    if (fabs(CPDelta_T) > 86400) {
        [[TWMessageBarManager sharedInstance] hideAll];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:@"请校正系统时间"
                                                              type:TWMessageBarMessageTypeInfo];
        return;
    }
    if (!CPMemberLicense || CPMemberLicense<=[[NSDate date] timeIntervalSince1970]) {
        [[TWMessageBarManager sharedInstance] hideAll];
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"NO"
                                                       description:@"请登陆并充值"
                                                              type:TWMessageBarMessageTypeInfo];
        return;
    }
    self.showAround = !self.showAround;
    [self updateUI];
}
-(void) localButtonClick:(id)sender{
    if ([self.mapView.userLocation location]) {
        [self.mapView setRegion:MACoordinateRegionMake(self.mapView.userLocation.coordinate, MACoordinateSpanMake(0.01, 0.01)) animated:YES];
    }else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"请在设置-隐私中打开\"定位服务\"来允许\"保险家\"确定您的位置" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alert show];
    }
}
-(void) listButtonClick:(id)sender{
    CPContactsInMapTableViewController* controller = [[CPContactsInMapTableViewController alloc] initWithNibName:nil bundle:nil];
    NSMutableArray* array = [@[] mutableCopy];
    for (id<MAAnnotation> an in self.mapView.annotations) {
        if ([an isKindOfClass:[MAPointAnnotation class]]) {
            [array addObject:an];
        }
    }
    controller.annotationArray = array;
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
    if (self.showAround && !(!CPMemberLicense || CPMemberLicense<=[[NSDate date] timeIntervalSince1970])) {
        if (!(fabs(CPDelta_T) > 86400)) {
            [self updateUI];
        }
    }
}
@end
