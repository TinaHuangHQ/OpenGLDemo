//
//  ViewController.m
//  案例08 - 马赛克滤镜
//
//  Created by macbook pro on 2020/9/10.
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
    if(self.context == [EAGLContext currentContext]){
        [EAGLContext setCurrentContext:nil];
    }
    if(_vertexBuffer){
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    if(_vertices){
        free(_vertices);
        _vertices = nil;
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
    
    [self render];
}

- (void)render{
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    glViewport(0, 0, [self drawableWidth], [self drawableHeight]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)filterInit {
    //1. set contenxt
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    //2. set layer
    CAEAGLLayer* layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer addSublayer:layer];
    
    //3. bind buffer
    [self bindRenderLayer:layer];
    
    //4. set vertex
    self.vertices = malloc(4*sizeof(SenceVertex));
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    GLuint vertexBuf;
    glGenBuffers(1, &vertexBuf);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuf);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SenceVertex)*4, self.vertices, GL_DYNAMIC_DRAW);
    self.vertexBuffer = vertexBuf;
    
    //5. set texture
    self.textureID = [self createTextureWithImage];
    
    //6. set shader
    [self setupNormalShaderProgram];
}

- (void)setupNormalShaderProgram {
    [self setupShaderProgramWithName:@"Normal"];
}

// 灰度滤镜着色器程序
- (void)setupGrayShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"Gray"];
}

// 颠倒滤镜着色器程序
- (void)setupReversalShaderProgram {
    //设置着色器程序
    [self setupShaderProgramWithName:@"Reversal"];
}

// 马赛克滤镜着色器程序
- (void)setupMosaicShaderProgram {
    [self setupShaderProgramWithName:@"Mosaic"];
    
}

// 六边形马赛克滤镜着色器程序
- (void)setupHexagonMosaicShaderProgram {
    [self setupShaderProgramWithName:@"HexagonMosaic"];
}

// 三角形马赛克滤镜着色器程序
- (void)setupTriangularMosaicShaderProgram {
    [self setupShaderProgramWithName:@"TriangularMosaic"];
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:(shaderType == GL_VERTEX_SHADER)?@"vsh":@"fsh"];
    NSString* source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"%@",source);
    const char *sourceContent = (GLchar*)[source UTF8String];
    GLuint shader =  glCreateShader(shaderType);
    int length = (int)source.length;
    glShaderSource(shader, 1, &sourceContent, &length);
    
    glCompileShader(shader);
    return shader;
}

- (GLuint)programWithShaderName:(NSString *)shaderName {
    GLuint vShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    GLuint program = glCreateProgram();
    glAttachShader(program, vShader);
    glAttachShader(program, fShader);
    
    glLinkProgram(program);
    glUseProgram(program);
    
    glDeleteShader(vShader);
    glDeleteShader(fShader);
    return program;
}

- (void)setupShaderProgramWithName:(NSString *)name {
    self.program = [self programWithShaderName:name];
    
    GLuint positionSlot = glGetAttribLocation(self.program, "Position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, 0, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    GLuint textureCoorSlot = glGetAttribLocation(self.program, "TextureCoords");
    glEnableVertexAttribArray(textureCoorSlot);
    glVertexAttribPointer(textureCoorSlot, 2, GL_FLOAT, 0, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    GLuint textureUniform = glGetUniformLocation(self.program, "Texture");
    glUniform1f(textureUniform, 0);
}

- (GLuint)createTextureWithImage{
    //得到纹理数据
    CGImageRef image = [[UIImage imageNamed:@"nn.jpg"] CGImage];
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    GLubyte* imageData = malloc(width*height*4);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);//CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    
    CGContextDrawImage(context, rect, image);
    CGContextRelease(context);
    
    //设置纹理数据
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (float)width, (float)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    free(imageData);
    
    return textureID;
}

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
    
    NSArray *dataSource = @[@"无",@"灰度",@"颠倒",@"马赛克",@"马赛克2",@"马赛克3"];
    filerBar.itemList = dataSource;
}


- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index{
    if (index == 0) {
        [self setupNormalShaderProgram];
    }
    else if (index == 1) {
        [self setupGrayShaderProgram];
    }
    else if(index == 2) {
        [self setupReversalShaderProgram];
    }
    else if (index == 3) {
        [self setupMosaicShaderProgram];
    }
    else if (index == 4) {
        [self setupHexagonMosaicShaderProgram];
    }
    else if (index == 5) {
        [self setupTriangularMosaicShaderProgram];
    }
    
    [self render];
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
