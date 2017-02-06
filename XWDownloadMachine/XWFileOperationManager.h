//
//  XWFileOperationManager.h
//  XWDownloadMachine
//
//  Created by xiaohesong on 2016/12/30.
//  Copyright © 2016年 XW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XWFileOperationManager : NSObject

+ (instancetype)shareManager;

- (void)addOperation:(NSOperation *)blockOperation withURL:(NSString *)url;

- (void)cacelOperation:(NSArray<NSString *>*)urls;

- (void)supuend;

- (void)start;

- (void)doWorkOnMainOperation:(void(^)())block;

- (void)doAsycWorkOnglobalOperation:(void(^)())block;

@end
