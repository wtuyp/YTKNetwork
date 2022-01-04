//
//  AYAppRequest.m
//
//  Created by yu on 2021/11/25.
//

#import "AYAppRequest.h"
#import "AYAppRequestConfig.h"

@interface AYAppRequest ()

@property (nonatomic, assign) BOOL isResponseSuccess;
@property (nonatomic, strong) NSDictionary *responseDataDic;
//@property (nonatomic, assign) NSInteger code;
//@property (nonatomic, copy) NSString *message;




@property (nonatomic, weak) UIView *hudView;

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

#pragma mark - Overwrite

- (void)start {
    if (self.showWaitingHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(showHUDWaitingWithText:inView:)] ) {
            [AYRequestHUD showHUDWaitingWithText:self.waitingHUDText inView:self.hudView];
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
                self.isResponseSuccess = YES;
                
                if (self.modelClass) {
                    NSError *toModelError = nil;
                    id json = responseDataDic;
                    if (self.isArray && self.arraykeyPath) {
                        json = [responseDataDic objectForKey:self.arraykeyPath];
                    }
                
                    id toModel = [AYRequestJsonToModel modelWithClass:self.modelClass fromJson:json isArray:self.isArray error:&toModelError];
                    if (toModelError) {
                        self.error = [NSError errorWithDomain:AYRequestErrorDomain code:AYAppRequestErrorJsonToModel userInfo:@{NSLocalizedDescriptionKey: toModelError.localizedDescription}];
                        self.isResponseSuccess = NO;
                    } else {
                        self.isArray ? (self.responseModels = (NSArray *)toModel) : (self.responseModel = toModel);
                    }
                }
            } else {
                self.error = [NSError errorWithDomain:AYRequestErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @"网络请求错误"}];
                self.isResponseSuccess = NO;
            }
        } else {
            self.error = [NSError errorWithDomain:AYRequestErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: @"返回数据格式错误"}];
            self.isResponseSuccess = NO;
        }
    }
}

- (void)requestSuccessHandleBegin {
    if (self.showWaitingHUD) {
        if ([AYRequestHUD respondsToSelector:@selector(hideHUDWaiting)] ) {
            [AYRequestHUD hideHUDWaiting];
        }
    }
    
    if (self.isResponseSuccess) {
        if (self.showSuccessHUD) {
            if ([AYRequestHUD respondsToSelector:@selector(showHUDSuccessWithText:inView:)] ) {
                [AYRequestHUD showHUDSuccessWithText:self.successHUDText inView:self.hudView];
            }
        }
    } else {
        if (self.showFailureHUD) {
            if ([AYRequestHUD respondsToSelector:@selector(showHUDFailureWithText:inView:)] ) {
                [AYRequestHUD showHUDFailureWithText:self.error.localizedDescription inView:self.hudView];
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
            [AYRequestHUD showHUDFailureWithText:self.error.localizedDescription inView:self.hudView];
        }
    }
}

#pragma mark - Public

- (void)startInView:(nullable UIView *)view {
    self.hudView = view;
}

- (void)configModelArrayWithClass:(Class)modelClass keyPath:(nullable NSString *)keyPath {
    self.modelClass = modelClass;
    self.isArray = YES;
    self.arraykeyPath = keyPath;
}

@end
