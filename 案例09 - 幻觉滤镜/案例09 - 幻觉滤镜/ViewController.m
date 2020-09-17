//
//  ViewController.m
//  案例09 - 幻觉滤镜
//
//  Created by macbook pro on 2020/9/17.
//  Copyright © 2020 hq. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import "FilterBar.h"

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface ViewController ()<FilterBarDelegate>
@property (nonatomic, assign) SenceVertex *vertices;
@property (nonatomic, strong) EAGLContext *context;
// 用于刷新屏幕
@property (nonatomic, strong) CADisplayLink *displayLink;
// 开始的时间戳
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
// 着色器程序
@property (nonatomic, assign) GLuint program;
// 顶点缓存
@property (nonatomic, assign) GLuint vertexBuffer;
// 纹理 ID
@property (nonatomic, assign) GLuint textureID;
@end

@implementation ViewController
- (void)dealloc {
    //1.上下文释放
    if(self.context == [EAGLContext currentContext]){
        [EAGLContext setCurrentContext:nil];
    }
    //顶点缓存区释放
    if(self.vertexBuffer){
        glDeleteBuffers(1, &_vertexBuffer);
        self.vertexBuffer = 0;
    }
    //顶点数组释放
    if(self.vertices){
        free(self.vertices);
        self.vertices = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if(self.displayLink){
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    //创建滤镜工具栏
    [self setupFilterBar];
    
    //滤镜处理初始化
    [self filterInit];
    
    //开始一个滤镜动画
    [self startFilerAnimation];
}

- (void)filterInit {
    //1. set context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    //2. set layer
    CAEAGLLayer* layer = [[CAEAGLLayer alloc] init];
    layer.contentsScale = [UIScreen mainScreen].scale;
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    [self.view.layer addSublayer:layer];
    
    //3. bind buffer
    [self bindRenderLayer:layer];
    
    //4. create texture
    self.textureID = [self createTexture];
    
    //5. create program
    [self setupNormalShaderProgram];
    
    //6. set vertext data
    [self setVertext];
    
    //7.设置视口
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    //8. start draw
    [self startFilerAnimation];
    
}

// 默认着色器程序
- (void)setupNormalShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"Normal"];
}

// 缩放滤镜着色器程序
- (void)setupScaleShaderProgram {
    [self setupShaderProgramWithName:@"Scale"];
}

// 灵魂出窍滤镜着色器程序
- (void)setupSoulOutShaderProgram {
    [self setupShaderProgramWithName:@"SoulOut"];
    
}

// 抖动滤镜着色器程序
-(void)setupShakeShaderProgram {
    [self setupShaderProgramWithName:@"Shake"];

}

// 闪白滤镜着色器程序
- (void)setupShineWhiteShaderProgram {
    [self setupShaderProgramWithName:@"ShineWhite"];
}

// 毛刺滤镜着色器程序
- (void)setupGitchShaderProgram {
    [self setupShaderProgramWithName:@"Glitch"];
}

// 幻影滤镜着色器程序
- (void)setupVertigoShaderProgram {
    [self setupShaderProgramWithName:@"Vertigo"];
}

- (void)setupShaderProgramWithName:(NSString *)name {
    GLuint vShader, fShader;
    vShader = [self compileShaderWithName:name type:GL_VERTEX_SHADER];
    fShader = [self compileShaderWithName:name type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vShader);
    glAttachShader(program, fShader);
    
    glDeleteShader(vShader);
    glDeleteShader(fShader);
    
    glLinkProgram(program);
    glUseProgram(program);
    self.program = program;
    
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:(shaderType == GL_VERTEX_SHADER)?@"vsh":@"fsh"];
    NSString* source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    GLuint shader = glCreateShader(shaderType);
    
    const GLchar* conten = source.UTF8String;
    GLint length = (int)source.length;
    glShaderSource(shader, 1, &conten, &length);
    glCompileShader(shader);
    return shader;
}

- (void)setVertext{
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SenceVertex)*4, self.vertices, GL_DYNAMIC_DRAW);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    GLuint positionSlot = glGetAttribLocation(self.program, "Position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, 0, sizeof(SenceVertex), NULL+offsetof(SenceVertex, positionCoord));
    
    GLuint TextureCoordsSlot = glGetAttribLocation(self.program, "TextureCoords");
    glEnableVertexAttribArray(TextureCoordsSlot);
    glVertexAttribPointer(TextureCoordsSlot, 2, GL_FLOAT, 0, sizeof(SenceVertex), NULL+offsetof(SenceVertex, textureCoord));
    
    GLuint TextureSlot = glGetUniformLocation(self.program, "Texture");
    glUniform1i(TextureSlot, 0);
}

- (GLuint)createTexture{
    CGImageRef image = [UIImage imageNamed:@"nn.jpg"].CGImage;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    CGRect rect = CGRectMake(0, 0, width, height);
    GLubyte* imageData = malloc(width*height*4);
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef contex = CGBitmapContextCreate(imageData, width, height, 8, width*4, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextTranslateCTM(contex, 0, height);
    CGContextScaleCTM(contex, 1, -1);
    CGColorSpaceRelease(space);
    CGContextClearRect(contex, rect);
    
    CGContextDrawImage(contex, rect, image);
    CGContextRelease(contex);
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (float)width, (float)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    free(imageData);
    
    return textureID;
}

//绑定渲染缓存区和帧缓存区
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer {
    GLuint renderBuffer;
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}

// 创建滤镜栏
- (void)setupFilterBar {
    CGFloat filterBarWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat filterBarHeight = 100;
    CGFloat filterBarY = [UIScreen mainScreen].bounds.size.height - filterBarHeight;
    FilterBar *filerBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, filterBarY, filterBarWidth, filterBarHeight)];
    filerBar.delegate = self;
    [self.view addSubview:filerBar];
    
    NSArray *dataSource = @[@"无",@"缩放",@"灵魂出窍",@"抖动",@"闪白",@"毛刺",@"幻觉"];
    filerBar.itemList = dataSource;
}

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index{
    if (index == 0) {
        [self setupNormalShaderProgram];
    }else if(index == 1)
    {
        [self setupScaleShaderProgram];
    }else if(index == 2)
    {
        [self setupSoulOutShaderProgram];
    }else if(index == 3)
    {
        [self setupShakeShaderProgram];
    }else if(index == 4)
    {
        [self setupShineWhiteShaderProgram];
    }else if(index == 5)
    {
        [self setupGitchShaderProgram];
    }else
    {
        [self setupVertigoShaderProgram];
    }
    // 重新开始滤镜动画
    [self startFilerAnimation];
}

// 开始一个滤镜动画
- (void)startFilerAnimation {
    if(self.displayLink){
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
- (void)timeAction {
    if(self.startTimeInterval == 0){
        self.startTimeInterval = self.displayLink.timestamp;
    }
    
    glUseProgram(self.program);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
//    NSLog(@"currentTime = %f", currentTime);
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

//获取渲染缓存区的宽
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}
//获取渲染缓存区的高
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}

@end
