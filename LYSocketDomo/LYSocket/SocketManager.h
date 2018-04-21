//
//  SocketManager.h
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 KJD. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SocketManager;


extern NSString *const SOCKET_SERVER_OFFLINE_NOTI;

@protocol SocketManagerDelegate <NSObject>


/**
 socket连接成功回调

 @param manager socket
 @param host 服务器
 @param port 端口
 */
- (void)socketManager:(SocketManager *)manager didConnectToHost:(NSString *)host port:(uint16_t)port;



/**
 socket连接失败回调

 @param manager socket
 @param error 失败的信息
 */
- (void)socketManager:(SocketManager *)manager didDisconnectWithError:(NSError *)error;


/**
 socket收到数据回调

 @param manager socket
 @param result 结果
 */
- (void)socketManager:(SocketManager *)manager didReadResult:(id)result;



@end


@interface SocketManager : NSObject


/**
 正在连接中
 */
@property (nonatomic, assign, readonly) BOOL isConnecting;

/**
 是否处于连接状态
 */
@property (nonatomic, assign, readonly) BOOL isConnected;


@property (nonatomic, weak) id <SocketManagerDelegate> delegate;



/**
 连接服务器

 @param host        服务器
 @param port        端口
 @param app_param   app_param
 @param co_param    co_param
 @return            socketManager
 */
+ (instancetype) socketManagerWithHost:(NSString *)host port:(uint16_t)port app_param:(NSString *)app_param co_param:(NSString *)co_param;



/**
 连接服务器
 */
- (void)connectToSocketServer;



/**
 发送数据

 @param message 消息的内容
 */
- (void)sendDataToSocket:(NSString *)message;



/**
 用户注册

 @param uuid     设备唯一标识
 @param success  成功回调，成功后会返回 pwd,用于后面身份验证
 @param failure  失败的回调
 */
- (void)appRegistUserUUID:(NSString *)uuid success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;


/**
 身份验证

 @param uuid 设备唯一标识
 @param pwd 用户注册时，服务器返回的pwd
 @param success 成功回调
 @param failure 失败回调
 */
- (void)appConnectWithUUID:(NSString *)uuid pwd:(NSString *)pwd success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;

#pragma mark - help


/**
 发送请求

 @param apiName 接口名称
 @param parameters 参数
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)SOCKET:(NSString *)apiName parameters:(id)parameters success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;


/**
 App 进入前台

 @param onLineBlock socket 在线处理Block
 */
- (void)ApplicationWillEnterFOregroundAndSocketIsOnlineBlock:(void(^)(void))onLineBlock;



/**
 App 进入后台
 */
- (void)ApplicatioinDidEnterBackground;



/**
 设置超时时间

 @param timeOut 超时间
 */
- (void)setSocketRequestTimeOut:(NSTimeInterval)timeOut;


/**
 *  添加打印信息
 */
- (void)allowToPrint;
@end
