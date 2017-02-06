//
//  XWFileDownloader.h
//  XWDownloadMachine
//
//  Created by 肖贺松 on 2016/12/26.
//  Copyright © 2016年 XW. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

typedef NS_ENUM(NSInteger, XWFileDownloaderState) {
    XWFileDownloaderState_NA,
    XWFileDownloaderState_Pause,
    XWFileDownloaderState_Failed,
    XWFileDownloaderState_Loading,
    XWFileDownloaderState_Finished
};

typedef void(^progressBlock)(CGFloat progress);
typedef void(^completeBlock)(BOOL complete);


@interface XWFileDownloader : NSObject

@property (nonatomic, copy) NSURL *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, assign) XWFileDownloaderState state;
@property (nonatomic, copy, readonly) NSString *downloadFilePath;
@property (nonatomic, copy) progressBlock progressBlock;
@property (nonatomic, copy) completeBlock completeBlock;

- (instancetype)initWithfileName:(NSString *)fileName
                    DownloadTask:(NSURLSessionTask *)task
                  downloadForURL:(NSString *)downloadURL
                   progressBlock:(progressBlock)progressBlock
                   completeBlock:(completeBlock)completeBlock;


@end
