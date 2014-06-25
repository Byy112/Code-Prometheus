//
//  CPBaseModel.m
//  Code Prometheus
//
//  Created by mirror on 13-9-16.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPBaseModel.h"
#import "JSONKit.h"

NSString *const CP_ENTITY_OPERATION_KEY = @"CP_ENTITY_OPERATION_KEY";

@implementation CPBaseModel

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToWidget:other];
}

- (BOOL)isEqualToWidget:(CPBaseModel *)aWidget {
    if (self == aWidget)
        return YES;
    if (![[self valueForKey:@"cp_uuid"] isEqual:[aWidget valueForKey:@"cp_uuid"]])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash += [[self valueForKey:@"cp_uuid"] hash];
    return hash;
}

#pragma mark - public
// 创建操作数据库的实体类
+(instancetype) newAdaptDB{
    CPBaseModel* object = [[self class] new];
    [object setValue:@([CPServer getServerTimeByDelta_t]) forKey:@"cp_timestamp"];
    [object setValue:[[NSUUID UUID]UUIDString] forKey:@"cp_uuid"];
    return object;
}

#pragma mark - private

//-(NSString*)propertyKeyValue{
//    NSObject* entity = self;
//    LKModelInfos* infos = [[entity class] getModelInfos];
//    NSMutableString* data = [NSMutableString stringWithCapacity:infos.count*20];
//    [data appendString:@"{"];
//    for (int i=0; i<infos.count; i++) {
//        LKDBProperty* property = [infos objectWithIndex:i];
//        id value = [self modelValueWithProperty:property model:entity];
//        if (!value || value==[NSNull null]) {
//            value = @"";
//        }
//        [data appendFormat:@"\"%@\":\"%@\",",property.sqlColumeName,value];
//    }
//    [data replaceCharactersInRange:NSMakeRange(data.length-1, 1) withString:@"}"];
//    return data;
//}

-(NSString*)propertyKeyValue{
    NSObject* entity = self;
    LKModelInfos* infos = [[entity class] getModelInfos];
    NSMutableDictionary* kv = [NSMutableDictionary dictionary];
    for (int i=0; i<infos.count; i++) {
        LKDBProperty* property = [infos objectWithIndex:i];
        id value = [self modelValueWithProperty:property model:entity];
        if (!value) {
            value = [NSNull null];
        }
        [kv setObject:value forKey:property.sqlColumeName];
    }
    return [kv JSONString];
}

-(id)modelValueWithProperty:(LKDBProperty *)property model:(NSObject *)model {
    id value = nil;
    if(property.isUserCalculate)
    {
        value = [model userGetValueForModel:property];
    }
    else
    {
        value = [self modelGetValue:property WithObj:model];
    }
    if(value == nil)
    {
        value = @"";
    }
    return value;
}

-(id)modelGetValue:(LKDBProperty *)property WithObj:(NSObject*)obj
{
    id value = [obj valueForKey:property.propertyName];
    id returnValue = nil;
    if(value == nil)
    {
        //        returnValue = @"";
#warning OK BUG (已修复)
        returnValue = [NSNull null];
    }
    else if([value isKindOfClass:[NSString class]])
    {
        returnValue = value;
    }
    else if([value isKindOfClass:[NSNumber class]])
    {
        returnValue = value;
    }
    else if([value isKindOfClass:[NSDate class]])
    {
        returnValue = [LKDBUtils stringWithDate:value];
    }
    else if([value isKindOfClass:[UIColor class]])
    {
        UIColor* color = value;
        float r,g,b,a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        returnValue = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f",r,g,b,a];
    }
    else if([value isKindOfClass:[NSValue class]])
    {
        NSString* columeType = property.propertyType;
        if([columeType isEqualToString:@"CGRect"])
        {
            returnValue = NSStringFromCGRect([value CGRectValue]);
        }
        else if([columeType isEqualToString:@"CGPoint"])
        {
            returnValue = NSStringFromCGPoint([value CGPointValue]);
        }
        else if([columeType isEqualToString:@"CGSize"])
        {
            returnValue = NSStringFromCGSize([value CGSizeValue]);
        }
    }
    else if([value isKindOfClass:[UIImage class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"img%ld%ld",date&0xFFFFF,random&0xFFF];
        
        NSData* datas = UIImageJPEGRepresentation(value, 1);
        [datas writeToFile:[obj.class getDBImagePathWithName:filename] atomically:YES];
        
        returnValue = filename;
    }
    else if([value isKindOfClass:[NSData class]])
    {
        long random = arc4random();
        long date = [[NSDate date] timeIntervalSince1970];
        NSString* filename = [NSString stringWithFormat:@"data%ld%ld",date&0xFFFFF,random&0xFFF];
        
        [value writeToFile:[obj.class getDBDataPathWithName:filename] atomically:YES];
        
        returnValue = filename;
    }
    if(returnValue == nil)
        returnValue = @"";
    
    return returnValue;
}

#pragma mark - LKDBHelper
+(void)dbDidIDeleted:(NSObject *)entity result:(BOOL)result{
    // 生成操作队列
    [CPServer notifyDeleteEntity:entity];
    // 通知
    [[NSNotificationCenter defaultCenter] postNotificationName:NSStringFromClass([entity class]) object:entity userInfo:@{CP_ENTITY_OPERATION_KEY:@(CP_ENTITY_OPERATION_DELETE)}];
}

+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result{
    // 生成操作队列
    [CPServer notifyReplaceEntity:entity];
    // 通知
    [[NSNotificationCenter defaultCenter] postNotificationName:NSStringFromClass([entity class]) object:entity userInfo:@{CP_ENTITY_OPERATION_KEY:@(CP_ENTITY_OPERATION_ADD)}];
}
+(void)dbDidUpdated:(NSObject *)entity result:(BOOL)result{
    // 生成操作队列
    [CPServer notifyReplaceEntity:entity];
    // 通知
    [[NSNotificationCenter defaultCenter] postNotificationName:NSStringFromClass([entity class]) object:entity userInfo:@{CP_ENTITY_OPERATION_KEY:@(CP_ENTITY_OPERATION_UPDATE)}];
}

// 表名
+(NSString *)getTableName
{
    return NSStringFromClass(self);
}
// 主键
+(NSString *)getPrimaryKey
{
    return @"cp_uuid";
}

#pragma mark - SYNC
+(NSString*) syncOperationDBName{
    NSString* userName = CPUserName;
    if (userName) {
        return userName;
    }else{
        return (NSString*)OFF_LINE_DB_Name;
    }
}
+(NSString*) syncOperationTBName{
    return [self getTableName];
}
-(NSString*) syncOperationUUID{
    return [self valueForKey:@"cp_uuid"];
}
-(NSTimeInterval) syncOperationTimestamp{
    return [[self valueForKey:@"cp_timestamp"] doubleValue];
}
+(NSString*) syncOperationPrimaryKey{
    return @"cp_uuid";
}
-(NSString*) syncDataContent{
    return [self propertyKeyValue];
}
@end
