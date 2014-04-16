//
//  CPMapUtil.m
//  Code Prometheus
//
//  Created by mirror on 13-12-6.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPMapUtil.h"

NSString* CP_MAP_UTIL_CITY = @"";
CLLocation* CP_MAP_UTIL_LOCATION = nil;
@interface AMapSearchAPIDelegate : NSObject<AMapSearchDelegate>
@end
@implementation AMapSearchAPIDelegate
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response{
    if (response.regeocode != nil){
        CP_MAP_UTIL_LOCATION = [[CLLocation alloc] initWithLatitude:request.location.latitude longitude:request.location.longitude];
        NSString* city = response.regeocode.addressComponent.city;
        NSString* province = response.regeocode.addressComponent.province;
        CP_MAP_UTIL_CITY = city && ![city isEqualToString:@""] ? city : province;
        CPLogWarn(@"定位城市:%@,坐标:%@",CP_MAP_UTIL_CITY,CP_MAP_UTIL_LOCATION);
    }
}
@end

@implementation CPMapUtil
+ (MAMapView *)sharedMapView
{
    static dispatch_once_t once;
    static MAMapView* instance;
    dispatch_once(&once, ^{
        instance = MAMapView.new;
        instance.rotateEnabled = NO;
        instance.rotateCameraEnabled = NO;
//        instance.showsCompass = YES;
//        instance.compassOrigin = CGPointMake(320, 0);
//        instance.showsScale = YES;
//        instance.scaleOrigin = CGPointMake(0, 0);
    });
    return instance;
}

+ (AMapSearchAPI *)sharedMapSearchAPI
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = [[AMapSearchAPI alloc] initWithSearchKey:[MAMapServices sharedServices].apiKey Delegate:nil];});
    return instance;
}

+(void) updateCityAndLocation:(MAUserLocation*) userLocation{
    static dispatch_once_t once2;
    static AMapSearchAPIDelegate* delegate;
    dispatch_once(&once2, ^{delegate = [[AMapSearchAPIDelegate alloc] init];});
    
    static dispatch_once_t once;
    static AMapSearchAPI* search;
    dispatch_once(&once, ^{search = [[AMapSearchAPI alloc] initWithSearchKey:[MAMapServices sharedServices].apiKey Delegate:delegate];});
    
    CLLocationCoordinate2D coordinate = userLocation.location.coordinate;
    if (!CP_MAP_UTIL_LOCATION || !CP_MAP_UTIL_CITY || fabs(CP_MAP_UTIL_LOCATION.coordinate.latitude-coordinate.latitude)>1 || fabs(CP_MAP_UTIL_LOCATION.coordinate.longitude-coordinate.longitude)>1) {
        //  重新定位城市
        CPLogWarn(@"重新定位城市,现在的城市:%@,坐标:%@",CP_MAP_UTIL_CITY,CP_MAP_UTIL_LOCATION);
        AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
        regeo.location = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        [search AMapReGoecodeSearch:regeo];
    }
}
@end
