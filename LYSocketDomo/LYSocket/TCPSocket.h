//
//  TCPSocket.h
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/19.
//  Copyright © 2018年 KJD. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCPSocket;

@protocol TCPSocketDelegate <NSObject>


/**
 socket 连接成功回调

 @param socket socket 实例
 @param host 服务器地址
 @param port 端口
 */
-(void)tcpSocket:(TCPSocket *)socket didConnectToHost:(NSString *)host port:(uint16_t)port;


/**
 socket 连接失败回调

 @param tcpSocket Socket 实例
 @param error 错误信息
 */
-(void)tcpSocket:(TCPSocket *)tcpSocket didDisconnectWithError:(NSError *)error;

-(void)tcpSocket:(TCPSocket *)tcpSocket didReadResult:(id)result;

@end


@interface TCPSocket : NSObject

@property (nonatomic, weak) id<TCPSocketDelegate> tcpDelegate;


@property (nonatomic, assign, readonly) BOOL isConnecting; // 是否正在连接中

@property (nonatomic, assign, readonly) BOOL isConnected;   // 连接状态



/**
 连接 Socket

 @param host 服务器地址
 @param port 端口
 */
- (void)connectToHost:(NSString *)host onPort:(uint16_t)port;



/**
 断开连接
 */
- (void)disconnectSocket;



/**
 向 Socket 发送数据

 @param message 字符串数据
 */
- (void)sendDataToSocket:(NSString *)message;

#pragma mark - help


/**
 允许打印
 */
-(void)allowToPrint;

@end
