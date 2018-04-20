//
//  TCPSocket.m
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/19.
//  Copyright © 2018年 众车在线. All rights reserved.
//

#import "TCPSocket.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

static BOOL _isAllowToPrint = NO;
#define LYLog(fmt, ...) _isAllowToPrint ? NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__) : nil

// G-C-D
// 主线程
#define MAIN_GCD(block) dispatch_async(dispatch_get_main_queue(), block)


@interface NSString (Json)
/**
 json 字符串格式化
 */
-(NSString *)jsonFormat;
@end

@interface SocketResult : NSObject

@property (nonatomic, copy) NSString *app;
@property (nonatomic, copy) NSString *co;
@property (nonatomic, copy) NSString *api;
@property (nonatomic, copy) NSString *retcode;
@property (nonatomic, copy) NSString *retmsg;
@property (nonatomic, strong) id data;

+ (instancetype)socketResultWithResult:(id)result;
@end


@implementation SocketResult

+ (instancetype)socketResultWithResult:(id)result{
    return [[self alloc] initWitResutl:result];
}

- (instancetype)initWitResutl:(id)result{
    if(self = [super init]){
        _app = result[@"app"];
        _co = result[@"co"];
        _api = result[@"api"];
        _retcode = result[@"result"];
        _retmsg = result[@"data"];
    }
    return self;
}

@end



@interface TCPSocket ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;

@end

@implementation TCPSocket

static int const kConnectTimeOut = 4;

static int const kReadTimeOut = -1;

static int const kWriteDataTag = 1;

static int const kReadDataTag = 0;


#pragma mark - 连接 socket
- (void)connectToHost:(NSString *)host onPort:(uint16_t)port{
    _isConnecting = YES;
    // 不能对一个已经连接 socket 进行重连
    [self disconnectSocket];
    
    NSError *error = nil;
    LYLog(@"开始连接到服务器");
    
    if(![self.socket connectToHost:[self convertedHostFromHost:host] onPort:port withTimeout:kConnectTimeOut error:&error] || error){
        LYLog(@"connet fail error: %@",error);
    }
}

#pragma mark - 断开连接
- (void)disconnectSocket{
    if(self.socket.isConnected){
        [self.socket disconnect];
        LYLog(@"disconnect socket");
    }
}

#pragma mark - 发送请求
- (void)sendDataToSocket:(NSString *)message{
    LYLog(@"send data to socket ,message is %@", message);
    
    // 这样的判断是否严谨？只接受字符串？
    if(!message || message.length == 0){
        return;
    }
    
    // 对信息的格式进行处理
    if ([message rangeOfString:@"'"].length>0) {
        message = [message stringByReplacingOccurrencesOfString:@"'" withString:@""];
    }
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.socket writeData:data withTimeout:-1 tag:kWriteDataTag];
}

#pragma mark - GCDAsyncSocketDelegate

#pragma mark - 连接成功回调
- (void)socket:(GCDAsyncSocket *)socket didConnectToHost:(NSString *)host port:(uint16_t)port{
    _isConnecting = NO;
    
    MAIN_GCD(^{
        if([self.tcpDelegate respondsToSelector:@selector(tcpSocket:didConnectToHost:port:)]){
            [self.tcpDelegate tcpSocket:self didConnectToHost:host port:port];
        }
    });
    [socket readDataToData:[GCDAsyncSocket LFData] withTimeout:kReadTimeOut tag:kReadDataTag];
}


#pragma mark - socket 断线回调
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    _isConnecting = NO;
    
    MAIN_GCD(^{
        if([self.tcpDelegate respondsToSelector:@selector(socketDidDisconnect:withError:)]){
            [self.tcpDelegate tcpSocket:self didDisconnectWithError:err];
        }
    });
}

#pragma mark - 写成功
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    // 写成功后开始读数据
    [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:kReadDataTag tag:kReadDataTag];
}

#pragma mark - 收到数据回调
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    // 数据长度不足，继续读数据
    if(data.length <= GCDAsyncSocket.LFData.length){
        [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:kReadTimeOut tag:kReadDataTag];
        return;
    }
    
    // 删掉最后[GCDAsyncSocket LFData]'\n'
    data = [data subdataWithRange:NSMakeRange(0, data.length-[GCDAsyncSocket LFData].length)];
    
    // 转string
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    LYLog(@"readText.leng = %d, json format = %@",(int)data.length,[text jsonFormat]);
    
    // 转字典
    id jsonResult = [self jsonSerializationWithString:text];
    
    NSString *retcode = nil;
    
    NSString *retmsg = nil;
    
    NSString *noti_name = nil;
    
    id object = nil;
    
    if([jsonResult isKindOfClass:[NSError class]]){// json 解析失败
        
        retcode = @"-1";
        retmsg = [[[(NSError *)jsonResult userInfo] allValues] lastObject];
        noti_name = @"ly_error_noti";
        
    }else if(!jsonResult || ![jsonResult isKindOfClass:[NSDictionary class]]){
        // 不存在或不是字典
        
        retcode = @"-1";
        retmsg = @"空数据";
        noti_name = @"ly_error_noti";
        
    }else{ // 有效数据
        SocketResult *socketResult = [SocketResult socketResultWithResult:jsonResult];
        retcode = socketResult.retcode ? socketResult.retcode : @"";
        retmsg = socketResult.retmsg ? socketResult.retmsg : @"";
        noti_name = [NSString stringWithFormat:@"ly_%@",socketResult.api];
        object = socketResult.data;
    }
    
    MAIN_GCD(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:noti_name object:object userInfo:@{retcode : retmsg}];
        
        if([self.tcpDelegate respondsToSelector:@selector(tcpSocket:didReadResult:)]){
            [self.tcpDelegate tcpSocket:self didReadResult:jsonResult];
        }
    });
    
    [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:kReadTimeOut tag:kReadDataTag];
    
}

