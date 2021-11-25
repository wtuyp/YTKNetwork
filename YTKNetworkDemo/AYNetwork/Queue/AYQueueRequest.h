//
//  AYQueueRequest.h
//
//  Created by yu on 2021/11/24.
//

#import <Foundation/Foundation.h>
#import "AYRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class AYQueueRequest;

typedef void(^AYQueueRequestSuccessBlock)(__kindof AYQueueRequest *qRequest);
typedef void(^AYQueueRequestFailureBlock)(__kindof AYQueueRequest *qRequest, __kindof AYRequest *failureRequest);

@protocol AYQueueRequestDelegate <NSObject>

@optional

- (void)queueRequestFinished:(__kindof AYQueueRequest *)qRequest;
- (void)queueRequestFailed:(__kindof AYQueueRequest *)qRequest failedRequest:(__kindof AYRequest *)request;

@end

@interface AYQueueRequest : NSObject

@property (nonatomic, weak, nullable) id<AYQueueRequestDelegate> delegate;

@property (nonatomic, copy, nullable) AYQueueRequestSuccessBlock successCompletionBlock;
@property (nonatomic, copy, nullable) AYQueueRequestFailureBlock failureCompletionBlock;

- (instancetype)initWithRequests:(NSArray<__kindof AYRequest *> *)requests;

- (void)start;
- (void)stop;

@end

@interface AYRequest (AYQueueRequest)

@property (nonatomic, copy, nullable) void (^configBeforeStartRequestInQueueBlock)(AYRequest *lastRequest, AYRequest *currentRequest);

@end

NS_ASSUME_NONNULL_END
