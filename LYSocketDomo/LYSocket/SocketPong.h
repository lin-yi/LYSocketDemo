//
//  SocketPong.h
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 众车在线. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketPong : NSObject


/**
 socket 心跳

 @param failure 超时回调
 */
+ (void)setSocketConnectPongFailure:(void(^)(id))failure;


/**
 设置心跳时间，模式是13秒

 @param interval 设置超时时间
 */
+ (void)setSoncketPongTimeInterval:(NSTimeInterval)interval;


/**
 刷新心跳时间
 */
+ (void)reloadSocketPongTimestamp;


/**
 开始心跳
 */
+ (void)startSocketPong;


/**
 停止心跳
 */
+ (void)stopSocketPong;

@end
