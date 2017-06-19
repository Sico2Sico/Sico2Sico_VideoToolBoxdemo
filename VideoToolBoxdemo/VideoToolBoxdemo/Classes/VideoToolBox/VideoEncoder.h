//
//  VideoEncoder.h
//  VideoToolBoxdemo
//
//  Created by 吴德志 on 2017/6/18.
//  Copyright © 2017年 Sico2Sico. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>

@interface VideoEncoder : NSObject

-(void)enCoderSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)EndEnCoder;

@end
