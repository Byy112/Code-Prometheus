//
//  CPUserDefaults.m
//  Code Prometheus
//
//  Created by mirror on 13-11-21.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPUserDefaults.h"

@implementation CPUserDefaults
+ (void)resetDefaults {
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        if ([key isEqualToString:CPUserNameKey] ||
            [key isEqualToString:CPPasswordKey] ||
            [key isEqualToString:CPSafetyPhoneNumberKey] ||
            [key isEqualToString:CPSafetyEmailKey] ||
            [key isEqualToString:CPMemberNameKey] ||
            [key isEqualToString:CPProductIdKey] ||
            [key isEqualToString:CPMemberPriceKey] ||
            [key isEqualToString:CPMemberRoomKey] ||
            [key isEqualToString:CPMemberTimeKey] ||
            [key isEqualToString:CPMemberUsageKey] ||
            [key isEqualToString:CPMemberUsePercentKey] ||
            [key isEqualToString:CPMemberLeftRoomKey] ||
            [key isEqualToString:CPMemberBalanceKey] ||
            [key isEqualToString:CPMemberLicenseKey]) {
            [defs removeObjectForKey:key];
        }
    }
    [defs synchronize];
}
@end
