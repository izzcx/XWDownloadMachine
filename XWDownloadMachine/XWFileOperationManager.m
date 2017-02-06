//
//  XWFileOperationManager.m
//  XWDownloadMachine
//
//  Created by xiaohesong on 2016/12/30.
//  Copyright © 2016年 XW. All rights reserved.
//

#import "XWFileOperationManager.h"

@interface XWFileOperationManager ()

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSMutableDictionary *downloadOperation;

@end

@implementation XWFileOperationManager

+ (instancetype)shareManager{
    static XWFileOperationManager *_instance ;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _downloadQueue = [[NSOperationQueue alloc]init];
        _downloadQueue.maxConcurrentOperationCount = 1;
        
    }
    return self;
}

- (void)addOperation:(NSOperation *)blockOperation withURL:(NSString *)url
{
    //do something.......顺序。。。
    [_downloadOperation addEntriesFromDictionary:@{url:blockOperation}];
    [_downloadQueue addOperation:blockOperation];
}

- (void)cacelOperation:(NSArray<NSString *>*)urls
{
    for (NSString *url in urls) {
        NSOperation *blockOperation = _downloadOperation[url];
        if (blockOperation) {
            [blockOperation cancel];
        }
    }
}

- (void)supuend
{
    [_downloadQueue setSuspended:YES];
}

- (void)start
{
    [_downloadQueue setSuspended:NO];
}

- (void)doWorkOnMainOperation:(void(^)())block
{
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)doAsycWorkOnglobalOperation:(void(^)())block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
}



@end
