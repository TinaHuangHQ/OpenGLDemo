//
//  ViewController.m
//  GLKit三角形变换
//
//  Created by macbook pro on 2020/8/31.
//  Copyright © 2020 hq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property(nonatomic,strong)EAGLContext *mContext;
@property(nonatomic,strong)GLKBaseEffect *mEffect;

@property(nonatomic,assign)int count;

//旋转的度数
@property(nonatomic,assign)float XDegree;
@property(nonatomic,assign)float YDegree;
@property(nonatomic,assign)float ZDegree;

//是否旋转X,Y,Z
@property(nonatomic,assign) BOOL XB;
@property(nonatomic,assign) BOOL YB;
@property(nonatomic,assign) BOOL ZB;

@property(nonatomic,strong) dispatch_source_t timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //1.新建图层
    [self setupContext];
    
    //2.设置顶点数据
    [self setupVertexData];
    
    //3.设置顶点索引数据
    [self setupIndicesData];
    
    //4.渲染图形
    [self render];
    
    //5. 启动定时器
    [self startTimer];
}

//1.新建图层
-(void)setupContext{
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    
    [EAGLContext setCurrentContext:self.mContext];
    glEnable(GL_DEPTH_TEST);
}

//2.设置顶点数据
-(void)setupVertexData{
    //1.顶点数据
    GLfloat attrArr[] = {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
    };
    //将顶点数组放入数组缓冲区中 GL_ARRAY_BUFFER
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), NULL);
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (GLfloat *)NULL + 3);
}

//3.设置顶点索引数据
-(void)setupIndicesData{
    //1.绘图索引
    GLuint indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    //顶点个数
    self.count = sizeof(indices) /sizeof(GLuint);
    //将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

//4.渲染图形
-(void)render{
    self.mEffect = [[GLKBaseEffect alloc] init];
    //投影视图
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 100.0f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

-(void)startTimer{
    double second = 0.1;
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, second * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(self.timer, ^{
        self.XDegree += 0.1f * self.XB;
        self.YDegree += 0.1f * self.YB;
        self.ZDegree += 0.1f * self.ZB ;
        
    });
    dispatch_resume(self.timer);
}

//场景数据变化
-(void)update{
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.5);

    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.XDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.YDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.ZDegree);

    self.mEffect.transform.modelviewMatrix = modelViewMatrix;

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

- (IBAction)XClick:(id)sender {
    _XB = !_XB;
}
- (IBAction)YClick:(id)sender {
    _YB = !_YB;
}
- (IBAction)ZClick:(id)sender {
    _ZB = !_ZB;
}

@end
