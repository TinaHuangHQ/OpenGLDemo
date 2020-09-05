//
//  HButton.m
//  04_CAEmitterLayer_点赞
//
//  Created by Qiong Huang on 2020/9/5.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "HButton.h"

@interface HButton ()

@property(nonatomic,strong)CAEmitterLayer *explosionLayer;

@end

@implementation HButton

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setupExplosion];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupExplosion];
    }
    return self;
}

- (void)setupExplosion{
    CAEmitterLayer* layer = [[CAEmitterLayer alloc] init];
    [self.layer addSublayer:layer];
    self.explosionLayer = layer;
    layer.emitterSize = CGSizeMake(self.bounds.size.width + 40, self.bounds.size.height + 40);
    layer.emitterShape = kCAEmitterLayerCircle;
    layer.emitterMode = kCAEmitterLayerOutline;
    layer.renderMode = kCAEmitterLayerOldestFirst;
    
    CAEmitterCell* cell = [[CAEmitterCell alloc] init];
    cell.name = @"cell";
    cell.alphaSpeed = -1;
    cell.alphaRange = 0.1;
    cell.lifetime = 1;
    cell.lifetimeRange = 0.1;
    cell.velocity = 40;
    cell.velocityRange = 10;
    cell.scale = 0.08;
    cell.scaleRange = 0.02;
    cell.contents = (id)[[UIImage imageNamed:@"spark_red"] CGImage];
    
    layer.emitterCells = @[cell];
}

- (void)layoutSubviews{
    self.explosionLayer.position = CGPointMake(self.bounds.size.width*0.5, self.bounds.size.height*0.5);
    [super layoutSubviews];
}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    if(selected){
        animation.values = @[@1.5,@2.0, @0.8, @1.0];
        animation.duration = 0.5;
        animation.calculationMode = kCAAnimationCubic;
        [self.layer addAnimation:animation forKey:nil];
        [self performSelector:@selector(startAnimation) withObject:nil afterDelay:0.25];
    }
    else{
        [self stopAnimation];
    }
}

- (void)setHighlighted:(BOOL)highlighted{
    
    [super setHighlighted:highlighted];
    
}

- (void)startAnimation{
    [self.explosionLayer setValue:@1000 forKeyPath:@"emitterCells.cell.birthRate"];
    self.explosionLayer.beginTime = CACurrentMediaTime();
    [self performSelector:@selector(stopAnimation) withObject:nil afterDelay:0.15];
}

- (void)stopAnimation{
    [self.explosionLayer setValue:@0 forKeyPath:@"emitterCells.cell.birthRate"];
    [self.explosionLayer removeAllAnimations];
}

- (void)drawRect:(CGRect)rect{
    
}

@end
