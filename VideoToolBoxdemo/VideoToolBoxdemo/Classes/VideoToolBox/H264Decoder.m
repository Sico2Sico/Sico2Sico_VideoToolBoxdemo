//
//  H265Decoder.m
//  testp2p
//
//  Created by libin li on 2024/6/29.
//  Copyright © 2024 libin li. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "H265Decoder.h"


@implementation H265Decoder
{
    dispatch_queue_t mDecodeQueue;
    uint8_t*       packetBuffer;
    
}

- (instancetype)initWithImageView:(UIImageView *)imageView {
    self = [super init];
    if (self) {
        _imageView = imageView;
        _decompressionSession = NULL;
        _formatDescription = NULL;
        mDecodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (void)dealloc {
    if (_decompressionSession) {
        VTDecompressionSessionInvalidate(_decompressionSession);
        CFRelease(_decompressionSession);
        _decompressionSession = NULL;
    }
    if (_formatDescription) {
        CFRelease(_formatDescription);
        _formatDescription = NULL;
    }
}



void decompressionOutputCallback(void *decompressionOutputRefCon,
                                 void *sourceFrameRefCon,
                                 OSStatus status,
                                 VTDecodeInfoFlags infoFlags,
                                 CVImageBufferRef imageBuffer,
                                 CMTime presentationTimeStamp,
                                 CMTime presentationDuration) {
    if (status != noErr) {
        NSLog(@"Error in decompression callback: %d", (int)status);
        return;
    }

    H265Decoder *decoder = (__bridge H265Decoder *)decompressionOutputRefCon;
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];

    dispatch_async(dispatch_get_main_queue(), ^{
        decoder.imageView.image = uiImage;
    });

    CGImageRelease(cgImage);
}


- (void)decodeNalu:(uint8_t *)frame size:(uint32_t)frameSize {
    int offset = 0;
    while (offset < frameSize - 4) {
        // 查找起始码 `00 00 00 01`
        if (frame[offset] == 0 && frame[offset + 1] == 0 && frame[offset + 2] == 0 && frame[offset + 3] == 1) {
            offset += 4;
        } else {
            break;
        }
        
        int start = offset;
        uint32_t nextNaluStart = frameSize;
        
        // 查找下一个 NALU 的起始码
        for (int i = offset; i < frameSize - 4; i++) {
            if (frame[i] == 0 && frame[i + 1] == 0 && frame[i + 2] == 0 && frame[i + 3] == 1) {
                nextNaluStart = i;
                break;
            }
        }
        
        uint32_t naluLength = nextNaluStart - start;
        if (naluLength <= 0) {
            break;
        }
        
        // 获取 NALU 类型
        int naluType = frame[start] & 0x1F;
        CVPixelBufferRef pixelBuffer = NULL;
        
        // 填充 NALU size，去掉 start code 替换成 NALU size
        uint32_t nalSize = naluLength;
        uint8_t *pNalSize = (uint8_t *)(&nalSize);
        frame[start - 4] = pNalSize[3];
        frame[start - 3] = pNalSize[2];
        frame[start - 2] = pNalSize[1];
        frame[start - 1] = pNalSize[0];
        
        switch (naluType) {
            case 0x05:
                // 关键帧
                if ([self initH264Decoder]) {
                    [self decode:frame + start - 4 size:nalSize + 4];
                }
                break;
            case 0x07:
                // SPS
                _spsSize = nalSize;
                _sps = [NSData dataWithBytes:frame + start length:_spsSize];
                break;
            case 0x08:
                // PPS
                _ppsSize = nalSize;
                _pps = [NSData dataWithBytes:frame + start length:_ppsSize];
                break;
            default:
                // B/P 帧
//                if ([self initH264Decoder]) {
                    [self decode:frame + start - 4 size:nalSize + 4];
//                }
                break;
        }
        
        offset = nextNaluStart;
    }
}


- (void)decode:(uint8_t *)frame size:(uint32_t)frameSize {
    NSData *frameData = [NSData dataWithBytes:frame length:frameSize];
    
    if (!_decompressionSession) {
        [self initH264Decoder];
        if (!_decompressionSession) {
            NSLog(@"Failed to create decompression session");
            return;
        }
    }

    // 解码视频帧
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(
        kCFAllocatorDefault,
        (void *)frameData.bytes,
        frameData.length,
        kCFAllocatorNull,
        NULL,
        0,
        frameData.length,
        0,
        &blockBuffer
    );
    if (status != kCMBlockBufferNoErr) {
        NSLog(@"Error creating block buffer: %d", (int)status);
        return;
    }
    
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = { frameData.length };
    status = CMSampleBufferCreateReady(
        kCFAllocatorDefault,
        blockBuffer,
        _formatDescription,
        1,
        0,
        NULL,
        1,
        sampleSizeArray,
        &sampleBuffer
    );
    if (status != noErr) {
        NSLog(@"Error creating sample buffer: %d", (int)status);
        CFRelease(blockBuffer);
        return;
    }
    
    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;
    status = VTDecompressionSessionDecodeFrame(
        _decompressionSession,
        sampleBuffer,
        flags,
        NULL,
        &flagOut
    );

    if (status != noErr) {
        NSLog(@"Error decoding frame: %d", (int)status);
    }

    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
}

- (BOOL)initH264Decoder{
    if(_decompressionSession){
        return YES;
    }
    
//    const uint8_t* parameterSetPointers[2] = { _spsData.bytes, _ppsData.bytes };
//    const size_t parameterSetSizes[2] = { _spsData.length, _ppsData.length };
    
    const uint8_t* parameterSetPointers[2] = { self.sps.bytes, self.pps.bytes };
       const size_t parameterSetSizes[2] = { self.spsSize, self.ppsSize };
    
    //用sps 和pps 实例化_decoderFormatDescription
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //参数个数
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal startcode开始的size
                                                                          &_formatDescription);
    
    if(status == noErr) {
        NSDictionary* destinationPixelBufferAttributes = @{
                                                           (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
                                                           //硬解必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                                           //                                                           或者是kCVPixelFormatType_420YpCbCr8Planar
                                                           //因为iOS是  nv12  其他是nv21
                                                           (id)kCVPixelBufferWidthKey : [NSNumber numberWithInt:1280],
                                                           (id)kCVPixelBufferHeightKey : [NSNumber numberWithInt:960],
                                                           //这里宽高和编码反的 两倍关系
                                                           (id)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:YES]
                                                           };

        
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = decompressionOutputCallback;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _formatDescription,
                                              NULL,
                                              (__bridge CFDictionaryRef)destinationPixelBufferAttributes,
                                              &callBackRecord,
                                              &_decompressionSession);
        VTSessionSetProperty(_decompressionSession, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
        VTSessionSetProperty(_decompressionSession, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
    } else {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
        return NO;
    }
    
    return YES;
}


@end
