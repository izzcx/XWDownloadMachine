//
//  NSURLSession+XWCorrectResumeData.h
//  XWDownloadMachine
//
//  Created by xiaohesong on 2017/1/3.
//  Copyright © 2017年 XW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (XWCorrectResumeData)

- (NSURLSessionDownloadTask *)correctedDownloadTaskWithResumeData:(NSData *)resumeData;

@end
