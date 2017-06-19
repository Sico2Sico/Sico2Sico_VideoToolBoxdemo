
//
//  VideoCamer.m
//  VideoToolBoxdemo
//
//  Created by 吴德志 on 2017/6/18.
//  Copyright © 2017年 Sico2Sico. All rights reserved.
//

#import "VideoCamer.h"
#import "VideoEncoder.h"
#import <AVFoundation/AVFoundation.h>


@interface VideoCamer()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

//编码对象
@property (nonatomic, strong) VideoEncoder *encode;
//捕获会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
//预览图成
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * preViewLayer;
//捕获会话队列
@property (nonatomic, strong) dispatch_queue_t captureQueue;

@end

@implementation VideoCamer

-(void)startCapture:(UIView *)preView{
    
    //初始化编码对象
    self.encode = [[VideoEncoder alloc]init];
    
    //1 创建捕获对象
    self.captureSession = [[AVCaptureSession alloc]init];
    self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    
    //设置输入设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }
    
    //设置输出设备
    AVCaptureVideoDataOutput * output = [[AVCaptureVideoDataOutput alloc]init];
    if ([self.captureSession canAddOutput:output]) {
        [self.captureSession addOutput:output];
    }
    self.captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [output setSampleBufferDelegate:self queue:self.captureQueue];
    
    //设置录取视频的方向
    AVCaptureConnection * connecton = [output connectionWithMediaType:AVMediaTypeVideo];
    [connecton setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    //设置预览图成
    self.preViewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
    self.preViewLayer.frame = preView.bounds;
    [preView.layer insertSublayer:self.preViewLayer atIndex:0];
    
    [self.captureSession startRunning];

}

-(void)stopCapture{
    [self.captureSession stopRunning];
    [self.preViewLayer removeFromSuperlayer];
    [self.encode  EndEnCoder];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    [self.encode enCoderSampleBuffer:sampleBuffer];

}



@end
