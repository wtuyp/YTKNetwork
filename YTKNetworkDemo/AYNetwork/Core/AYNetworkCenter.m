//
//  AYNetworkCenter.m
//
//  Created by yu on 2021/11/20.
//

#import "AYNetworkCenter.h"
#import "AYRequest.h"
#import <pthread/pthread.h>
#import <CommonCrypto/CommonDigest.h>

#if __has_include(<AFNetworking/AFHTTPSessionManager.h>)
#import <AFNetworking/AFHTTPSessionManager.h>
#else
#import <AFNetworking/AFHTTPSessionManager.h>
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface AYNetworkCenter ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, AYRequest *> *requestRecords;

@end

@implementation AYNetworkCenter {
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;
}

+ (AYNetworkCenter *)sharedCenter {
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
        _manager = [[AFHTTPSessionManager alloc] init];
        
        _requestRecords = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.ay.network.center.processing", DISPATCH_QUEUE_CONCURRENT);
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        pthread_mutex_init(&_lock, NULL);
        
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        
        _manager.completionQueue = _processingQueue;
        
        _debugLogEnabled = YES;
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
    });
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    });
    return _xmlParserResponseSerialzier;
}

- (NSString *)requestUrlOfRequest:(AYRequest *)request {
    NSParameterAssert(request != nil);
    
    NSString *requestUrl = request.requestUrl;
    NSURL *tempURL = [NSURL URLWithString:requestUrl];
    
    if (tempURL && tempURL.host && tempURL.scheme) {
        return requestUrl;
    }
    
    NSString *baseUrl;
    if (request.useCDN) {
        if (request.cdnUrl.length > 0) {
            baseUrl = request.cdnUrl;
        } else {
            baseUrl = self.cdnUrl;
        }
    } else {
        if (request.baseUrl.length > 0) {
            baseUrl = request.baseUrl;
        } else {
            baseUrl = self.baseUrl;
        }
    }
    
    NSURL *url = [NSURL URLWithString:baseUrl];
    
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:requestUrl relativeToURL:url].absoluteString;
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(AYRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == AYRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == AYRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.timeoutInterval = request.timeoutInterval;
    requestSerializer.allowsCellularAccess = request.allowsCellularAccess;
    
    NSArray<NSString *> *authorizationHeaderFieldArray = [request authorizationHeaderFields];
    if (authorizationHeaderFieldArray) {
        NSParameterAssert(authorizationHeaderFieldArray.count == 2);
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }
    
    NSDictionary<NSString *, NSString *> *headerFields = self.headerFields;
    if (headerFields) {
        for (NSString *field in headerFields.allKeys) {
            [requestSerializer setValue:headerFields[field] forHTTPHeaderField:field];
        }
    }
    
    headerFields = request.headerFields;
    if (headerFields) {
        for (NSString *field in headerFields.allKeys) {
            [requestSerializer setValue:headerFields[field] forHTTPHeaderField:field];
        }
    }
    
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(AYRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    AYRequestMethod method = request.method;
    NSString *url = [self requestUrlOfRequest:request];
    id params = request.parameters;
    
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    
    switch (method) {
        case AYRequestMethodGET:
            if (request.downloadDirectoryPath) {
                return [self downloadTaskWithDownloadPath:request.downloadDirectoryPath
                                        requestSerializer:requestSerializer
                                                URLString:url
                                               parameters:params
                                                 progress:request.downloadProgressBlock
                                                    error:error];
            } else {
                return [self dataTaskWithHTTPMethod:@"GET"
                                  requestSerializer:requestSerializer
                                          URLString:url
                                         parameters:params
                                              error:error];
            }
        case AYRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                 uploadProgress:request.uploadProgressBlock
                            uploadDataConstruct:request.uploadDataConstructBlock
                                          error:error];
        case AYRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                          error:error];
        case AYRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                 uploadProgress:request.uploadProgressBlock
                            uploadDataConstruct:request.uploadDataConstructBlock
                                          error:error];
        case AYRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                          error:error];
        case AYRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH"
                              requestSerializer:requestSerializer
                                      URLString:url
                                     parameters:params
                                          error:error];
    }
}

#pragma mark - Public

