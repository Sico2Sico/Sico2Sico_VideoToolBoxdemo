//
//  VideoCamer.h
//  VideoToolBoxdemo
//
//  Created by 吴德志 on 2017/6/18.
//  Copyright © 2017年 Sico2Sico. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCamer : NSObject

-(void)startCapture:(UIView*)preView;

-(void)stopCapture;

@end
