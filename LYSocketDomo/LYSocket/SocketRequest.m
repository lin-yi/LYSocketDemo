//
//  SocketRequest.m
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 众车在线. All rights reserved.
//

#import "SocketRequest.h"


typedef void (^kCallBackBlock)(id);

static NSString *APP_PARAM = @"smart";
static NSString *CO_PARAM = @"kjd";
static NSMutableDictionary *_successBlockDic;
static NSMutableDictionary *_failureBlockDic;
static NSTimeInterval requestTimeOut = 10;

// const 关键字的作用，组合的作用。
static NSString *const ERROR_NOTI_NAME = @"ly_error_noti";
static TCPSocket *tcpScoket = nil;

@implementation SocketRequest

@end
