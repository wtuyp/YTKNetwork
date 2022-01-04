//
//  AYAppRequestConfig.h
//
//  Created by yu on 2021/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIView;

@protocol AYAppNetworkPluginHUD <NSObject>

- (void)showHUDWaitingWithText:(nullable NSString *)text inView:(nullable UIView *)view;
- (void)hideHUDWaiting;

- (void)showHUDSuccessWithText:(nullable NSString *)text inView:(nullable UIView *)view;
- (void)showHUDFailureWithText:(nullable NSString *)text inView:(nullable UIView *)view;

@end

@protocol AYAppNetworkPluginCache <NSObject>

- (void)setObject:(id)object forKey:(id<NSCoding>)key;
- (id)objectForKey:(id<NSCopying>)key;

@end

@protocol AYAppNetworkPluginJsonToModel <NSObject>

- (id)modelWithClass:(Class)aClass fromJson:(id)json isArray:(BOOL)isArray error:(NSError * _Nullable __autoreleasing *)error;

@end

#define AYRequestSharedConfig   [AYAppRequestConfig sharedConfig]
#define AYRequestHUD            AYRequestSharedConfig.hud
#define AYRequestCache          AYRequestSharedConfig.cache
#define AYRequestJsonToModel    AYRequestSharedConfig.jsonToModel

@interface AYAppRequestConfig : NSObject

@property (nonatomic, strong) id<AYAppNetworkPluginHUD> hud;
@property (nonatomic, strong) id<AYAppNetworkPluginCache> cache;
@property (nonatomic, strong) id<AYAppNetworkPluginJsonToModel> jsonToModel;

+ (AYAppRequestConfig *)sharedConfig;

@property (nonatomic, copy) NSString *codeKey;      // 默认 "code"
@property (nonatomic, copy) NSString *dataKey;      // 默认 "data"
@property (nonatomic, copy) NSString *messageKey;   // 默认 "msg"

@property (nonatomic, assign) NSInteger successCode;    // 默认 0


- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