#pragma mark - help
/**
 允许打印
 */
-(void)allowToPrint{
    _isAllowToPrint = YES;
}

/**
*  json string ==> 字典
*/
- (id)jsonSerializationWithString:(NSString *)jsonString{
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    // 转字典
    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        return error;
    }else{
        return result;
    }
}

/**
 *  ip转换(ipv6 ip转换)
 *
 *  @param host 旧host
 *
 *  @return 新ip
 */

- (NSString *)convertedHostFromHost:(NSString *)host{
    
    NSError *err = nil;
    
    NSMutableArray *addresses = [GCDAsyncSocket lookupHost:host port:0 error:&err];
    
    //    WZLog(@"address%@",addresses);
    
    NSData *address4 = nil;
    NSData *address6 = nil;
    
    for (NSData *address in addresses)
    {
        if (!address4 && [GCDAsyncSocket isIPv4Address:address])
        {
            address4 = address;
        }
        else if (!address6 && [GCDAsyncSocket isIPv6Address:address])
        {
            address6 = address;
        }
    }
    
    NSString *ip;
    
    if (address6) {
        LYLog(@"===ipv6===：%@",[GCDAsyncSocket hostFromAddress:address6]);
        ip = [GCDAsyncSocket hostFromAddress:address6];
    }else {
        LYLog(@"===ipv4===：%@",[GCDAsyncSocket hostFromAddress:address4]);
        ip = [GCDAsyncSocket hostFromAddress:address4];
    }
    
    return ip;
    
}

-(GCDAsyncSocket *)socket{
    if(!_socket){
        dispatch_queue_t socketQueue = dispatch_queue_create("FirstSerialQueue", DISPATCH_QUEUE_SERIAL);
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
        _socket.IPv4PreferredOverIPv6 = NO;
    }
    return _socket;
}

@end

#pragma mark - json

@implementation NSString (Json)
/**
 *  json字符串格式化
 */
- (NSString *)jsonFormat{
    
    NSString *spacing = @"\t";
    NSString *enterKey = @"\n";
    
    NSMutableString *mString = [NSMutableString string];
    
    int number = 0;
    
    // 添加空格block
    NSString *(^addSpaceBlock)(int) = ^NSString *(int num){
        NSMutableString *mString = [NSMutableString string];
        for (int i = 0; i < num; i++) {
            [mString appendString:spacing];
        }
        return mString;
    };
    
    //遍历输入字符串。
    for (int i = 0; i < self.length; i++) {
        
        //1、获取当前字符。
        NSString *subStr = [self substringWithRange:NSMakeRange(i, 1)];
        
        //2、如果当前字符是前方括号、前花括号做如下处理：
        if ([subStr isEqualToString:@"["] || [subStr isEqualToString:@"{"]) {
            
            // (1）如果前面还有字符，并且字符为“：”，打印：换行和缩进字符字符串。
            if ((i-1>0) && [[self substringWithRange:NSMakeRange(i-1, 1)] isEqualToString:@":"]) {
                [mString appendString:enterKey];
                [mString appendString:addSpaceBlock(number)];
            }
            //（2）打印：当前字符。
            [mString appendString:subStr];
            
            //（3）前方括号、前花括号，的后面必须换行。打印：换行。
            [mString appendString:enterKey];
            
            //（4）每出现一次前方括号、前花括号；缩进次数增加一次。打印：新行缩进。
            number++;
            [mString appendString:addSpaceBlock(number)];
            
            //（5）进行下一次循环。
            continue;
        }
        
        //3、如果当前字符是后方括号、后花括号做如下处理：
        if ([subStr isEqualToString:@"]"]||[subStr isEqualToString:@"}"]) {
            //（1）后方括号、后花括号，的前面必须换行。打印：换行。
            [mString appendString:enterKey];
            //（2）每出现一次后方括号、后花括号；缩进次数减少一次。打印：缩进。
            number--;
            [mString appendString:addSpaceBlock(number)];
            //（3）打印：当前字符。
            [mString appendString:subStr];
            //（4）如果当前字符后面还有字符，并且字符不为“，”，打印：换行。
            if (((i+1)>self.length) && ![[self substringWithRange:NSMakeRange(i+1, 1)] isEqualToString:@","]) {
                [mString appendString:enterKey];
            }
            //（5）继续下一次循环。
            continue;
        }
        
        //4、如果当前字符是逗号。逗号后面换行，并缩进，不改变缩进次数。
        if ([subStr isEqualToString:@","]) {
            [mString appendString:subStr];
            [mString appendString:enterKey];
            [mString appendString:addSpaceBlock(number)];
            continue;
        }
        [mString appendString:subStr];
    }
    return mString;
}
@end
