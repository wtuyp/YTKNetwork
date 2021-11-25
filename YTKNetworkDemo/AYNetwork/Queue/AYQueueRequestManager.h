//
//  AYQueueRequestManager.h
//
//  Created by yu on 2021/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AYQueueRequest;

@interface AYQueueRequestManager : NSObject

+ (AYQueueRequestManager *)sharedManager;

- (void)addQueueRequest:(AYQueueRequest *)qRequest;
- (void)removeQueueRequest:(AYQueueRequest *)qRequest;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
