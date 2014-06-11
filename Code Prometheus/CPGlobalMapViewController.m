//
//  CPGlobalMapViewController.m
//  Code Prometheus
//
//  Created by 管理员 on 14-1-8.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPGlobalMapViewController.h"
#import "CPContacts.h"
#import "CPFamily.h"
#import "CPCompany.h"
#import "CPAnnotationView.h"
#import <Masonry.h>
#import "CPContactsDetailViewController.h"
#import "CommonUtility.h"
#import "CPContactsInMapTableViewController.h"
#import <TWMessageBarManager.h>

@interface CPGlobalMapViewController ()<MAMapViewDelegate, AMapSearchDelegate,UISearchBarDelegate,UISearchDisplayDelegate,UITableViewDelegate,UITableViewDataSource>
// 地图模式
@property (nonatomic) BOOL showAround;
// 显示的标记
@property (nonatomic) NSMutableArray* annotationArray;
// 地图范围内人脉读取线程池
@property (nonatomic) NSOperationQueue* queue;
// 搜索table相关的model
@property (nonatomic) NSMutableArray* contactsArray;
@property (nonatomic) NSMutableDictionary* contactsForAlephSort;
@property (nonatomic) NSArray* contactsForAlephSortKeys;
@end

@implementation CPGlobalMapViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.showAround = YES;
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

//-(void)viewWillAppear:(BOOL)animated{
//    [super viewWillAppear:animated];
//    [self updateUI];
//}

#pragma mark - Action

