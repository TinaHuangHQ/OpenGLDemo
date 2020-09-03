//
//  ViewController.m
//  01_CAEmitterLayer_红包雨
//
//  Created by Qiong Huang on 2020/9/3.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self rainZongzi];
}

-(void)rainZongzi{
    //1. 设置CAEmitterLayer
    CAEmitterLayer* rainLayer = [[CAEmitterLayer alloc] init];
    
    //2.在背景图上添加粒子图层
    [self.view.layer addSublayer:rainLayer];
    
    //3.发射形状--线性
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
    
    //4. 配置cell
    CAEmitterCell* snowCell = [CAEmitterCell emitterCell];
    snowCell.contents = (id)[[UIImage imageNamed:@"hongbao.png"] CGImage];
    snowCell.birthRate = 1.0;
    snowCell.lifetime = 30;
    snowCell.speed = 2.0f;
    snowCell.velocity = 10.0f;
    snowCell.velocityRange = 10.0f;
    snowCell.yAcceleration = 60;
    snowCell.scale = 0.05;
    snowCell.scaleRange = 0.0f;
    
    // 3.添加到图层上
    rainLayer.emitterCells = @[snowCell];
}


@end
