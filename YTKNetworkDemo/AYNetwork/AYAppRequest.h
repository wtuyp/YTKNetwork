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

typedef NSMutableDictionary<NSString *, id> AYAppRequestParamDic;

@interface AYAppRequest : AYRequest

@property (nonatomic, assign, readonly) BOOL isSuccess;     // 没有任何error，则成功
@property (nonatomic, strong, readonly) NSDictionary *responseDataDic;

/**
 HUD显示
 */
@property (nonatomic, assign) BOOL showWaitingHUD;  // 默认 YES
@property (nonatomic, copy, nullable) NSString *waitingHUDText;

@property (nonatomic, assign) BOOL showSuccessHUD;  // 默认 NO
@property (nonatomic, copy, nullable) NSString *successHUDText;

@property (nonatomic, assign) BOOL showFailureHUD;  // 默认 YES

@property (nonatomic, weak) UIView *showingHudView; ///< 显示 HUD 的视图

- (void)configShowHUDInView:(nullable UIView *)view
                waitingText:(nullable NSString *)waitingText
                successText:(nullable NSString *)successText;
/**
 模型转换
 */
@property (nonatomic, assign) Class modelClass;

@property (nonatomic, strong, readonly) id responseModel;
@property (nonatomic, strong, readonly) NSArray *responseModels;

// keyPath 基于 responseDataDic
- (void)configModelArrayWithClass:(Class)modelClass keyPath:(nullable NSString *)keyPath;

+ (instancetype)downloadRequestWithUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
