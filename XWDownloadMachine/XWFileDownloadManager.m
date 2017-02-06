//
//  XWFileDownloadManager.m
//  XWDownloadMachine
//
//  Created by 肖贺松 on 2016/12/26.
//  Copyright © 2016年 XW. All rights reserved.
//

#import "XWFileDownloadManager.h"
#import "XWFileOperationManager.h"
#import "NSURLSession+XWCorrectResumeData.h"
#import <UIKit/UIKit.h>

static XWFileDownloadManager *_instance;

@interface XWFileDownloadManager ()<NSURLSessionDelegate,NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSession *backgroundSession;
@property (nonatomic, strong) NSMutableDictionary *downloadDic;
@property (nonatomic, strong) NSURL *resumeDataFilePath;

@end

@implementation XWFileDownloadManager

+(instancetype)shareInstance{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self instanceSession];
        _downloadDic = [[NSMutableDictionary alloc] init];
        _resumeDataFilePath = [[self cacheDirectoryPath] URLByAppendingPathComponent:@"xwresumeData.plist"];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appTerminate)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];

    }
    return self;
}

- (void)instanceSession
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    NSURLSessionConfiguration *backgroundConfiguration = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    }else{
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.xwmanagerchine.downloader"];
    }
    /*这个标志允许系统为分配任务进行性能优化。这意味着只有当设备有足够电量时，设备才通过Wifi进行数据传输。如果电量低，或者只仅有一个蜂窝连接，传输任务是不会运行的*/
    backgroundConfiguration.discretionary = NO;
    //session 
    self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    
}

- (void)DownloadFileForURL:(NSString *)url
                  fileName:(NSString *)fileName
                  progress:(progressBlock)progress
                  complete:(completeBlock)complete
            backgroundMode:(BOOL)backgroundMode
{
    if (!url) {
        return;
    }
    
    if (!fileName) {
        fileName = [url lastPathComponent];
    }
    
    if ([_downloadDic objectForKey:url]) {
        
        //do something
        [self reStartDownloaderForURL:url backgroundMode:(backgroundMode?_backgroundSession:_session)];
        
    }else{
        
        NSURLSessionDownloadTask *task;
        NSMutableURLRequest *request = [self downloadForRequest:url];
        if (backgroundMode) {
            task = [self.backgroundSession downloadTaskWithRequest:request];
        }else{
            task = [self.session downloadTaskWithRequest:request];
        }
        XWFileDownloader *downloader = [[XWFileDownloader alloc] initWithfileName:fileName DownloadTask:task downloadForURL:url progressBlock:progress completeBlock:complete];
        downloader.state = XWFileDownloaderState_Loading;
        [_downloadDic addEntriesFromDictionary:@{url:downloader}];
        
        __block NSURLSessionDownloadTask *bTask = task;
        [self downloadOperationTask:^{
            [bTask resume];
        } with:url];
    
    }
}

- (void)reStartDownloaderForURL:(NSString *)url backgroundMode:(NSURLSession *)session
{
    XWFileDownloader *downloader = [_downloadDic objectForKey:url];
    NSMutableDictionary *resumeDic = [[NSMutableDictionary alloc] initWithContentsOfURL:_resumeDataFilePath];
    NSData *resumeData = [resumeDic objectForKey:url];
    downloader.task = [self downloadTaskWithResumeData:resumeData session:(NSURLSession *)session];
    downloader.state = XWFileDownloaderState_Loading;
    __block NSURLSessionDownloadTask *bTask = (NSURLSessionDownloadTask *)downloader.task;
    [self downloadOperationTask:^{
        [bTask resume];
    } with:url];
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData session:(NSURLSession *)session
{
    NSURLSessionDownloadTask *task = nil;
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 10.0) {
        task = [session correctedDownloadTaskWithResumeData:resumeData];
    } else {
        task = [session downloadTaskWithResumeData:resumeData];
    }
    return task;
}


- (void)downloadOperationTask:(void(^)())block with:(NSString *)url
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
    [[XWFileOperationManager shareManager] addOperation:blockOperation withURL:url];
}

- (NSMutableURLRequest *)downloadForRequest:(NSString *)url
{
    NSURL *downloadURL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:downloadURL];
    [request setValue:@"" forHTTPHeaderField:@"user-agent"];
    [request setValue:@"" forHTTPHeaderField:@"Cookie"];
    [request setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    return request;
}

- (void)pauseDownloaderForUrls:(NSArray *)urls
{
    if (!urls.count) {
        return;
    }
    [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XWFileDownloader *downloader = [_downloadDic objectForKey:obj];
        NSURLSessionDownloadTask *task = (NSURLSessionDownloadTask *)downloader.task;
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [self saveData:resumeData withForURL:downloader.downloadURL];
            downloader.state = XWFileDownloaderState_Pause;
            //do something
        }];
    }];
}

