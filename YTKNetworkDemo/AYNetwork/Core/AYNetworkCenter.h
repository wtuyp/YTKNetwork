//
//  AYNetworkCenter.h
//
//  Created by yu on 2021/11/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AYRequest;
@class AFSecurityPolicy;
@class AFHTTPSessionManager;

@interface AYNetworkCenter : NSObject

@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *cdnUrl;

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *headerFields;    ///< 通用请求头

@property (nonatomic, assign) BOOL debugLogEnabled; // 仅 DEBUG 模式下有效, 默认 YES

+ (AYNetworkCenter *)sharedCenter;

- (void)startRequest:(AYRequest *)request;
- (void)cancelRequest:(AYRequest *)request;
- (void)cancelAllRequests;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
