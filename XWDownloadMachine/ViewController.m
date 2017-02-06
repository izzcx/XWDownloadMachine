//
//  ViewController.m
//  XWDownloadMachine
//
//  Created by 肖贺松 on 2016/12/26.
//  Copyright © 2016年 XW. All rights reserved.
//

#import "ViewController.h"
#import "XWFileDownloadManager.h"


 NSString const *url = @"http://play.g3proxy.lecloud.com/vod/v2/MjIyLzM3LzQ5L2xldHYtdXRzLzIwL3Zlcl8wMF8yMi0xMDY3OTkyODk0LWF2Yy00MTkzNjQtYWFjLTMyMDAwLTExODUyNDAtNjgxNzI3NDctMmRkYWE3MTlhZmUxZmRkMDQzNTFiYTM4OGRhOTYyMzItMTQ3NjQxNDk1Njc3NC5tcDQ=?b=460068&mmsid=107736403&key=07fe08e1936560b47904c7093f928980&tm=1483713136&platid=14&splatid=1408&playid=2&tss=no&payff=0&pip=e0adba53fe424e0030d857c8d2255b2a&cvid=0&vtype=13&fcode=lhYFookVrZBonFxnKoSYVOJLDzSn4VCOxaQg4R%2FxU%2FcqTKPSWgry9VjNVL4TSxleNZ9poD8vW2lEDqpBmSEFycd%2FtrjUItNwdtdks3RQrCM%3D&fcodever=1";

@interface ViewController ()

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIButton *pauseBtn;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UIButton *deletBtn;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(100, 200, 200, 20);
    [self.view addSubview:self.progressView];
    
    
    self.pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.pauseBtn.frame = CGRectMake(100, 250, 80, 40);
    [self.pauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
    [self.pauseBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.pauseBtn addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pauseBtn];
    
    self.startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startBtn.frame = CGRectMake(100, 300, 80, 40);
    [self.startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [self.startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.startBtn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startBtn];
    
    self.deletBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deletBtn.frame = CGRectMake(100, 360, 80, 40);
    [self.deletBtn setTitle:@"删除文件" forState:UIControlStateNormal];
    [self.deletBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.deletBtn addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deletBtn];

}

- (void)pause
{
    [[XWFileDownloadManager shareInstance]pauseDownloaderForUrls:@[url]];
}

- (void)start
{
   
    __weak typeof(self) wself = self;
    [[XWFileDownloadManager shareInstance]DownloadFileForURL:url fileName:@"电影" progress:^(CGFloat progress) {
        __strong typeof(self) sself = wself;
        sself.progressView.progress = progress;
        
    } complete:^(BOOL complete) {
        
    } backgroundMode:YES];
}

- (void)delete
{
    self.progressView.progress = 0.0f;
    [[XWFileDownloadManager shareInstance] deleteDownloaderFileFor:nil withFileName:@"电影"];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