- (void)cancelDownloaderForUrls:(NSArray *)urls
{
    [[XWFileOperationManager shareManager]cacelOperation:urls];
}

- (void)appTerminate
{
    NSArray<XWFileDownloader *> *downloaders = [_downloadDic allValues];
    [downloaders enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XWFileDownloader  *downloader = obj;
        if (downloader.state == XWFileDownloaderState_Loading) {
            __block XWFileDownloader *bDownloader = downloader;
            //do something ...... tmp data
            [[XWFileOperationManager shareManager] doAsycWorkOnglobalOperation:^{
                NSURLSessionDownloadTask *task = (NSURLSessionDownloadTask *)bDownloader.task;
                [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    [self saveData:resumeData withForURL:downloader.downloadURL];
                    downloader.state = XWFileDownloaderState_Pause;
                }];
            }];
        }
    }];

}


#pragma mark --- NSURlSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"totalbyreWritten is %lld,totalBytesExpectedToWrite is %lld",totalBytesWritten,totalBytesExpectedToWrite);
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    XWFileDownloader *downloader = [_downloadDic objectForKey:url];
    CGFloat progress = (CGFloat)totalBytesWritten/(CGFloat)totalBytesExpectedToWrite;
    if (downloader.progressBlock) {
        [[XWFileOperationManager shareManager] doWorkOnMainOperation:^{
            downloader.progressBlock(progress);
        }];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"do something.......");
}

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location
{
    NSError *error;
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    XWFileDownloader *downloader = [_downloadDic objectForKey:url];
    BOOL success = YES;
    if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)downloadTask.response statusCode];
        if (statusCode > 400) {
          NSLog(@"do something.......");
        }
    }
    if (success) {
        if (!downloader.filePath) {
           downloader.filePath = [[self cacheDirectoryPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@",downloader.fileName]];
        }
        [[NSFileManager defaultManager]moveItemAtURL:location toURL:downloader.filePath error:&error];
        if (!error) {
            downloader.state = XWFileDownloaderState_Finished;
            [_downloadDic setValue:nil forKey:url];
            if (downloader.completeBlock) {
                [[XWFileOperationManager shareManager] doWorkOnMainOperation:^{
                    downloader.completeBlock(YES);
                }];
            }
            
        }else{
            downloader.state = XWFileDownloaderState_Failed;
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSLog(@"ERROR: %@", error);
        
        NSString *url = task.originalRequest.URL.absoluteString;
        XWFileDownloader *downloader = [_downloadDic objectForKey:url];
        
        if (downloader.completeBlock) {
            [[XWFileOperationManager shareManager]doWorkOnMainOperation:^{
                downloader.completeBlock(NO);
                downloader.progressBlock(1);
            }];
            
        }
        [_downloadDic removeObjectForKey:url];
    }
}

#pragma mark - Background download

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
    //session....
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([downloadTasks count] == 0) {
            if (self.backgroundTransferCompletionHandler != nil) {
                void(^completionHandler)() = self.backgroundTransferCompletionHandler;
                completionHandler();
                self.backgroundTransferCompletionHandler = nil;
            }
        }
    }];
}


#pragma mark ----operation

- (void)doWorkOnMainOperation:(void(^)())block
{
    dispatch_async(dispatch_get_main_queue(), block);
}

#pragma file operation

- (NSURL *)cacheDirectoryPath
{
    NSString *paths = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    return [NSURL fileURLWithPath:paths];
}

- (void)saveData:(NSData * _Nullable)data withForURL:(NSString *)url
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithContentsOfURL:_resumeDataFilePath];
    if (!dic) {
        dic = [[NSMutableDictionary alloc] init];
    }
    [dic addEntriesFromDictionary:@{url:data}];
    
    [dic writeToURL:_resumeDataFilePath atomically:NO];
}

- (void)deleteDownloaderFileFor:(NSArray *)urls
{
    [self deleteDownloaderFileFor:urls withFileName:nil];
   
}

- (void)deleteDownloaderFileFor:(NSArray *)urls withFileName:(NSString *)fileName
{
    NSError *error;
   
    NSURL *fileLocation = [[self cacheDirectoryPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]];
        
    
    // Move downloaded item from tmp directory to te caches directory
    // (not synced with user's iCloud documents)
    [[NSFileManager defaultManager] removeItemAtURL:fileLocation error:&error];
    
    if (error) {
        NSLog(@"Error deleting file: %@", error);
    } else {
        NSLog(@"do something .....");
    }

}


@end
