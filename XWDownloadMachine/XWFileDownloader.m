//
//  XWFileDownloader.m
//  XWDownloadMachine
//
//  Created by 肖贺松 on 2016/12/26.
//  Copyright © 2016年 XW. All rights reserved.
//

#import "XWFileDownloader.h"

@implementation XWFileDownloader

- (instancetype)initWithfileName:(NSString *)fileName
                    DownloadTask:(NSURLSessionTask *)task
                  downloadForURL:(NSString *)downloadURL
                   progressBlock:(progressBlock)progressBlock
                   completeBlock:(completeBlock)completeBlock{
    self = [super init];
    if (self) {
        _task = task;
        _fileName = [fileName copy];
        _downloadURL = [downloadURL copy];
        _progressBlock = progressBlock;
        _completeBlock = completeBlock;
    }
    return self;

}

@end
