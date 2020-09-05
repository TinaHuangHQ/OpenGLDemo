//
//  ViewController.m
//  04_CAEmitterLayer_点赞
//
//  Created by Qiong Huang on 2020/9/5.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController.h"
#import "HButton.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    //添加点赞按钮
    HButton * btn = [HButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(200, 150, 30, 130);
    [self.view addSubview:btn];
    [btn setImage:[UIImage imageNamed:@"dislike"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"like_orange"] forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)btnClick:(UIButton *)button{
    
    if (!button.selected) { // 点赞
        button.selected = !button.selected;
    }else{ // 取消点赞
        button.selected = !button.selected;
    }
}



@end
