//
//  ViewController3.m
//  01_CAEmitterLayer_红包雨
//
//  Created by Qiong Huang on 2020/9/4.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController3.h"

@interface ViewController3 ()

@end

@implementation ViewController3

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self rainJinBi];
}

- (void)rainJinBi{
    CAEmitterLayer* rainLayer = [[CAEmitterLayer alloc] init];
    [self.view.layer addSublayer:rainLayer];
    
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
    
    CAEmitterCell* snowCell = [CAEmitterCell emitterCell];
    snowCell.contents = (id)[[UIImage imageNamed:@"jinbi.png"] CGImage];
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
