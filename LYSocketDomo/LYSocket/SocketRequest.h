//
//  SocketRequest.h
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 KJD. All rights reserved.
//  我觉得对于TCP的封装有些不必要，实际上就是对GCD进行了一次包装，包装成自己的 TCPSocket, 隔离对第三方库的直接使用。
//  现在觉得可能有必要，比如我要换一个第三方库，这就非常有必要了。
//  那么，第三方库更换的情况多吗？如果不进行一层包装，更换的工作量大不大？
//  这不是对与错，这是权衡。因为文件越多，迷惑队友的的概率就越大。

#import <Foundation/Foundation.h>
@class  TCPSocket;

@interface SocketRequest : NSObject


/**
 设置 socket 及协议格式参数

 @param tcpSocket TCPSocket
 @param app_param app default is "wifi"
 @param co_param co default is "kjd"
 */
+ (void)setTcpSocket:(TCPSocket *)tcpSocket appParam:(NSString *)app_param co_param:(NSString *)co_param;


/**
 SOCKET 请求

 @param apiName     接口名称
 @param parameters  参数：json 格式的字典
 @param success     成功回调
 @param failure     失败回调
 */
+ (void)socketWithApiName:(NSString *)apiName
               parameters:(id)parameters
                  success:(void(^)(id result))success
                  failure:(void(^)(NSError *error))failure;



/**
 SOCKET 请求

 @param tcpSocket TCPSocket
 @param apiName     接口名称
 @param parameters  参数：json 格式的字典
 @param success     成功回调
 @param failure     失败回调
 */
+ (void)socket:(TCPSocket *)tcpSocket
       apiName:(NSString *)apiName
    parameters:(id)parameters
       success:(void(^)(id result))success
       failure:(void(^)(NSError *error))failure;


/**
 设置请求超时时间

 @param timeOut 超时时间，默认是10s
 */
+ (void)setSocketRequestTimeOut:(NSTimeInterval)timeOut;
@end
