//
//  AYAppRequestConfig.m
//
//  Created by yu on 2021/11/26.
//

#import "AYAppRequestConfig.h"
#import "AYQueueRequest.h"

@interface AYAppRequestConfig ()

@end

@implementation AYAppRequestConfig

+ (AYAppRequestConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _codeKey = @"code";
        _dataKey = @"data";
        _messageKey = @"msg";
        _successCode = 0;
    }
    
    return self;
}

@end
