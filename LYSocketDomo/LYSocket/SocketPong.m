//
//  SocketPong.m
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 KJD. All rights reserved.
//

#import "SocketPong.h"

static NSInteger _pongTimestamp = 0;

static BOOL _isSocketPonging = NO;

static BOOL _isStoped = NO;

static NSTimeInterval _timeInterval = 13;

// 我已经忘记 block 的几种写法了。
static void (^failure)(id);

@implementation SocketPong

#pragma mark - socket连接心跳
/**
 socket 心跳
 
 @param failure 超时回调
 */
+ (void)setSocketConnectPongFailure:(void(^)(void))failure{
    failure = failure;
}


/**
 设置心跳时间，模式是13秒
 
 @param interval 设置超时时间
 */
+ (void)setSoncketPongTimeInterval:(NSTimeInterval)interval{
    _timeInterval = interval;
}


/**
 开始心跳
 */
+ (void)startSocketPong{
    [self setIsStoped:NO];
    
    if (_isSocketPonging) {// 正在心跳
        
        NSLog(@"正在心跳中。。。");
        return;
    }
    NSLog(@"开始心跳");
    
    _pongTimestamp = [[self timeStamp] integerValue];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        while (!self.isStoped) {
            // 正在心跳标识
            _isSocketPonging = YES;
            
            sleep(_timeInterval);
            
            NSLog(@"时间间隔：%ld", (long)[[self timeStamp] integerValue] - _pongTimestamp);
            
            
            // 超时处理
            if ([[self timeStamp] integerValue] - _pongTimestamp > _timeInterval) {
                
                if (failure) {
                    failure(@"failure");
                }
            }
        }
        // 结束心跳标识
        _isSocketPonging = NO;
        NSLog(@"可以开始心跳");
    });
}


/**
 停止心跳
 */
+ (void)stopSocketPong{
    [self setIsStoped:YES];
}


/**
 刷新心跳时间
 */
+ (void)reloadSocketPongTimestamp{
    _pongTimestamp = [[self timeStamp] integerValue];
}

+ (void)setIsStoped:(BOOL)isStoped{
    _isStoped = isStoped;
}

+ (BOOL)isStoped{
    return _isStoped;
}

// 时间戳：秒

+ (NSString *)timeStamp{
    // 据说这里是一个耗时操作；
    return [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]];
}

@end
