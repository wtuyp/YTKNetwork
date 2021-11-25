//
//  AYQueueRequestManager.m
//
//  Created by yu on 2021/11/25.
//

#import "AYQueueRequestManager.h"
#import "AYQueueRequest.h"
#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface AYQueueRequestManager ()

@property (nonatomic, strong) NSMutableArray<AYQueueRequest *> *qRequests;

@end

@implementation AYQueueRequestManager {
    pthread_mutex_t _lock;
}

+ (AYQueueRequestManager *)sharedManager {
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
        pthread_mutex_init(&_lock, NULL);
        _qRequests = [NSMutableArray array];
    }
    return self;
}

- (void)addQueueRequest:(AYQueueRequest *)qRequest {
    Lock();
    [_qRequests addObject:qRequest];
    Unlock();
}

- (void)removeQueueRequest:(AYQueueRequest *)qRequest {
    Lock();
    [_qRequests removeObject:qRequest];
    Unlock();
}


@end
