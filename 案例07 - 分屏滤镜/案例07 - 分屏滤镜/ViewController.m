//
//  ViewController.m
//  案例07 - 分屏滤镜
//
//  Created by macbook pro on 2020/9/9.
//  Copyright © 2020 hq. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import "Tool/FilterBar.h"

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
- (void)dealloc{
    //1.上下文释放
    if([EAGLContext currentContext] == self.context){
        [EAGLContext setCurrentContext:nil];
    }
    
    //顶点缓存区释放
    if(self.vertexBuffer){
        glDeleteBuffers(1, &_vertexBuffer);
    }
    
    //顶点数组释放
    if(self.vertices){
        free(_vertices);
        _vertices = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self setupFilterBar];
    
    [self filterInit];
    
    [self render];
}

- (void)filterInit{
    //1. set context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    //2. set layer
    CAEAGLLayer* layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer addSublayer:layer];
    
    [self bindRenderLayer:layer];
    
    //3. set vertex data
    [self setupVertexData];
    
    //4. set texture
    self.textureID = [self createTextureWithImage];
    
    [self setupNormalShaderProgram];
}

- (void)setupVertexData{
    //2.开辟顶点数组内存空间
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    
    //3.初始化顶点(0,1,2,3)的顶点坐标以及纹理坐标
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SenceVertex)*4, self.vertices, GL_STATIC_DRAW);
    self.vertexBuffer = vertexBuffer;
}

//从图片中加载纹理
- (GLuint)createTextureWithImage{
    CGImageRef image = [[UIImage imageNamed:@"nn.jpg"] CGImage];
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    GLubyte* imageData = calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    
    CGContextDrawImage(context, rect, image);
    CGContextRelease(context);
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
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

-(void)render{
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    //使用program
    glUseProgram(self.program);
    //绑定buffer
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

// 创建滤镜栏
- (void)setupFilterBar {
    CGFloat filterBarWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat filterBarHeight = 100;
    CGFloat filterBarY = [UIScreen mainScreen].bounds.size.height - filterBarHeight;
    FilterBar *filerBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, filterBarY, filterBarWidth, filterBarHeight)];
    filerBar.delegate = self;
    [self.view addSubview:filerBar];
    
    NSArray *dataSource = @[@"无", @"2分屏", @"3分屏", @"4分屏", @"6分屏", @"9分屏"];
    filerBar.itemList = dataSource;
}

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index {
    //1. 选择默认shader
     if (index == 0) {
         [self setupNormalShaderProgram];
     }
     else if(index == 1){
         [self setupSplitScreen_2ShaderProgram];
     }
     else if(index == 2){
         [self setupSplitScreen_3ShaderProgram];
     }
     else if(index == 3){
         [self setupSplitScreen_4ShaderProgram];
     }
     else if(index == 4){
         [self setupSplitScreen_6ShaderProgram];
     }
     else if(index == 5){
         [self setupSplitScreen_9ShaderProgram];
     }
     
     //渲染
     [self render];
}

// 默认着色器程序
- (void)setupNormalShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"Normal"];
}

- (void)setupSplitScreen_2ShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"SplitScreen_2"];
}

- (void)setupSplitScreen_3ShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"SplitScreen_3"];
}

- (void)setupSplitScreen_4ShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"SplitScreen_4"];
}

- (void)setupSplitScreen_6ShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"SplitScreen_6"];
}

- (void)setupSplitScreen_9ShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"SplitScreen_9"];
}

// 初始化着色器程序
- (void)setupShaderProgramWithName:(NSString *)name {
    //1. 获取着色器program
    GLuint program = [self programWithShaderName:name];
    
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    
    glUniform1i(textureSlot, 0);
    
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    self.program = program;
}

- (GLuint)programWithShaderName:(NSString *)shaderName {
    GLuint vShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    
    glAttachShader(program, vShader);
    glAttachShader(program, fShader);
    
    glDeleteShader(vShader);
    glDeleteShader(fShader);
    
    glLinkProgram(program);
    glUseProgram(program);
    return program;
}

//编译shader代码
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType{
    NSString* shaderFile = [[NSBundle mainBundle] pathForResource:name ofType:(shaderType == GL_VERTEX_SHADER)? @"vsh":@"fsh"];
    
    NSString* content = [NSString stringWithContentsOfFile:shaderFile encoding:NSUTF8StringEncoding error:nil];
    GLuint shader =  glCreateShader(shaderType);
    
    const char* contentSource = [content UTF8String];
    int length = (int)[content length];
    glShaderSource(shader, 1, &contentSource, &length);
    
    glCompileShader(shader);
    
    return shader;
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
