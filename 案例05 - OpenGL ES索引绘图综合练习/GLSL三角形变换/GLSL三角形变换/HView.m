//
//  HView.m
//  GLSL三角形变换
//
//  Created by Qiong Huang on 2020/8/27.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import "HView.h"
#import "Utils/GLESMath.h"
#import "Utils/GLESUtils.h"

@interface HView ()
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer* myTimer;
}

@property(nonatomic,strong)CAEAGLLayer *myEagLayer;
@property(nonatomic,strong)EAGLContext *myContext;

@property(nonatomic,assign)GLuint myColorRenderBuffer;
@property(nonatomic,assign)GLuint myColorFrameBuffer;

@property(nonatomic,assign)GLuint myProgram;
@property (nonatomic , assign) GLuint  myVertices;

@end

@implementation HView

- (void)layoutSubviews{
    [self setupLayer];
    [self setupContext];
    [self deletBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupProgram];
    [self setupVertexData];
    [self setupProjectionData];
    [self setupModelViewData];
    [self render];
}

-(void)setupLayer{
    self.myEagLayer = (CAEAGLLayer*)self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.opaque = YES;
    self.myEagLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking:@false,
        kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
    };
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

-(void)setupContext{
    self.myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.myContext];
}

-(void)deletBuffer{
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

-(void)setupRenderBuffer{
    glGenRenderbuffers(1, &_myColorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

-(void)setupFrameBuffer{
    glGenFramebuffers(1, &_myColorFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

-(void)setupProgram{
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    glLinkProgram(self.myProgram);
    glUseProgram(self.myProgram);
}

-(void)setupVertexData{
    //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)
    GLfloat attrArr[] = {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上0
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上1
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下2
        
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下3
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点4
    };
    
    GLuint bufferID;
    glGenBuffers(1, &bufferID);
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), NULL);
    
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), (GLfloat*)NULL+3);
}

-(void)setupProjectionData{
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = self.frame.size.width/self.frame.size.height;
    
    ksPerspective(&_projectionMatrix, 30, aspect, 5.0, 20.0);
    ksTranslate(&_projectionMatrix, 0, 0, -10.0);
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, &_projectionMatrix.m[0][0]);
}

- (void)setupModelViewData{
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
        
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, &_modelViewMatrix.m[0][0]);
}

-(void)render{
    glClearColor(0, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLfloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    glEnable(GL_CULL_FACE);
    
    //(2).索引数组
    GLuint indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

-(GLuint)loadShader:(NSString *)vert frag:(NSString *)frag{
    GLuint vertShader, fragShader;
    GLuint program = glCreateProgram();
    
    [self compileShader:&vertShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    
    return program;
}

-(void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    const GLchar* source = content.UTF8String;
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
}

- (IBAction)XClick:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bX = !bX;
}

- (IBAction)YClick:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bY = !bY;
}

- (IBAction)ZClick:(id)sender {
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bZ = !bZ;
}

-(void)reDegree{
    xDegree += bX*5;
    yDegree += bY*5;
    zDegree += bZ*5;
    
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    ksRotate(&_rotationMatrix, xDegree, 1, 0, 0);
    ksRotate(&_rotationMatrix, yDegree, 0, 1, 0);
    ksRotate(&_rotationMatrix, zDegree, 0, 0, 1);
    
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, &_modelViewMatrix.m[0][0]);
    
    [self render];
}

@end
