//
//  AYRequest.m
//
//  Created by yu on 2021/11/20.
//

#import "AYRequest.h"
#import "AYNetworkCenter.h"

NSString *const AYRequestErrorDomain = @"com.ay.request.domain.error";

@interface AYRequest ()

@end

@implementation AYRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeoutInterval = 15.0;
        
        _method = AYRequestMethodGET;
        _requestSerializerType = AYRequestSerializerTypeJSON;
        _responseSerializerType = AYResponseSerializerTypeJSON;
        
        _allowsCellularAccess = YES;
    }
    return self;
}

- (instancetype)initWithMethod:(AYRequestMethod)mothod url:(NSString *)url parameters:(nullable id)parameters; {
    self = [self init];
    if (self) {
        _method = mothod;
        _requestUrl = url;
        _parameters = parameters;
    }
    return self;
}

#pragma mark - Request and Response Information

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(AYRequestCompletionBlock)success
                              failure:(AYRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    self.uploadProgressBlock = nil;
}

- (void)requestSuccessPreHandle {}
- (void)requestSuccessHandleBegin {}
- (void)requestSuccessHandleEnd {}

- (void)requestFailurePreHandle {}
- (void)requestFailureHandleBegin {}
- (void)requestFailureHandleEnd {}

#pragma mark - Request Action

- (void)start {
    [[AYNetworkCenter sharedCenter] startRequest:self];
}

- (void)stop {
    self.delegate = nil;
    [[AYNetworkCenter sharedCenter] cancelRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(AYRequestCompletionBlock)success
                                    failure:(AYRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.parameters];
}

@end
