//
//  ViewController2.m
//  01_CAEmitterLayer_红包雨
//
//  Created by Qiong Huang on 2020/9/4.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController2.h"

@interface ViewController2 ()

@end

@implementation ViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self rainHongBao];
}

- (void)rainHongBao{
    CAEmitterLayer* rainLayer = [[CAEmitterLayer alloc] init];
    [self.view.layer addSublayer:rainLayer];
    
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
    
    CAEmitterCell* snowCell = [[CAEmitterCell alloc] init];
    snowCell.contents = (id)[[UIImage imageNamed:@"zongzi.png"] CGImage];
    snowCell.birthRate = 1.0;
    snowCell.lifetime = 30;
    snowCell.speed = 2;
    snowCell.velocity = 10.0f;
    snowCell.velocityRange = 10.0f;
    snowCell.yAcceleration = 60;
    snowCell.scale = 0.05;
    snowCell.scaleRange = 0.0f;
    
    rainLayer.emitterCells = @[snowCell];
}

@end
