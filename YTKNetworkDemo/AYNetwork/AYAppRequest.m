//
//  AYAppRequest.m
//
//  Created by yu on 2021/11/25.
//

#import "AYAppRequest.h"
#import "AYAppRequestConfig.h"

@interface AYAppRequest ()

@property (nonatomic, assign) BOOL isSuccess;
@property (nonatomic, strong) NSDictionary *responseDataDic;

/**
 模型转换
 */
@property (nonatomic, strong) id responseModel;
@property (nonatomic, strong) NSArray *responseModels;

@property (nonatomic, assign) BOOL isArray;
@property (nonatomic, copy) NSString *arraykeyPath;  // model array 在 responseDataDic 中的 keyPath

@end

@implementation AYAppRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _showWaitingHUD = YES;
        _showFailureHUD = YES;
    }
    return self;
}

+ (instancetype)downloadRequestWithUrl:(NSString *)url {
    AYAppRequest *request = [[AYAppRequest alloc] initWithMethod:AYRequestMethodGET url:url parameters:nil];
    request.timeoutInterval = 60;
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"Download"];
    
    request.downloadDirectoryPath = filePath;
    
    return request;
}

#pragma mark - Override

- (void)start {
    if (self.showWaitingHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(showHUDWaitingWithText:inView:)] ) {
            [AYRequestHUD showHUDWaitingWithText:self.waitingHUDText inView:self.showingHudView];
        }
    }
    
    [super start];
}

- (void)stop {
    [super stop];
    
    if (self.showWaitingHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(hideHUDWaiting)] ) {
            [AYRequestHUD hideHUDWaiting];
        }
    }
}

- (void)requestSuccessPreHandle {
    NSDictionary *responseDic = (NSDictionary *)self.responseObject;
    if ([responseDic isKindOfClass:[NSDictionary class]]) {
        NSInteger code = [responseDic[AYRequestSharedConfig.codeKey] integerValue];
        NSDictionary *responseDataDic = responseDic[AYRequestSharedConfig.dataKey];
        NSString *message = responseDic[AYRequestSharedConfig.messageKey];
        
        if ([responseDataDic isKindOfClass:[NSDictionary class]]) {
            if (code == AYRequestSharedConfig.successCode) {
                self.responseDataDic = responseDataDic;
                self.isSuccess = YES;
                
                if (self.modelClass) {
                    if (![AYRequestJsonToModel respondsToSelector:@selector(modelWithClass:fromJson:isArray:error:)]) {
                        self.error = [NSError errorWithDomain:AYRequestErrorDomain code:AYAppRequestErrorJsonToModel userInfo:@{NSLocalizedDescriptionKey: @"未实现'AYAppNetworkPluginJsonToModel'代理"}];
                        self.isSuccess = NO;
                        return;
                    }
                    
                    NSError *toModelError = nil;
                    id json = responseDataDic;
                    if (self.isArray && self.arraykeyPath) {
                        json = [responseDataDic objectForKey:self.arraykeyPath];
                    }
                
                    id toModel = [AYRequestJsonToModel modelWithClass:self.modelClass fromJson:json isArray:self.isArray error:&toModelError];
                    if (toModelError) {
                        self.error = [NSError errorWithDomain:AYRequestErrorDomain code:AYAppRequestErrorJsonToModel userInfo:@{NSLocalizedDescriptionKey: toModelError.localizedDescription}];
                        self.isSuccess = NO;
                    } else {
                        self.isArray ? (self.responseModels = (NSArray *)toModel) : (self.responseModel = toModel);
                    }
                }
            } else {
                self.error = [NSError errorWithDomain:AYRequestErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @"网络请求错误"}];
                self.isSuccess = NO;
            }
        } else {
            self.error = [NSError errorWithDomain:AYRequestErrorDomain code:AYAppRequestErrorNotDictionary userInfo:@{NSLocalizedDescriptionKey: @"返回数据不是字典类型"}];
            self.isSuccess = NO;
        }
    }
}

- (void)requestSuccessHandleBegin {
    if (self.showWaitingHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(hideHUDWaiting)] ) {
            [AYRequestHUD hideHUDWaiting];
        }
    }
    
    if (self.isSuccess) {
        if (self.showSuccessHUD) {
            if ([AYRequestHUD respondsToSelector:@selector(showHUDSuccessWithText:inView:)] ) {
                [AYRequestHUD showHUDSuccessWithText:self.successHUDText inView:self.showingHudView];
            }
        }
    } else {
        if (self.showFailureHUD) {
            if ([AYRequestHUD respondsToSelector:@selector(showHUDFailureWithText:inView:)] ) {
                [AYRequestHUD showHUDFailureWithText:self.error.localizedDescription inView:self.showingHudView];
            }
        }
    }
}

- (void)requestFailureHandleBegin {
    if (self.showWaitingHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(hideHUDWaiting)] ) {
            [AYRequestHUD hideHUDWaiting];
        }
    }
    
    if (self.showFailureHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(showHUDFailureWithText:inView:)] ) {
            [AYRequestHUD showHUDFailureWithText:self.error.localizedDescription inView:self.showingHudView];
        }
    }
}

#pragma mark - Public

- (void)configShowHUDInView:(nullable UIView *)view
                waitingText:(nullable NSString *)waitingText
                successText:(nullable NSString *)successText {
    self.showingHudView = view;
    if (waitingText) {
        self.showWaitingHUD = YES;
        self.waitingHUDText = waitingText;
    }
    if (successText) {
        self.showSuccessHUD = YES;
        self.successHUDText = successText;
    }
}

- (void)configModelArrayWithClass:(Class)modelClass keyPath:(nullable NSString *)keyPath {
    self.modelClass = modelClass;
    self.isArray = YES;
    self.arraykeyPath = keyPath;
}

@end
