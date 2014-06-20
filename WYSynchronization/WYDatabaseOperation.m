//
//  WYDatabaseOperation.m
//  Code Prometheus
//
//  Created by mirror on 13-9-9.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "WYDatabaseOperation.h"
#import "LKDBHelper.h"

@implementation WYDatabaseOperation

//主键
+(NSString *)getPrimaryKey
{
    return @"wy_uuid";
}

//表名
+(NSString *)getTableName
{
    return NSStringFromClass(self);
}

-(NSString *)description{
    NSString* superStr = [super description];
    NSString* myStr = [NSString stringWithFormat:@"wy_uuid->%@,wy_dbName->%@,wy_tbName->%@,wy_primary_key->%@,wy_data->%@,wy_timestamp->%f,wy_operation->%d",self.wy_uuid,self.wy_dbName,self.wy_tbName,self.wy_primary_key,self.wy_data,self.wy_timestamp,self.wy_operation];
    return [NSString stringWithFormat:@"%@ , %@",superStr,myStr];
}
@end


@implementation NSObject (Operation)

+(NSString*) syncOperationDBName{
    return @"";
}
+(NSString*) syncOperationTBName{
    return @"";
}
-(NSString*) syncOperationUUID{
    return @"";
}
-(NSTimeInterval) syncOperationTimestamp{
    return 0.0;
}
+(NSString*) syncOperationPrimaryKey{
    return @"";
}
-(NSString*) syncDataContent{
    return @"";
}
@end