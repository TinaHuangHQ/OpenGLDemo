//
//  HView.m
//  案例03 - 使用GLSL完成纹理图片加载
//
//  Created by macbook pro on 2020/8/25.
//  Copyright © 2020 hq. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import "HView.h"

/*
不采样GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
思路：
  1.创建图层
  2.创建上下文
  3.清空缓存区
  4.设置RenderBuffer
  5.设置FrameBuffer
  6.开始绘制

*/

@interface HView ()

//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property(nonatomic,strong)CAEAGLLayer *myEagLayer;

@property(nonatomic,strong)EAGLContext *myContext;

@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

@property(nonatomic,assign)GLuint myPrograme;

@end

@implementation HView

- (void)layoutSubviews{
    //1.设置图层
    [self setupLayer];
    
    //2.设置图形上下文
    [self setupContext];
    
    //3.清空缓存区
    [self deleteRenderAndFrameBuffer];
    
    //4.设置RenderBuffer
    [self setupRenderBuffer];
    
    //5.设置FrameBuffer
    [self setupFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
}

//1.设置图层
-(void)setupLayer{
    //1.创建特殊图层
    /*
    重写layerClass，将HView返回的图层从CALayer替换成CAEAGLLayer
    */
    self. myEagLayer = (CAEAGLLayer*)self.layer;
    
    //2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
    kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
    kEAGLDrawablePropertyColorFormat
        可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
    
        kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
        kEAGLColorFormatRGB565：16位RGB的颜色，
        kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。


    */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatSRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

//2.设置上下文
-(void)setupContext{
    self.myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.myContext];
}

//3.清空缓存区
-(void)deleteRenderAndFrameBuffer{
    /*
    buffer分为frame buffer 和 render buffer2个大类。
    其中frame buffer 相当于render buffer的管理者。
    frame buffer object即称FBO。
    render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
    */
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

//4.设置RenderBuffer
-(void)setupRenderBuffer{
    //1.定义一个缓存区ID
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    
    self.myColorRenderBuffer = buffer;
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

//5.设置FrameBuffer
-(void)setupFrameBuffer{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
//    glGenBuffers(1, &buffer);
    
    self.myColorFrameBuffer = buffer;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//从图片中加载纹理
- (void)setupTexture:(NSString *)fileName {
    //1、将 UIImage 转换为 CGImageRef
    CGImageRef spriteImage = [[UIImage imageNamed:fileName] CGImage];
    
    //2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //3.获取图片字节数 宽*高*4（RGBA）
    GLubyte* spriteData = (GLubyte*)calloc(width*height*4, sizeof(GLubyte));
    
    //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //5、在CGContextRef上--> 将图片绘制出来
    CGRect rect = CGRectMake(0, 0, width, height);
    
    //6.使用默认方式绘制
    /*
    CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
    CGContextDrawImage
    参数1：绘图上下文
    参数2：rect坐标
    参数3：绘制的图片
    */
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
    //8、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //9.设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //10.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (float)width, (float)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
}

//6.开始绘制
-(void)renderLayer{
    //设置清屏颜色
    glClearColor(0.3, 0.45, 0.5, 1.0);
    
    //清除屏幕
    glClear(GL_COLOR_BUFFER_BIT);
    
    //1.设置视口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    
    //2.读取顶点着色程序、片元着色程序
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    //3.加载shader
    self.myPrograme = [self loadShaders:vertFile Withfrag:fragFile];
    
    //4.链接
    glLinkProgram(self.myPrograme);
    
    //获取链接状态
    GLint linkStatus;
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    if(linkStatus == GL_FALSE){
        GLchar message[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return ;
    }
    
    //5.使用program
    glUseProgram(self.myPrograme);
    
    //6.设置顶点、纹理坐标
    //前3个是顶点坐标，后2个是纹理坐标
    GLfloat attrArr[] ={
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    //7.-----处理顶点数据--------
    //(1)顶点缓存区
    GLuint attrBuffer;
    //(2)申请一个缓存区标识符
    glGenBuffers(1, &attrBuffer);
    //(3)将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    //(4)把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), NULL);
    
    GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), (float *)NULL + 3);
    
    [self setupTexture:@"nn.jpg"];
    
    //11. 设置纹理采样器 sampler2D
    glUniform1f(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
    //12.绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    //13.从渲染缓存区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

//加载shader
-(GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag{
    //1.定义2个零时着色器对象
    GLuint verShader, fragShader;
    
    //创建program
    GLint program = glCreateProgram();
    
    //2.编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //3.创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //4.释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //1.读取文件路径字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    const GLchar* source = (GLchar*)content.UTF8String;
    
    //2.创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //3.将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

@end
