//
//  AYRequest.h
//
//  Created by yu on 2021/11/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const AYRequestErrorDomain;

typedef NS_ENUM(NSInteger, AYRequestMethod) {
    AYRequestMethodGET = 0,
    AYRequestMethodPOST,
    AYRequestMethodHEAD,
    AYRequestMethodPUT,
    AYRequestMethodDELETE,
    AYRequestMethodPATCH,
};

typedef NS_ENUM(NSInteger, AYRequestSerializerType) {
    AYRequestSerializerTypeHTTP = 0,
    AYRequestSerializerTypeJSON,
};

typedef NS_ENUM(NSInteger, AYResponseSerializerType) {
    AYResponseSerializerTypeHTTP,
    AYResponseSerializerTypeJSON,
    AYResponseSerializerTypeXMLParser,
};

typedef NS_ENUM(NSInteger, AYRequestPriority) {
    AYRequestPriorityLow = -4L,
    AYRequestPriorityDefault = 0,
    AYRequestPriorityHigh = 4,
};

typedef NS_ENUM(NSInteger, AYRequestError) {
    AYRequestErrorInvalidStatusCode = -10000,
};

@protocol AFMultipartFormData;

typedef void (^AYRequestUploadDataConstructBlock)(id<AFMultipartFormData> formData);
typedef void (^AYRequestProgressBlock)(NSProgress * progress);

@class AYRequest;

typedef void (^AYRequestCompletionBlock)(__kindof AYRequest *request);

@protocol AYRequestDelegate <NSObject>

@optional

- (void)requestSuccess:(__kindof AYRequest *)request;
- (void)requestFailure:(__kindof AYRequest *)request;

@end

//@protocol AYRequestAccessory <NSObject>
//
//@optional
//
//- (void)requestWillStart:(id)request;
//- (void)requestWillStop:(id)request;
//- (void)requestDidStop:(id)request;
//
//@end


@interface AYRequest : NSObject

@property (nonatomic, assign) AYRequestMethod method;
@property (nonatomic, copy) NSString *requestUrl;
@property (nonatomic, strong, nullable) id parameters;  ///< 请求参数
@property (nonatomic, assign) NSTimeInterval timeoutInterval;   ///< 超时时间，默认 15s

@property (nonatomic, assign) AYRequestSerializerType requestSerializerType;    // 默认 AYRequestSerializerTypeJSON
@property (nonatomic, assign) AYResponseSerializerType responseSerializerType;  // 默认 AYResponseSerializerTypeJSON

@property (nonatomic, weak, nullable) id<AYRequestDelegate> delegate;

@property (nonatomic, copy, nullable) AYRequestCompletionBlock successCompletionBlock;
@property (nonatomic, copy, nullable) AYRequestCompletionBlock failureCompletionBlock;

/**
 发起请求后，一些只读属性
 */
@property (nonatomic, strong) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;    // requestTask.response
@property (nonatomic, strong, nullable) id responseObject;  // 序列化后的数据对象，类型由 AYResponseSerializerType 决定 (data, dic/array, xml...)
@property (nonatomic, strong, nullable) NSError *error;

@property (nonatomic, readonly) BOOL isCancelled;
@property (nonatomic, readonly) BOOL isExecuting;

/**
 其他不常用属性
 */
@property (nonatomic, copy) NSString *baseUrl;  // 设置后，替代 NetworkCenter 的 baseUrl
@property (nonatomic, assign) BOOL useCDN;
@property (nonatomic, copy) NSString *cdnUrl;   // 设置后，替代 NetworkCenter 的 cdnUrl

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *headerFields;
@property (nonatomic, strong, nullable) NSArray<NSString *> *authorizationHeaderFields;

@property (nonatomic) AYRequestPriority requestPriority;
@property (nonatomic, assign) BOOL allowsCellularAccess;    ///< 是否使用蜂窝数据，默认 YES
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong, nullable) NSDictionary *userInfo;
///  自定义请求设置，将忽略参数, `requestUrl`, `timeoutInterval`, `requestArgument`, `allowsCellularAccess`, `method` and `requestSerializerType` will all be ignored.
@property (nonatomic, strong, nullable) NSURLRequest *customUrlRequest;

/**
 上传下载相关属性
 */
@property (nonatomic, copy, nullable) NSString *downloadDirectoryPath;  ///< 下载文件夹路径
@property (nonatomic, strong, nullable) NSURL *downloadLocalFilePath;   ///< 下载成功后的文件路径
@property (nonatomic, copy, nullable) AYRequestProgressBlock downloadProgressBlock;

@property (nonatomic, copy, nullable) AYRequestUploadDataConstructBlock uploadDataConstructBlock;   ///<  构建上传文件
@property (nonatomic, copy, nullable) AYRequestProgressBlock uploadProgressBlock;

- (instancetype)initWithMethod:(AYRequestMethod)mothod url:(NSString *)url parameters:(nullable id)parameters;

/// 请求开始
- (void)start;
- (void)startWithCompletionBlockWithSuccess:(nullable AYRequestCompletionBlock)success
                                    failure:(nullable AYRequestCompletionBlock)failure;

/// 请求停止
- (void)stop;
- (void)clearCompletionBlock;

/**
 子类看情况实现
 pre 在 begin 前调用，在请求线程上。
 begin 在 delegate \ block 前调用，end 在 delegate \ block 后调用。在主线程上。
 */
- (void)requestSuccessPreHandle;
- (void)requestSuccessHandleBegin;
- (void)requestSuccessHandleEnd;

- (void)requestFailurePreHandle;
- (void)requestFailureHandleBegin;
- (void)requestFailureHandleEnd;

@end

NS_ASSUME_NONNULL_END
