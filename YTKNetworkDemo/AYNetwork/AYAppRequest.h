//
//  AYAppRequest.h
//
//  Created by yu on 2021/11/25.
//

#import "AYRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AYAppRequestError) {
    AYAppRequestErrorJsonToModel = -20001,      // json 转 model 错误
    AYAppRequestErrorNotDictionary = -20002,    // 返回不是一个字典
};

@class UIView;

typedef NSDictionary<NSString *, id> AYRequestDic;


@interface AYAppRequest : AYRequest

@property (nonatomic, assign, readonly) BOOL isResponseSuccess; // 没有任何error，则成功
@property (nonatomic, strong, readonly) NSDictionary *responseDataDic;

/**
 HUD显示
 */
@property (nonatomic, assign) BOOL showWaitingHUD;  // 默认 YES
@property (nonatomic, copy) NSString *waitingHUDText;

@property (nonatomic, assign) BOOL showSuccessHUD;  // 默认 NO
@property (nonatomic, copy) NSString *successHUDText;

@property (nonatomic, assign) BOOL showErrorHUD;    // 默认 YES
@property (nonatomic, assign) BOOL showFailureHUD;  // 默认 YES

/**
 模型转换
 */
@property (nonatomic, assign) Class modelClass;

@property (nonatomic, strong, readonly) id responseModel;
@property (nonatomic, strong, readonly) NSArray *responseModels;

// keyPath 基于 responseDataDic
- (void)configModelArrayWithClass:(Class)modelClass keyPath:(nullable NSString *)keyPath;

/**
 分页
 */
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) NSInteger total;

+ (instancetype)downloadRequestWithUrl:(NSString *)url;

- (void)startInView:(nullable UIView *)view;

@end

NS_ASSUME_NONNULL_END
