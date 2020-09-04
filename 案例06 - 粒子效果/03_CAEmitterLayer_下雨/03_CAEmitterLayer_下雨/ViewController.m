//
//  ViewController.m
//  03_CAEmitterLayer_下雨
//
//  Created by Qiong Huang on 2020/9/5.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) CAEmitterLayer * rainLayer;
@property (nonatomic, weak) UIImageView * imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [self setupEmitter];
}

- (void)setupUI{
    // 背景图片
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    imageView.image = [UIImage imageNamed:@"rain"];
    
    // 下雨按钮
    UIButton * startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:startBtn];
    startBtn.frame = CGRectMake(20, self.view.bounds.size.height - 60, 80, 40);
    startBtn.backgroundColor = [UIColor whiteColor];
    [startBtn setTitle:@"雨停了" forState:UIControlStateNormal];
    [startBtn setTitle:@"下雨" forState:UIControlStateSelected];
    [startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [startBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // 雨量按钮
    UIButton * rainBIgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:rainBIgBtn];
    rainBIgBtn.tag = 100;
    rainBIgBtn.frame = CGRectMake(140, self.view.bounds.size.height - 60, 80, 40);
    rainBIgBtn.backgroundColor = [UIColor whiteColor];
    [rainBIgBtn setTitle:@"下大点" forState:UIControlStateNormal];
    [rainBIgBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rainBIgBtn addTarget:self action:@selector(rainButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * rainSmallBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:rainSmallBtn];
    rainSmallBtn.tag = 200;
    rainSmallBtn.frame = CGRectMake(240, self.view.bounds.size.height - 60, 80, 40);
    rainSmallBtn.backgroundColor = [UIColor whiteColor];
    [rainSmallBtn setTitle:@"太大了" forState:UIControlStateNormal];
    [rainSmallBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rainSmallBtn addTarget:self action:@selector(rainButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonClick:(UIButton *)sender{
    if(!sender.selected){
        sender.selected = !sender.selected;
        self.rainLayer.birthRate = 0;
    }
    else{
        sender.selected = !sender.selected;
        self.rainLayer.birthRate = 25;
    }
}

- (void)rainButtonClick:(UIButton *)sender{
    NSInteger rate = 1;
    CGFloat scale = 0.05;
    if(sender.tag == 100){
        if(self.rainLayer.birthRate < 30){
            self.rainLayer.birthRate = self.rainLayer.birthRate + rate;
            self.rainLayer.scale = self.rainLayer.scale + scale;
        }
    }
    else{
        if(self.rainLayer.birthRate > 1){
            self.rainLayer.birthRate = self.rainLayer.birthRate - rate;
            self.rainLayer.scale = self.rainLayer.scale - scale;
        }
    }
}

- (void)setupEmitter{
    CAEmitterLayer* rainLayer = [[CAEmitterLayer alloc] init];
    [self.view.layer addSublayer:rainLayer];
    self.rainLayer = rainLayer;
    
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*0.5, -10.0f);
    
    CAEmitterCell* cell = [[CAEmitterCell alloc] init];
    cell.contents = (id)[[UIImage imageNamed:@"rain_white"] CGImage];
    cell.birthRate = 25;
    cell.lifetime = 20;
    cell.speed = 10;
    cell.velocity = 10;
    cell.velocityRange = 10;
    cell.yAcceleration = 1000;
    cell.scale = 0.1;
    cell.scaleRange = 0;
    
    rainLayer.emitterCells = @[cell];
}

@end
