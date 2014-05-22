//
//  CPLocalNotificationManager.m
//  Code Prometheus
//
//  Created by 管理员 on 14-5-21.
//  Copyright (c) 2014年 Mirror. All rights reserved.
//

#import "CPLocalNotificationManager.h"
#import "CPPolicy.h"
#import <DateTools.h>


#define CP_ADVANCE_DAYS 7


#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]


@implementation NSDate (CP_PRIVATE)

- (BOOL) isEqualToDateIgnoringTime: (NSDate *) aDate
{
	NSDateComponents *components1 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:aDate];
	return (([components1 year] == [components2 year]) &&
			([components1 month] == [components2 month]) &&
			([components1 day] == [components2 day]));
}

- (NSDate *) dateAtStartOfDay
{
	NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	[components setHour:0];
	[components setMinute:0];
	[components setSecond:0];
	return [CURRENT_CALENDAR dateFromComponents:components];
}

- (NSDate *)dateBySubtractingDaysMy:(NSInteger)days{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:-1*days];
    
    return [calendar dateByAddingComponents:components toDate:self options:0];
}
@end

@implementation CPLocalNotificationManager
+ (instancetype) shared {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

-(void) fire{
    static NSDateFormatter *dateFormatter1 = nil;
    if (!dateFormatter1) {
        dateFormatter1 = [[NSDateFormatter alloc] init];
        [dateFormatter1 setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    //发送通知
    if ([UIApplication sharedApplication].scheduledLocalNotifications.count!=0) {
        return;
    }
    // 获取提醒数据
    NSDictionary* policyDateDic = [self getPolicyDateDic];
    NSArray* keys = [policyDateDic allKeys];
    for (NSDate* key in keys) {
        NSArray* policyList = policyDateDic[key];
        UILocalNotification *notification=[[UILocalNotification alloc] init];

        // 提醒日 中午12点
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setYear:key.year];
        [components setMonth:key.month];
        [components setDay:key.day];
        [components setHour:12];
        [components setMinute:0];
        [components setSecond:0];
        NSDate* date = [calendar dateFromComponents:components];
        // 提醒的时间
        notification.fireDate = [date dateBySubtractingDaysMy:CP_ADVANCE_DAYS];
        notification.repeatInterval = 0;//循环次数，kCFCalendarUnitWeekday一周一次
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.applicationIconBadgeNumber = policyList.count; //应用的红色数字
        notification.soundName= UILocalNotificationDefaultSoundName;//声音，可以换成alarm.soundName = @"myMusic.caf"
        //去掉下面2行就不会弹出提示框
        NSMutableString* name = [NSMutableString string];
        for (CPPolicy* policy in policyList) {
            [name appendFormat:@"%@,",policy.cp_name];
        }
        if (![name isEqualToString:@""]) {
            NSRange range;
            range.location = name.length-1;
            range.length = 1;
            [name deleteCharactersInRange:range];
        }
        notification.alertBody = [NSString stringWithFormat:@"%d天后%@...这些保单该缴费啦,提醒下他吧!",CP_ADVANCE_DAYS,name];//提示信息 弹出提示框
        notification.alertAction = @"打开";  //提示框按钮
        //notification.hasAction = NO; //是否显示额外的按钮，为no时alertAction消失
        
        // NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
        //notification.userInfo = infoDict; //添加额外的信息
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    static NSDateFormatter* df = nil;
    if (!df) {
        df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"yyyy年MM月dd日hh点mm分ss秒";
    }
    for (UILocalNotification* ln in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        CPLogInfo(@"创建本地通知队列 日期:%@,内容:%@",[df stringFromDate:ln.fireDate],ln.alertBody);
    }
}
-(void) down{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}


#pragma mark - private
-(NSMutableDictionary*)getPolicyDateDic{
    NSMutableDictionary* policyDateDic = [NSMutableDictionary dictionary];
    
    NSDate* now = [NSDate date];
    // 加载保单信息！
    NSString* where = [NSString stringWithFormat:@"cp_date_end > %f",[[[now dateByAddingDays:1 + CP_ADVANCE_DAYS] dateAtStartOfDay] timeIntervalSince1970]-1];
    
    NSMutableArray *array = [[CPDB getLKDBHelperByUser] search:[CPPolicy class] where:where orderBy:nil offset:0 count:-1];
    
    for (CPPolicy* policy in array) {
        NSDate* remindDate = [self remindDateWithPolicy:policy now:now];
        if (!remindDate) {
            continue;
        }
        if (!policyDateDic[remindDate]) {
            policyDateDic[remindDate] = [NSMutableArray array];
        }
        [(NSMutableArray*)policyDateDic[remindDate] addObject:policy];
    }
    return policyDateDic;
}

-(NSDate*) remindDateWithPolicy:(CPPolicy*)policy now:(NSDate*)now{
    if (!policy.cp_date_begin || !policy.cp_date_end || !policy.cp_pay_type) {
        return nil;
    }

    NSDate* beginDate = [[NSDate alloc] initWithTimeIntervalSince1970:policy.cp_date_begin.doubleValue];
    NSDate* endDate = [[NSDate alloc] initWithTimeIntervalSince1970:policy.cp_date_end.doubleValue];
    
    if ([now isEqualToDateIgnoringTime:endDate] || [now isLaterThan:endDate]) {
        CPLogWarn(@"保单没有提醒日期！beginDate:%@,endDate:%@,now:%@",beginDate,endDate,now);
        return nil;
    }
    
    NSDate* remindDate = nil;
    NSInteger n = 1;
    while (YES) {
        switch (policy.cp_pay_type.integerValue) {
            case 0:
                remindDate = [beginDate dateByAddingMonths:n];
                break;
            case 1:
                remindDate = [beginDate dateByAddingMonths:3*n];
                break;
            case 2:
                remindDate = [beginDate dateByAddingYears:n];
                break;
            default:
                break;
        }
        if ([remindDate isEqualToDateIgnoringTime:endDate] || [remindDate isLaterThan:endDate]) {
            break;
        }
        if ([remindDate isEqualToDateIgnoringTime:now] || [remindDate isLaterThan:now]) {
            return [remindDate dateAtStartOfDay];
        }
        n++;
    }
    return nil;
}
@end
