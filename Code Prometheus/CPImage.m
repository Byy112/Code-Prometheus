//
//  CPImage.m
//  Code Prometheus
//
//  Created by mirror on 13-12-3.
//  Copyright (c) 2013年 Mirror. All rights reserved.
//

#import "CPImage.h"
#import <SDImageCache.h>
#import <UIImageView+WebCache.h>
#import <UIButton+WebCache.h>

@implementation CPImage{
    UIImage* _image;
}
+(void)initialize
{
    [super initialize];
    @synchronized(self) {
	}
    [self removePropertyWithColumeName:@"image"];
}
-(void)setImage:(UIImage *)image{
    _image = image;
}
-(UIImage *)image{
    if (!_image) {
        @synchronized(self){
            if (!_image) {
                if (self.cp_url) {
                    _image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[NSString stringWithFormat:@"%@%@",URL_SERVER_ROOT,self.cp_url]];
                }
                if (!_image) {
                    _image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:self.cp_uuid];
                }
            }
        }
    }
    return _image;
}

#pragma mark - LKDBHelper
// 表名
+(NSString *)getTableName
{
    return @"cp_file";
}

+(void)dbDidIDeleted:(NSObject *)entity result:(BOOL)result{
    [super dbDidIDeleted:entity result:result];
    CPImage* cpimage = (CPImage*)entity;
    CPLogInfo(@"删除文件缓存, uuid:%@",cpimage.cp_uuid);
    [[SDImageCache sharedImageCache] removeImageForKey:cpimage.cp_uuid];
    if (cpimage.cp_url) {
        // 若此图片在数据库中无引用,则从硬盘删除
        int count = [[CPDB getLKDBHelperByUser] rowCount:[CPImage class] where:@{@"cp_url":cpimage.cp_url}];
        if (count == 0) {
            NSString* urlStr = [NSString stringWithFormat:@"%@%@",URL_SERVER_ROOT,cpimage.cp_url];
            CPLogInfo(@"删除文件缓存 url:%@",urlStr);
            [[SDImageCache sharedImageCache] removeImageForKey:urlStr];
        }else{
            CPLogWarn(@"此文件 url = %@ ，有%d 条 记录与之对应，不删除缓存",cpimage.cp_url,count);
        }
    }else{
        CPLogWarn(@"此文件只有 uuid = %@，不存在url!无法删除以urk为key的缓存!",cpimage.cp_uuid);
    }
}
+(void)dbDidInserted:(NSObject *)entity result:(BOOL)result{
    [super dbDidInserted:entity result:result];
    CPImage* cpimage = (CPImage*)entity;
    if (cpimage.image) {
        if (cpimage.cp_url) {
            [[SDImageCache sharedImageCache] storeImage:cpimage.image forKey:[NSString stringWithFormat:@"%@%@",URL_SERVER_ROOT,cpimage.cp_url]];
        }else{
            [[SDImageCache sharedImageCache] storeImage:cpimage.image forKey:cpimage.cp_uuid];
        }
    }
}
+(void)dbWillUpdate:(NSObject *)entity{
    @throw [NSException exceptionWithName:@"不建议更新 CPImage" reason:@"更新CPImage,其对应的图片文件可能不能清除!" userInfo:nil];
}
@end


@implementation UIImageView (CPImage)

-(void)setImageWithCPImage:(CPImage*)image{
    UIImage* ima = image.image;
    if (ima) {
        self.image = ima;
    }else{
        if (image.cp_url && ![image.cp_url isEqualToString:@""]) {
            CPLogWarn(@"图片本地不存在,需要网上下载。url:%@",image.cp_url);
            [self setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",URL_SERVER_ROOT,image.cp_url]] placeholderImage:nil options:SDWebImageRetryFailed|SDWebImageProgressiveDownload|SDWebImageRefreshCached|SDWebImageContinueInBackground];
        }else{
            CPLogWarn(@"图片无url,并且本地找不到文件! uuid:%@",image.cp_uuid);
            self.image = [UIImage imageNamed:@"cp_null_photo"];
        }
    }
}

@end

@implementation UIButton (CPImage)
-(void)setImageWithCPImage:(CPImage*)image{
    UIImage* ima = image.image;
    if (ima) {
        [self setImage:ima forState:UIControlStateNormal];
    }else{
        if (image.cp_url && ![image.cp_url isEqualToString:@""]) {
            CPLogWarn(@"图片本地不存在,需要网上下载。url:%@",image.cp_url);
            [self setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",URL_SERVER_ROOT,image.cp_url]] forState:UIControlStateNormal placeholderImage:nil options:SDWebImageRetryFailed|SDWebImageProgressiveDownload|SDWebImageRefreshCached|SDWebImageContinueInBackground];
        }else{
            CPLogWarn(@"图片无url,并且本地找不到文件! uuid:%@",image.cp_uuid);
            [self setImage:[UIImage imageNamed:@"cp_null_photo"] forState:UIControlStateNormal];
        }
    }
}

@end