- (void)startRequest:(AYRequest *)request {
    NSParameterAssert(request != nil);
    
    NSError * __autoreleasing requestSerializationError = nil;
    
    NSURLRequest *customUrlRequest= request.customUrlRequest;
    if (customUrlRequest) {
        __block NSURLSessionDataTask *dataTask = nil;
        dataTask = [_manager dataTaskWithRequest:customUrlRequest
                                  uploadProgress:nil
                                downloadProgress:nil
                               completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handleRequestResult:dataTask responseObject:responseObject error:error];
        }];
        request.requestTask = dataTask;
    } else {
        request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    }
    
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    // Set request task priority
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case AYRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case AYRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case AYRequestPriorityDefault:
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    
    [self addRequestToRecord:request];
    [request.requestTask resume];
    AYNetwrokLog(@"\n[AYRequest Start %@]", request.requestUrl);
}

- (void)cancelRequest:(AYRequest *)request {
    NSParameterAssert(request != nil);
    
    if (request.downloadDirectoryPath && [self incompleteDownloadTempPathForDownloadPath:request.downloadDirectoryPath] != nil) {
        NSURLSessionDownloadTask *requestTask = (NSURLSessionDownloadTask *)request.requestTask;
        [requestTask cancelByProducingResumeData:^(NSData *resumeData) {
            NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.downloadDirectoryPath];
            [resumeData writeToURL:localUrl atomically:YES];
        }];
    } else {
        [request.requestTask cancel];
    }
    
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
    AYNetwrokLog(@"\n[AYRequest Cancel %@]", request.requestUrl);
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestRecords allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            AYRequest *request = _requestRecords[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stop];
        }
    }
}

#pragma mark - Private

- (BOOL)validateResult:(AYRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    NSInteger statusCode = request.response.statusCode;
    
    BOOL result = [_allStatusCodes containsIndex:statusCode];
    if (!result) {
        if (error) {
            NSString *desc = [NSString stringWithFormat:@"Invalid status code (%ld)", (long)statusCode];
            *error = [NSError errorWithDomain:AYRequestErrorDomain code:AYRequestErrorInvalidStatusCode userInfo:@{NSLocalizedDescriptionKey: desc}];
        }
        return result;
    }
    
    return YES;
}

- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    AYRequest *request = _requestRecords[@(task.taskIdentifier)];
    Unlock();
    
    if (!request) {
        return;
    }
    
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    if ([responseObject isKindOfClass:[NSData class]]) {
        switch (request.responseSerializerType) {
            case AYResponseSerializerTypeHTTP:
                request.responseObject = responseObject;
                break;
            case AYResponseSerializerTypeJSON: {
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:responseObject error:&serializationError];
#if DEBUG
                NSString *log = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:request.responseObject options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
                AYNetwrokLog(@"\n[AYRequest Response %@]\n %@\n", request.requestUrl, log);
#endif
                break;
            }
            case AYResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:responseObject error:&serializationError];
                break;
        }
    } else if ([responseObject isKindOfClass:[NSURL class]]) {
        NSURL *filePath = (NSURL *)responseObject;
        AYNetwrokLog(@"\n[AYRequest Response %@]\n filePath: %@\n", request.requestUrl, filePath.absoluteString);
        request.downloadLocalFilePath = filePath;
    }
    
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(AYRequest *)request {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [request toggleAccessoriesWillStopCallBack];
        
        if ([request.delegate respondsToSelector:@selector(requestFinished:)]) {
            [request.delegate requestFinished:request];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
        //        [request toggleAccessoriesDidStopCallBack];
    });
}

- (void)requestDidFailWithRequest:(AYRequest *)request error:(NSError *)error {
    request.error = error;
    AYNetwrokLog(@"\n[AYRequest Failed %@] status code = %ld, error = %@",
                 request.requestUrl, (long)request.response.statusCode, error.localizedDescription);
    
    // 保存未下载完成的数据
    if (request.downloadDirectoryPath) {
        NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:request.downloadDirectoryPath];
        if (localUrl) {
            NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
            if (incompleteDownloadData) {
                [incompleteDownloadData writeToURL:localUrl atomically:YES];
            }
        }
    }
    
    // Load response from file and clean up if download task failed.
    if ([request.downloadLocalFilePath isKindOfClass:[NSURL class]]) {
        NSURL *url = request.downloadLocalFilePath;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseObject = [NSData dataWithContentsOfURL:url];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.downloadLocalFilePath = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [request toggleAccessoriesWillStopCallBack];
        
        if ([request.delegate respondsToSelector:@selector(requestFailed:)]) {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
        //        [request toggleAccessoriesDidStopCallBack];
    });
}

