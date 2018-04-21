//
//  SocketManager.m
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/20.
//  Copyright © 2018年 KJD. All rights reserved.
//

#import "SocketManager.h"
#import "TCPSocket.h"
#import "SocketRequest.h"
#import "SocketPong.h"
#import <CommonCrypto/CommonHMAC.h>

NSString *const SOCKET_SERVER_OFFLINE_NOTI = @"socket_server_offline_noti";

#define kAfter_GCD(a, block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(a*NSEC_PER_SEC)), dispatch_get_main_queue(), block)

static BOOL _isAllowToPrint = NO;

#define WZLog(fmt, ...) _isAllowToPrint ? NSLog((@"%s " fmt),__PERTTY_FUNCTION__, ##__VA_ARGS__) : nil

@interface SocketManager()<TCPSocketDelegate>

@property (nonatomic, strong) TCPSocket *tcpSocket;

// socket断开连接次数
@property (nonatomic, assign) int socketOffCount;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) uint16_t port;
@property (nonatomic, copy) NSString *app_param;
@property (nonatomic, copy) NSString *co_param;


@end

@implementation SocketManager

+ (instancetype)socketManagerWithHost:(NSString *)host port:(uint16_t)port app_param:(NSString *)app_param co_param:(NSString *)co_param{

    return [[self alloc] initWithHost:host port:port app_param:app_param co_param:co_param];
}

- (instancetype)initWithHost:(NSString *)host port:(uint16_t)port app_param:(NSString *)app_param co_param:(NSString *)co_param{

    if(self = [super init]){
        self.host = host;
        self.port = port;
        self.app_param = app_param;
        self.co_param = co_param;
        [self setSocketPong];
    }
    return self;
}


/**
 设置心跳及处理
 */
- (void)setSocketPong{
    
    [SocketPong setSocketConnectPongFailure:^() {
        NSLog(@"心跳超时");
        
        [[self class] app_ping_success:^(id result) {
            NSLog(@"socket 正常，不需要重新连接");
        } fail:^(NSError *error) {
            [self connectToSocketServer];
        }];
        
    }];
}

#pragma mark - 公有方法


/**
 发送请求

 @param apiName     接口名称
 @param parameters  参数
 @param success     成功回调
 @param failure     失败回调
 */
+ (void)SOCKET:(NSString *)apiName
    parameters:(id)parameters
       success:(void (^)(id))success
       failure:(void (^)(NSError *))failure{
    [SocketRequest socketWithApiName:apiName parameters:parameters success:success failure:failure];
}


- (void)ApplicationWillEnterFOregroundAndSocketIsOnlineBlock:(void (^)(void))onLineBlock{
    if(!self.isConnected){
        // 不在线。
        [self connectToSocketServer];
        return;
    }
    
    NSLog(@"在线，更新设备状态");
    [[self class] app_ping_success:^(id result) {
        
        [SocketPong startSocketPong];
        if(onLineBlock){
            onLineBlock();
        }
        
    } fail:^(NSError *error) {
        
        [self connectToSocketServer];
    }];
    //
}


/**
 App 进入后台
 */
- (void)ApplicatioinDidEnterBackground{
    [SocketPong stopSocketPong];
}



/**
 连接服务器
 */
- (void)connectToSocketServer{
    if(self.tcpSocket.isConnecting){
        NSLog(@"socket 正在连接中...");
        return;
    }
    [self.tcpSocket connectToHost:self.host onPort:self.port];
}

#pragma mark- 发送请求
- (void)sendDataToSocket:(NSString *)message{
    [self.tcpSocket sendDataToSocket:message];
}


- (void)appRegistUserUUID:(NSString *)uuid success:(void (^)(id))success failure:(void (^)(NSError *))failure{
    NSString *timestamp = [self timeStamp];
    
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    paramDic[@"uuid"] = uuid;
    paramDic[@"timestamp"] = timestamp;
    paramDic[@"pwd"] = [self md5StringFromString:[NSString stringWithFormat:@"%@%@%@", @"kdkdkdk8394y5fnwoejfs93u49tjf,.3049jrfjslfjsdfs", uuid, timestamp]];
    
    [SocketRequest socketWithApiName:@"app_regist_user" parameters:paramDic success:success failure:failure];
}

#pragma mark - 身份验证

- (void)appConnectWithUUID:(NSString *)uuid pwd:(NSString *)pwd success:(void (^)(id))success failure:(void (^)(NSError *))failure{

    //当前的时间戳
    NSString *timestamp = [self timeStamp];
    
    NSMutableDictionary *mParamDict = [NSMutableDictionary dictionary];
    mParamDict[@"uuid"] = uuid;
    mParamDict[@"timestamp"] = [self timeStamp];
    
    mParamDict[@"pwd"] = [self md5StringFromString:[NSString stringWithFormat:@"%@%@%@",@"ilsdkjfsldfjlwfioejfwkfsdjvihsoverklnrf34u392485u9rjsoidfnj3948uthgrf",pwd,timestamp]];
    
    [SocketRequest socketWithApiName:@"app_client_connect" parameters:mParamDict success:success failure:failure];

}

