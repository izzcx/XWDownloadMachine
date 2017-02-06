//
//  XWFileDownloadManager.h
//  XWDownloadMachine
//
//  Created by 肖贺松 on 2016/12/26.
//  Copyright © 2016年 XW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XWFileDownloader.h"


@interface XWFileDownloadManager : NSObject

@property (nonatomic, strong) void(^backgroundTransferCompletionHandler)();

+(instancetype)shareInstance;

- (void)DownloadFileForURL:(NSString *)url
                  fileName:(NSString *)fileName
                  progress:(progressBlock)progress
                  complete:(completeBlock)complete
            backgroundMode:(BOOL)backgroundMode;


- (void)pauseDownloaderForUrls:(NSArray *)urls;

- (void)cancelDownloaderForUrls:(NSArray *)urls;

- (void)deleteDownloaderFileFor:(NSArray *)urls;

- (void)deleteDownloaderFileFor:(NSArray *)urls withFileName:(NSString *)fileName;

@end
