//
//  ViewController.m
//  LYSocketDomo
//
//  Created by 林一 on 2018/4/18.
//  Copyright © 2018年 KJD. All rights reserved.
//

#import "ViewController.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
@interface ViewController ()<GCDAsyncSocketDelegate>
@property (strong, nonatomic) GCDAsyncSocket *clientSocket;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 1.初始化
    self.clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSError *error = nil;
    
//    self.clientSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    BOOL isConnect = [self.clientSocket connectToHost:@"120.76.27.28" onPort:27411 viaInterface:nil withTimeout:-1 error:&error];
    
    
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self showMessageWithStr:@"链接成功"];
    NSLog(@"链接成功");
    
    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP: %@", host]];
    //    NSLog(@"%@",_clientSocket);
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
    
    
}

// 收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showMessageWithStr:text];
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
}




// 信息展示
- (void)showMessageWithStr:(NSString *)str {
    NSLog(@"%@",str);
//    self.showMessageTF.text = [self.showMessageTF.text stringByAppendingFormat:@"%@\n", str];
}



// 链接成功

//- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
//
//    NSLog(@"链接成功");
//}

// 链接失败
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    
    NSLog(@"链接失败 err = %@",err);
}

@end