#pragma mark - 心跳
+ (void)app_ping_success:(void(^)(id result))succes fail:(void(^)(NSError *error))fail{
    NSString *api_name = @"ping";
    
    [SocketRequest setSocketRequestTimeOut:1];
    
    [SocketRequest socketWithApiName:api_name parameters:[NSDictionary dictionary] success:^(id result) {
        [SocketRequest setSocketRequestTimeOut:10.0];
        if(succes){
            succes(result);
        }
    } failure:^(NSError *error) {
        [SocketRequest setSocketRequestTimeOut:10.0];
        if(fail){
            fail(error);
        }
    }];
}


#pragma mark - SocketDelegate


/**
 socket连接成功回调
 */
- (void)tcpSocket:(TCPSocket *)socket didConnectToHost:(NSString *)host port:(uint16_t)port{
    
    self.socketOffCount = 0;
    
    [SocketPong startSocketPong];
    
    if([_delegate respondsToSelector:@selector(socketManager:didConnectToHost:port:)]){
        [_delegate socketManager:self didConnectToHost:host port:port];
    }
}


/**
 socket连接失败回调
 */
- (void)tcpSocket:(TCPSocket *)tcpSocket didDisconnectWithError:(NSError *)error{
    
    if(!error){
        // 正常断开
        NSLog(@"------正常断开------");
    }else{
        // 非正常断开
        [self starReconnectWithError:error];
    }
    
    // 停止心跳
    [SocketPong startSocketPong];
    
    if([_delegate respondsToSelector:@selector(socketManager:didDisconnectWithError:)]){
        [_delegate socketManager:self didDisconnectWithError:error];
    }
    
}


/**
 收到数据的回调
 */
-(void)tcpSocket:(TCPSocket *)tcpSocket didReadResult:(id)result{
    if(![result isKindOfClass:[NSDictionary class]]){
        return;
    }
    
    if([result[@"type"] isEqualToString:@"ping"]){
        NSLog(@"心跳包");
        [SocketPong reloadSocketPongTimestamp];
        return;
    }
    
    if([_delegate respondsToSelector:@selector(socketManager:didReadResult:)]){
        [_delegate socketManager:self didReadResult:result];
    }
}

#pragma mark - 重连机制
-(void)starReconnectWithError:(NSError *)error{
    NSLog(@"异常断开次数：%d,%@， %@\n", self.socketOffCount, [NSThread currentThread], error.userInfo);
    
    self.socketOffCount ++;
    if(self.socketOffCount <= 3){
        // 重连
        
        kAfter_GCD(1.5, ^{
            if (!self.tcpSocket.isConnected) {
                [self connectToSocketServer];
            }else{
                NSLog(@"socket已在线");
            }
        });
        
        if (self.socketOffCount == 2) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SOCKET_SERVER_OFFLINE_NOTI object:nil];
        }
        
    }else{
        [[NSNotificationCenter defaultCenter] postNotificationName:SOCKET_SERVER_OFFLINE_NOTI object:nil];
        NSLog(@"重连机制");
        kAfter_GCD(10, ^{
            if (!self.tcpSocket.isConnected) {
                [self connectToSocketServer];
            }
        });
    }
    
}



#pragma mark - help

- (BOOL)isConnected{
    
    return self.tcpSocket.isConnected;
}
- (BOOL)isConnecting{
    
    return self.tcpSocket.isConnecting;
}


/**
 *  设置请求超时时间
 *
 *  @param timeOut 超时时间， default is 10s
 */
- (void)setSocketRequsetTimeOut:(NSTimeInterval)timeOut{
    
    [SocketRequest setSocketRequestTimeOut:timeOut];
}

/**
 *  允许打印
 */
- (void)allowToPrint{
    
    _isAllowToPrint = YES;
    
    [self.tcpSocket allowToPrint];
}


/**
 时间戳

 @return 时间戳字符串，从1970 年开始
 */
- (NSString *)timeStamp{
    return [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]];
}



/**
 MD5 加密

 @param normalString 传进来
 @return 返回的已加密的字符串
 */
- (NSString *)md5StringFromString:(NSString *)normalString{
    const char *string = normalString.UTF8String;
    int length = (int)strlen(string);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, length, bytes);
    return [self stringFromBytes:bytes length:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)stringFromBytes:(unsigned char *)bytes length:(NSUInteger)length{
    NSMutableString *mutablesString = [NSMutableString new];
    for(int i = 0; i < length; i++){
        [mutablesString appendFormat:@"%02x", bytes[i]];
    }
    return [NSString stringWithString:mutablesString];
}



@end
