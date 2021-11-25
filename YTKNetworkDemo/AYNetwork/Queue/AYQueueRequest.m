//
//  AYQueueRequest.m
//
//  Created by yu on 2021/11/24.
//

#import "AYQueueRequest.h"
#import "AYQueueRequestManager.h"

@interface AYQueueRequest () <AYRequestDelegate>

@property (nonatomic, strong, nullable) NSArray<AYRequest *> *requests;
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) NSUInteger requestIndex;
@end

@implementation AYQueueRequest

- (instancetype)initWithRequests:(NSArray<AYRequest *> *)requests {
    self = [super init];
    if (self) {
        _requests = requests;
    }
    
    return self;
}

- (void)start {
    if (self.requests.count == 0) {
        return;
    }
    
    if (self.isStart) {
        return;
    }
        
    self.isStart = YES;
    
    AYRequest *request = self.requests.firstObject;
    request.delegate = self;
    [request start];
    [[AYQueueRequestManager sharedManager] addQueueRequest:self];
}

- (void)stop {
    AYRequest *currentRequest = self.requests[self.requestIndex];
    [currentRequest stop];
    [self destroy];
}

#pragma mark - AYRequestDelegate

- (void)requestFinished:(__kindof AYRequest *)request {
    self.requestIndex++;
    if (self.requestIndex >= self.requests.count) { // 请求全部完成
        if (_successCompletionBlock) {
            _successCompletionBlock(self);
        }
        
        if ([_delegate respondsToSelector:@selector(queueRequestFinished:)]) {
            [_delegate queueRequestFinished:self];
        }

        [self destroy];
        return;
    }
    
    AYRequest *currentRequest = self.requests[self.requestIndex];
    if (currentRequest.configBeforeStartRequestInQueueBlock) {
        currentRequest.configBeforeStartRequestInQueueBlock(request, currentRequest);
    }
    currentRequest.delegate = self;
    [currentRequest start];
}

- (void)requestFailed:(__kindof AYRequest *)request {
    if (_failureCompletionBlock) {
        _failureCompletionBlock(self, request);
    }
    
    if ([_delegate respondsToSelector:@selector(queueRequestFailed:failedRequest:)]) {
        [_delegate queueRequestFailed:self failedRequest:request];
    }
    
    [self destroy];
}

- (void)destroy {
    self.requests = nil;
    self.isStart = NO;
    [[AYQueueRequestManager sharedManager] removeQueueRequest:self];
}

@end

#import <objc/runtime.h>

@implementation AYRequest (AYQueueRequest)

- (void (^)(AYRequest * _Nonnull, AYRequest * _Nonnull))configBeforeStartRequestInQueueBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setConfigBeforeStartRequestInQueueBlock:(void (^)(AYRequest * _Nonnull, AYRequest * _Nonnull))configBeforeStartQueueRequestBlock {
    objc_setAssociatedObject(self, @selector(configBeforeStartRequestInQueueBlock), configBeforeStartQueueRequestBlock, OBJC_ASSOCIATION_COPY);
}

@end
