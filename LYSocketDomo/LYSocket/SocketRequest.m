//
//  SocketRequest.m
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 KJD. All rights reserved.
//

#import "SocketRequest.h"
#import "TCPSocket.h"
typedef void (^callBackBlock)(id);

static NSString *APP_PARAM = @"smart";
static NSString *CO_PARAM = @"kjd";
static NSMutableDictionary *_successBlockDic;
static NSMutableDictionary *_failureBlockDic;
static NSTimeInterval requestTimeOut = 10;

// const 关键字的作用，组合的作用是啥？
static NSString *const ERROR_NOTI_NAME = @"ly_error_noti";
static TCPSocket *_tcpScoket = nil;

@implementation SocketRequest

+ (void)initialize{
    _successBlockDic = [NSMutableDictionary dictionary];
    _failureBlockDic = [NSMutableDictionary dictionary];
}

+ (void)socket:(TCPSocket *)tcpSocket apiName:(NSString *)apiName parameters:(id)parameters success:(void (^)(id))success failure:(void (^)(NSError *))failure{
    
    if(!_tcpScoket){
        NSAssert(!_tcpScoket, @"请先调用(-setTcpSocket:appParam:co_param:)设置socket相关参数");
        return;
    }
    [self socketWithApiName:apiName parameters:parameters success:success failure:failure];
}

// 发送数据
+ (void)socketWithApiName:(NSString *)apiName
               parameters:(id)parameters
                  success:(void (^)(id))success
                  failure:(void (^)(NSError *))failure{
    NSString *noti_name = [NSString stringWithFormat:@"ly_%@",apiName];
    
    // 这里不懂，这里应该是回调出去的。居然在这里进行判断，这个写法是什么意思？所以无论怎么走都会走过来这个意思？
    if(success){
        
        // 每一次传，都把回调放在字典里这个操作？这是哪个设计模式？为什么不通过常规的代理或者Block？
        _successBlockDic[noti_name] = success;
    }
    if(failure){
        _failureBlockDic[noti_name] = failure;
        _failureBlockDic[ERROR_NOTI_NAME] = failure;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_result_noti:) name:noti_name object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(get_result_noti:) name:ERROR_NOTI_NAME object:nil];
    
    // 发送请求
    [_tcpScoket sendDataToSocket:[self formatCmdWithApiName:apiName parameters:parameters]];
    
    // 发送超时的通知
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(requestTimeOut * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 如果不会失败，则不发。
        if(!_failureBlockDic[noti_name]){
            return ;
        }
        
        NSNotification *noti = [NSNotification notificationWithName:noti_name object:nil userInfo:@{@"-1" : @"request time out"}];
        
        [self get_result_noti:noti];
    });
}

#pragma mark - 通知

+(void)get_result_noti:(NSNotification *)noti{
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:noti.name object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ERROR_NOTI_NAME object:nil];
    
    if (!noti.userInfo || noti.userInfo.count == 0) {
        return;
    }
    
    // 取出 retcode
    NSInteger retcode = [[noti.userInfo allKeys][0] integerValue];
    
    if(retcode == 0){
        callBackBlock success = _successBlockDic[noti.name];
        [self removeBlockWithKey:noti.name];
        if(success){
            success(noti.object);
        }
    }else{
        callBackBlock failure = _failureBlockDic[noti.name];
        [self removeBlockWithKey:noti.name];
        if(failure){
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:retcode userInfo:@{@"error":[noti.userInfo allValues]}];
            failure(error);
        }
    }
}

/**
 *  移除block
 *
 *  @param key key
 */
+ (void)removeBlockWithKey:(NSString *)key{
    
    [_successBlockDic removeObjectForKey:key];
    [_failureBlockDic removeObjectForKey:key];
    [_failureBlockDic removeObjectForKey:ERROR_NOTI_NAME];
}


#pragma mark - help
/**
 *  格式化指令
 */
+ (NSString *)formatCmdWithApiName:(NSString *)apiName parameters:(id)parameters{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) return nil;
    
    NSString *param = [[[[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"  \"" withString:@"\""] stringByReplacingOccurrencesOfString:@" : " withString:@":"];
    
    return [NSString stringWithFormat:@"{\"app\":\"%@\",\"co\":\"%@\",\"api\":\"%@\",\"data\":%@}\n", APP_PARAM, CO_PARAM, apiName, param];
}

/**
 *  参数设置
 *
 *  @param tcpSocket tcpSocket
 *  @param app_param app_param
 *  @param co_param  co_param
 */
+ (void)setTcpSocket:(TCPSocket *)tcpSocket appParam:(NSString *)app_param co_param:(NSString *)co_param{
    
    if (tcpSocket) {
        _tcpScoket = tcpSocket;
    }
    if (app_param) {
        APP_PARAM = app_param;
    }
    if (co_param) {
        CO_PARAM = co_param;
    }
}


/**
 *  设置请求超时时间
 *
 *  @param timeOut 超时时间
 */
+ (void)setSocketRequestTimeOut:(NSTimeInterval)timeOut{
    
    requestTimeOut = timeOut;
    
}

@end