-(void) allContactsButtonClick:(id)sender{
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
    controller.hidesBottomBarWhenPushed = YES;
    
    NSMutableArray* array = [@[] mutableCopy];
    for (id<MAAnnotation> an in self.mapView.annotations) {
        if ([an isKindOfClass:[MAPointAnnotation class]]) {
            [array addObject:an];
        }
    }
    controller.annotationArray = array;
    [self.navigationController pushViewController:controller animated:YES];
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
#pragma mark - private load & init
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

-(NSArray*) findAnnotationByContacts:(CPContacts*) contacts{
    NSMutableArray* annotationArray = [NSMutableArray array];
    CPFamily* family = [[CPDB getLKDBHelperByUser] searchSingle:[CPFamily class] where:[NSString stringWithFormat:@"cp_contact_uuid = '%@' AND cp_invain NOTNULL AND cp_invain == 1",contacts.cp_uuid] orderBy:nil];
    if (family) {
        CPPointAnnotation* annotation = [[CPPointAnnotation alloc] init];
        annotation.uuid = contacts.cp_uuid;
        annotation.title = contacts.cp_name;
        annotation.subtitle = family.cp_address_name;
        annotation.coordinate = CLLocationCoordinate2DMake(family.cp_latitude.doubleValue, family.cp_longitude.doubleValue);
        annotation.type = CPPointAnnotationTypeFamily;
        [annotationArray addObject:annotation];
    }
    CPCompany* company = [[CPDB getLKDBHelperByUser] searchSingle:[CPCompany class] where:[NSString stringWithFormat:@"cp_contact_uuid = '%@' AND cp_invain NOTNULL AND cp_invain == 1",contacts.cp_uuid] orderBy:nil];
    if (company) {
        CPPointAnnotation* annotation = [[CPPointAnnotation alloc] init];
        annotation.uuid = contacts.cp_uuid;
        annotation.title = contacts.cp_name;
        annotation.subtitle = company.cp_address_name;
        annotation.coordinate = CLLocationCoordinate2DMake(company.cp_latitude.doubleValue, company.cp_longitude.doubleValue);
        annotation.type = CPPointAnnotationTypeCompany;
        [annotationArray addObject:annotation];
    }
    return annotationArray;
}
-(void) loadContactsWithSearchString:(NSString*)searchString{
    [[CPDB getLKDBHelperByUser] executeDB:^(FMDatabase *db) {
        FMResultSet* set = [db executeQuery:@"SELECT rowid,* FROM cp_contacts c WHERE c.cp_uuid IN(SELECT f.cp_contact_uuid FROM cp_family f LEFT OUTER JOIN cp_company com ON f.cp_contact_uuid = com.cp_contact_uuid WHERE f.cp_invain NOTNULL AND f.cp_invain == 1 UNION SELECT com.cp_contact_uuid FROM cp_company com LEFT OUTER JOIN  cp_family f ON f.cp_contact_uuid = com.cp_contact_uuid WHERE com.cp_invain NOTNULL AND com.cp_invain == 1)  AND c.cp_name LIKE ?" withArgumentsInArray:@[[NSString stringWithFormat:@"%%%@%%",searchString]]];
        self.contactsArray = [[CPDB getLKDBHelperByUser] executeResult:set Class:[CPContacts class]];
        [set close];
    }];
}
-(void) initContactsForSort{
    self.contactsForAlephSort = [NSMutableDictionary dictionary];
    
    // 首字母分组
    for (CPContacts* contact in self.contactsArray) {
        NSString* initial = [contact.cp_name aleph];
        NSMutableArray* array = [self.contactsForAlephSort objectForKey:initial];
        if (array) {
            [array addObject:contact];
        }else{
            NSMutableArray* arrayNew = [NSMutableArray array];
            [arrayNew addObject:contact];
            [self.contactsForAlephSort setObject:arrayNew forKey:initial];
        }
    }
    // 每组自然排序
    for (NSString* key in self.contactsForAlephSort) {
        NSMutableArray* array = self.contactsForAlephSort[key];
        [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[(CPContacts*)obj1 cp_name] compare:[(CPContacts*)obj2 cp_name]];
        }];
    }
    // key排序
    self.contactsForAlephSortKeys = [self.contactsForAlephSort.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
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
    if (self.showAround && !(!CPMemberLicense || CPMemberLicense<=[[NSDate date] timeIntervalSince1970])) {
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

-(void) updateRegion:(NSArray*)annotationArray{
    // 调整地图可视范围
    if (annotationArray.count == 1){
        [self.mapView setRegion:MACoordinateRegionMake([annotationArray[0] coordinate], MACoordinateSpanMake(0.01, 0.01)) animated:YES];
    } else{
        [self.mapView setVisibleMapRect:[CommonUtility minMapRectForAnnotations:annotationArray] edgePadding:UIEdgeInsetsMake(160, 60, 60, 60) animated:YES];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    self.searchDisplayController.searchResultsTableView.contentInset = UIEdgeInsetsZero;
}

#pragma mark - UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if (!searchString || [searchString isEqualToString:@""]) {
        return NO;
    }
    // 加载数据
    [self loadContactsWithSearchString:searchString];
    // 排序
    [self initContactsForSort];
    // 重载table
    [self.searchDisplayController.searchResultsTableView reloadData];
    return YES;
}

- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    controller.searchBar.text = controller.searchBar.text;
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
        [self updateUI];
    }
}

#pragma mark - UITableViewDataSource
// 多Sections
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.contactsForAlephSortKeys.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [(NSArray*)self.contactsForAlephSort[self.contactsForAlephSortKeys[section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell_contacts";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    NSString* aleph = self.contactsForAlephSortKeys[indexPath.section];
    CPContacts* contacts = self.contactsForAlephSort[aleph][indexPath.row];
    cell.textLabel.text = contacts.cp_name;
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.contactsForAlephSortKeys[section];
}
// 索引
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.contactsForAlephSortKeys;
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString* aleph = self.contactsForAlephSortKeys[indexPath.section];
    CPContacts* contracts = self.contactsForAlephSort[aleph][indexPath.row];
    
    // 清空大头针
    NSMutableArray* annotationForRemove = [@[] mutableCopy];
    for (id <MAAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
            [annotationForRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationForRemove];
    
    NSArray* array = [self findAnnotationByContacts:contracts];
    self.showAround = NO;
    [self.mapView addAnnotations:array];
    [self.mapView selectAnnotation:array.firstObject animated:NO];
    [self updateRegion:array];
    
    [self.searchDisplayController setActive:NO animated:YES];
    self.searchDisplayController.searchBar.text = contracts.cp_name;
}
@end
