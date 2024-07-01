//
//  H265Decoder.h
//  testp2p
//
//  Created by libin li on 2024/6/29.
//  Copyright © 2024 libin li. All rights reserved.
//

#ifndef H265Decoder_h
#define H265Decoder_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>

@interface H265Decoder : NSObject

- (instancetype)initWithImageView:(UIImageView *)imageView;
- (void)decodeFrameData:(NSData *)frameData;
- (void)decodeNalu:(uint8_t *)frame size:(uint32_t)frameSize;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) CMFormatDescriptionRef formatDescription;
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;

@end

#endif /* H265Decoder_h */
