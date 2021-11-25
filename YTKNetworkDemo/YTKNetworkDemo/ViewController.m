//
//  ViewController.m
//  YTKNetworkDemo
//
//  Created by Chenyu Lan on 10/28/14.
//  Copyright (c) 2014 yuantiku.com. All rights reserved.
//

#import "ViewController.h"
#import "YTKBatchRequest.h"
#import "YTKChainRequest.h"
#import "GetImageApi.h"
#import "GetUserInfoApi.h"
#import "RegisterApi.h"
#import "YTKBaseRequest+AnimatingAccessory.h"

#import "AYNetwork.h"

@interface ViewController ()<YTKChainRequestDelegate>

@end

@implementation ViewController

/// Send batch request
- (void)sendBatchRequest {
    GetImageApi *a = [[GetImageApi alloc] initWithImageId:@"1.jpg"];
    GetImageApi *b = [[GetImageApi alloc] initWithImageId:@"2.jpg"];
    GetImageApi *c = [[GetImageApi alloc] initWithImageId:@"3.jpg"];
    GetUserInfoApi *d = [[GetUserInfoApi alloc] initWithUserId:@"123"];
    YTKBatchRequest *batchRequest = [[YTKBatchRequest alloc] initWithRequestArray:@[a, b, c, d]];
    [batchRequest startWithCompletionBlockWithSuccess:^(YTKBatchRequest *batchRequest) {
        NSLog(@"succeed");
        NSArray *requests = batchRequest.requestArray;
        GetImageApi *a = (GetImageApi *)requests[0];
        GetImageApi *b = (GetImageApi *)requests[1];
        GetImageApi *c = (GetImageApi *)requests[2];
        GetUserInfoApi *user = (GetUserInfoApi *)requests[3];
        // deal with requests result ...
        NSLog(@"%@, %@, %@, %@", a, b, c, user);
    } failure:^(YTKBatchRequest *batchRequest) {
        NSLog(@"failed");
    }];
}

- (void)sendChainRequest {
    RegisterApi *reg = [[RegisterApi alloc] initWithUsername:@"username" password:@"password"];
    YTKChainRequest *chainReq = [[YTKChainRequest alloc] init];
    [chainReq addRequest:reg callback:^(YTKChainRequest *chainRequest, YTKBaseRequest *baseRequest) {
        RegisterApi *result = (RegisterApi *)baseRequest;
        NSString *userId = [result userId];
        GetUserInfoApi *api = [[GetUserInfoApi alloc] initWithUserId:userId];
        [chainRequest addRequest:api callback:nil];
        
    }];
    chainReq.delegate = self;
    // start to send request
    [chainReq start];
}

- (void)chainRequestFinished:(YTKChainRequest *)chainRequest {
    // all requests are done
    
}

- (void)chainRequestFailed:(YTKChainRequest *)chainRequest failedBaseRequest:(YTKBaseRequest*)request {
    // some one of request is failed
}

- (void)loadCacheData {
    NSString *userId = @"1";
    GetUserInfoApi *api = [[GetUserInfoApi alloc] initWithUserId:userId];
    if ([api loadCacheWithError:nil]) {
        NSDictionary *json = [api responseJSONObject];
        NSLog(@"json = %@", json);
        // show cached data
    }

    api.animatingText = @"正在加载";
    api.animatingView = self.view;

    [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        NSLog(@"update ui");
    } failure:^(YTKBaseRequest *request) {
        NSLog(@"failed");
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* POST
    AYRequest *request = [[AYRequest alloc] initWithUrl:@"https://itunes.apple.com/cn/lookup?id=670910957" parameters:nil method:AYRequestMethodPOST];
    [request startWithCompletionBlockWithSuccess:^(__kindof AYRequest * _Nonnull request) {
        NSDictionary *data = request.responseObject;
//        NSLog(@"data = %@", data);
        NSDictionary *info = [data[@"results"] firstObject];
        NSString *appStoreVersion = info[@"version"];
        if ([@"1.0.0" compare:appStoreVersion options:NSNumericSearch] == NSOrderedAscending) {  //有新版本

            NSLog(@"有新版本");
        }
    } failure:^(__kindof AYRequest * _Nonnull request) {
        ;
    }];
    // */
    
    AYRequest *downloadRequest = [[AYRequest alloc] initWithMethod:AYRequestMethodGET url:@"https://www.mediaatelier.com/CheatSheet/CheatSheet_1.2.9.zip" parameters:nil];
    downloadRequest.timeoutInterval = 60;
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"Download/CheatSheet"];

    downloadRequest.downloadDirectoryPath = filePath;
    
    downloadRequest.downloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"progress = %.2f%%", (double)progress.completedUnitCount * 100.0 / (double)progress.totalUnitCount);
    };
    
    downloadRequest.successCompletionBlock = ^(__kindof AYRequest * _Nonnull request) {
        NSLog(@"%@下载完成", request.requestUrl);
    };
    
    downloadRequest.failureCompletionBlock = ^(__kindof AYRequest * _Nonnull request) {
        NSLog(@"%@下载失败", request.requestUrl);
    };
    
//    [downloadRequest startWithCompletionBlockWithSuccess:^(__kindof AYRequest * _Nonnull request) {
//        NSLog(@"%@下载完成", request.requestUrl);
//    } failure:^(__kindof AYRequest * _Nonnull request) {
//        NSLog(@"%@下载失败", request.requestUrl);
//    }];
    
    //* DOWNLOAD
    AYRequest *downloadRequest0 = [[AYRequest alloc] initWithMethod:AYRequestMethodGET url:@"https://www.mediaatelier.com/CheatSheet/CheatSheet_1.6.0.1.zip" parameters:nil];

    downloadRequest0.timeoutInterval = 60;

    downloadRequest0.downloadDirectoryPath = filePath;
    
    downloadRequest0.downloadProgressBlock = ^(NSProgress * _Nonnull progress) {
        NSLog(@"progress0 = %.2f%%", (double)progress.completedUnitCount * 100.0 / (double)progress.totalUnitCount);
    };
    
    downloadRequest0.successCompletionBlock = ^(__kindof AYRequest * _Nonnull request) {
        NSLog(@"%@下载完成", request.requestUrl);
        NSLog(@"request userInfo = %@", request.userInfo);
    };
    
    downloadRequest0.failureCompletionBlock = ^(__kindof AYRequest * _Nonnull request) {
        NSLog(@"%@下载失败", request.requestUrl);
    };
    
    downloadRequest0.configCurrentRequestBlock = ^(AYRequest * _Nonnull lastRequest, AYRequest * _Nonnull currentRequest) {
        NSLog(@"lastRequest url = %@", lastRequest.requestUrl);
        
        currentRequest.userInfo = @{@"lastUrl": lastRequest.requestUrl ?: @""};
    };
    
//    [downloadRequest0 startWithCompletionBlockWithSuccess:^(__kindof AYRequest * _Nonnull request) {
//        NSLog(@"%@下载完成", request.requestUrl);
//    } failure:^(__kindof AYRequest * _Nonnull request) {
//        NSLog(@"%@下载失败", request.requestUrl);
//    }];
     // */
    
    AYQueueRequest *qRequest = [[AYQueueRequest alloc] initWithRequests:@[downloadRequest, downloadRequest0]];
    [qRequest start];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
