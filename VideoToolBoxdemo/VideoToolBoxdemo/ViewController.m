//
//  ViewController.m
//  VideoToolBoxdemo
//
//  Created by 吴德志 on 2017/6/18.
//  Copyright © 2017年 Sico2Sico. All rights reserved.
//

#import "ViewController.h"
#include "VideoCamer.h"

@interface ViewController ()
@property (nonatomic, strong) VideoCamer * Videcamer;
@property (weak, nonatomic) IBOutlet UIButton *stopbut;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect frame = self.stopbut.frame;
    frame.size = CGSizeMake(45, 45);
    self.stopbut.frame = frame;
    self.stopbut.layer.borderColor = [UIColor greenColor].CGColor;
    self.stopbut.layer.cornerRadius = 5;
    self.stopbut.layer.borderWidth = 2;
    self.stopbut.layer.masksToBounds = YES;
    
    [self.stopbut addTarget:self action:@selector(stopcaputre) forControlEvents:UIControlEventTouchUpInside];
    self.Videcamer = [[VideoCamer alloc]init];
    [self.Videcamer startCapture:self.view];
    
}


-(void)stopcaputre{

    [self.Videcamer stopCapture];
}


@end