- (void)addRequestToRecord:(AYRequest *)request {
    Lock();
    _requestRecords[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(AYRequest *)request {
    Lock();
    [_requestRecords removeObjectForKey:@(request.requestTask.taskIdentifier)];
    Unlock();
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method
                      requestSerializer:requestSerializer
                              URLString:URLString
                             parameters:parameters
                         uploadProgress:nil
                    uploadDataConstruct:nil
                                  error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(AYRequestProgressBlock)uploadProgress
                             uploadDataConstruct:(nullable void (^)(id <AFMultipartFormData> formData))uploadDataConstructBlock
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    
    if (uploadDataConstructBlock) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:uploadDataConstructBlock error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                              uploadProgress:uploadProgress
                            downloadProgress:nil
                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
        [self handleRequestResult:dataTask responseObject:responseObject error:_error];
    }];
    
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(NSString *)downloadPath
                                         requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                                 URLString:(NSString *)URLString
                                                parameters:(id)parameters
                                                  progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:parameters error:error];
    
    NSString *fileName = [urlRequest.URL lastPathComponent];
    NSString *filePath = downloadPath;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            AYNetwrokLog(@"Failed to create download directory at %@ with error: %@ \n ", filePath, error != nil ? error.localizedDescription : @"unkown");
            return nil;
        }
    }
    
    NSString *downloadTargetPath = [NSString pathWithComponents:@[filePath, fileName]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    NSURL *localUrl = [self incompleteDownloadTempPathForDownloadPath:filePath];
    if (localUrl) {
        BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:localUrl.path];
        NSData *data = [NSData dataWithContentsOfURL:localUrl];
        BOOL resumeDataIsValid = [[self class] validateResumeData:data];
        
        BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
        // Try to resume with resumeData.
        // Even though we try to validate the resumeData, this may still fail and raise excecption.
        if (canBeResumed) {
            @try {
                downloadTask = [_manager downloadTaskWithResumeData:data progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                } completionHandler:
                                ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    [self handleRequestResult:downloadTask responseObject:filePath error:error];
                }];
                resumeSucceeded = YES;
            } @catch (NSException *exception) {
                AYNetwrokLog(@"Resume download failed, reason = %@", exception.reason);
                resumeSucceeded = NO;
            }
        }
    }
    
    if (!resumeSucceeded) {
        downloadTask = [_manager downloadTaskWithRequest:urlRequest progress:downloadProgressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
        } completionHandler:
                        ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self handleRequestResult:downloadTask responseObject:filePath error:error];
        }];
    }
    return downloadTask;
}

#pragma mark - Resumable Download

- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Download/Incompleted"];
    
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:cacheFolder isDirectory:&isDirectory] && isDirectory) {
        return cacheFolder;
    }
    
    NSError *error = nil;
    if ([fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error] && error == nil) {
        return cacheFolder;
    }
    
    AYNetwrokLog(@"Failed to create cache directory at %@ with error: %@", cacheFolder, error != nil ? error.localizedDescription : @"unkown");
    return nil;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    if (downloadPath.length == 0) {
        return nil;
    }
    
    NSString *md5URLString = [[self class] md5StringFromString:downloadPath];
    NSString *tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return tempPath ? [NSURL fileURLWithPath:tempPath] : nil;
}

#pragma mark - Private

void AYNetwrokLog(NSString *format, ...) {
#if DEBUG
    if (![AYNetworkCenter sharedCenter].debugLogEnabled) {
        return;
    }
    va_list argptr;
    va_start(argptr, format);
    NSLogv(format, argptr);
    va_end(argptr);
#endif
}

+ (NSString *)md5StringFromString:(NSString *)string {
    NSParameterAssert(string != nil && [string length] > 0);
    
    const char *value = [string UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    
    return outputString;
}

+ (NSStringEncoding)stringEncodingWithRequest:(AYRequest *)request {
    // From AFNetworking 2.6.3
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSString *encodingName = [request.response.textEncodingName copy];
    if (encodingName) {
        CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);
        if (encoding != kCFStringEncodingInvalidId) {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        }
    }
    return stringEncoding;
}

+ (BOOL)validateResumeData:(NSData *)data {
    // From http://stackoverflow.com/a/22137510/3562486
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;
    
    // Before iOS 9 & Mac OS X 10.11
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000)\
|| (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED < 101100)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
    // complicated structure. Besides, the plist structure is different between iOS 9 and iOS 10.
    // We can only assume that the plist being successfully parsed means the resume data is valid.
    return YES;
}

@end


