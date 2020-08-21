//
//  ViewController.m
//  案例01-使用OpenGL ES完成纹理加载
//
//  Created by macbook pro on 2020/8/21.
//  Copyright © 2020 hq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    EAGLContext *context;
    GLKBaseEffect *cEffect;
}
@end

@implementation ViewController
-(void)setUpConfig{
    //1.初始化上下文&设置当前上下文
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if(!context){
        NSLog(@"Create ES context Failed");
        return;
    }
    [EAGLContext setCurrentContext:context];
    
    //2.获取GLKView & 设置context
    GLKView* view = (GLKView*)self.view;
    view.context = context;
    
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    //3.设置背景颜色
    glClearColor(1, 0, 0, 1.0);
}

-(void)setUpVertexData{
    //1.设置顶点数组(顶点坐标,纹理坐标)
    /*
     纹理坐标系取值范围[0,1];原点是左下角(0,0);
     故而(0,0)是纹理图像的左下角, 点(1,1)是右上角.
     */
    GLfloat vertexData[] = {
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5,  0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    //2.开辟顶点缓存区
    //(1).创建顶点缓存区标识符ID
    GLuint bufferID;
    glGenBuffers(1, &bufferID);
    
    //(2).绑定顶点缓存区.(明确作用)
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    
    //(3).将顶点数组的数据copy到顶点缓存区中(GPU显存中)
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    
    //3.打开读取通道.
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

-(void)setUpTexture{
    //1.获取纹理图片路径
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"nn" ofType:@"jpg"];
    
    //2.设置纹理参数
    //纹理坐标原点是左下角,但是图片显示原点应该是左上角.
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //3.使用苹果GLKit 提供GLKBaseEffect 完成着色器工作(顶点/片元)
    cEffect = [[GLKBaseEffect alloc] init];
    cEffect.label = @"test";
    cEffect.texture2d0.enabled = GL_TRUE;
    cEffect.texture2d0.name = textureInfo.name;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //1.OpenGL ES 相关初始化
    [self setUpConfig];
    
    //2.加载顶点/纹理坐标数据
    [self setUpVertexData];
    
    //3.加载纹理数据(使用GLBaseEffect)
    [self setUpTexture];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClear(GL_COLOR_BUFFER_BIT);
    
    //2.准备绘制
    [cEffect prepareToDraw];
    
    //3.开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
