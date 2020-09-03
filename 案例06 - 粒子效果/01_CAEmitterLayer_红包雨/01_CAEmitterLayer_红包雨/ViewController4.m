//
//  ViewController4.m
//  01_CAEmitterLayer_红包雨
//
//  Created by Qiong Huang on 2020/9/4.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController4.h"

@interface ViewController4 ()

@end

@implementation ViewController4

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self rainAll];
}

- (void)rainAll{
    CAEmitterLayer* rainLayer = [[CAEmitterLayer alloc] init];
    [self.view.layer addSublayer:rainLayer];
    
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10);
    
    CAEmitterCell* snowCell_zongzi = [CAEmitterCell emitterCell];
    snowCell_zongzi.contents = (id)[[UIImage imageNamed:@"zongzi.png"] CGImage];
    snowCell_zongzi.birthRate = 1.0;
    snowCell_zongzi.lifetime = 30;
    snowCell_zongzi.speed = 2;
    snowCell_zongzi.velocity = 10.0f;
    snowCell_zongzi.velocityRange = 10.0f;
    snowCell_zongzi.yAcceleration = 60;
    snowCell_zongzi.scale = 0.05;
    snowCell_zongzi.scaleRange = 0.0f;
    
    CAEmitterCell* snowCell_hongbao = [CAEmitterCell emitterCell];
    snowCell_hongbao.contents = (id)[[UIImage imageNamed:@"hongbao.png"] CGImage];
    snowCell_hongbao.birthRate = 1.0;
    snowCell_hongbao.lifetime = 30;
    snowCell_hongbao.speed = 2;
    snowCell_hongbao.velocity = 10.0f;
    snowCell_hongbao.velocityRange = 10.0f;
    snowCell_hongbao.yAcceleration = 60;
    snowCell_hongbao.scale = 0.05;
    snowCell_hongbao.scaleRange = 0.0f;
    
    CAEmitterCell* snowCell_jinbi = [CAEmitterCell emitterCell];
    snowCell_jinbi.contents = (id)[[UIImage imageNamed:@"jinbi.png"] CGImage];
    snowCell_jinbi.birthRate = 1.0;
    snowCell_jinbi.lifetime = 30;
    snowCell_jinbi.speed = 2;
    snowCell_jinbi.velocity = 10.0f;
    snowCell_jinbi.velocityRange = 10.0f;
    snowCell_jinbi.yAcceleration = 60;
    snowCell_jinbi.scale = 0.05;
    snowCell_jinbi.scaleRange = 0.0f;
    
    rainLayer.emitterCells = @[snowCell_zongzi, snowCell_hongbao, snowCell_jinbi];
}

@end
