//
//  ViewController.m
//  02_CAEmitterLayer_点击产生粒子
//
//  Created by macbook pro on 2020/9/4.
//  Copyright © 2020 hq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) CAEmitterLayer * colorBallLayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self setupEmitter];
}
- (void)setupEmitter{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 50)];
    [self.view addSubview:label];
    label.textColor = [UIColor whiteColor];
    label.text = @"轻点或拖动来改变发射源位置";
    label.textAlignment = NSTextAlignmentCenter;
    
    CAEmitterLayer* layer = [[CAEmitterLayer alloc] init];
    self.colorBallLayer = layer;
    [self.view.layer addSublayer:layer];
    
    layer.emitterSize = self.view.frame.size;
    layer.emitterShape = kCAEmitterLayerPoint;
    layer.emitterMode = kCAEmitterLayerPoints;
    layer.emitterPosition = CGPointMake(self.view.layer.bounds.size.width*0.5, 70.0f);
    
    CAEmitterCell* cell = [CAEmitterCell emitterCell];
    cell.name = @"colorBallCell";
    cell.birthRate = 20.0f;
    cell.lifetime = 10.0f;
    cell.velocity = 40.0f;
    cell.velocityRange = 100.0f;
    cell.yAcceleration = 15.0f;
    cell.emissionLongitude = M_PI;
    cell.emissionRange = M_PI_4;
    cell.scale = 0.2;
    cell.scaleRange = 0.1;
    cell.scaleSpeed = 0.02;
    
    cell.contents = (id)[[UIImage imageNamed:@"circle_white"] CGImage];
    cell.color = [[UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0] CGColor];
    cell.redRange = 1.0;
    cell.greenRange = 1.0;
    cell.alphaRange = 0.8;
    cell.blueSpeed = 1.0f;
    cell.alphaSpeed = -0.1f;
    
    layer.emitterCells = @[cell];
}

- (CGPoint)locationFromTouchEvent:(UIEvent *)event{
    UITouch * touch = [[event allTouches] anyObject];
    return [touch locationInView:self.view];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point = [self locationFromTouchEvent:event];
    [self setBallInPsition:point];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point = [self locationFromTouchEvent:event];
    [self setBallInPsition:point];
}

- (void)setBallInPsition:(CGPoint)position{
    //创建基础动画
    CABasicAnimation * anim = [CABasicAnimation animationWithKeyPath:@"emitterCells.colorBallCell.scale"];
    
    anim.fromValue = @0.2f;
    anim.toValue = @0.5f;
    anim.duration = 1.0f;
    
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.colorBallLayer addAnimation:anim forKey:nil];
    self.colorBallLayer.emitterPosition = position;
    
    [CATransaction commit];
}


@end
