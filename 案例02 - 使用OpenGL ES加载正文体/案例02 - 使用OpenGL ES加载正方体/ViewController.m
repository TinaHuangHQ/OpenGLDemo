//
//  ViewController.m
//  案例02 - 使用OpenGL ES加载正文体
//
//  Created by Qiong Huang on 2020/8/23.
//  Copyright © 2020 Qiong Huang. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>

typedef struct {
    GLKVector3 positionCoord;   //顶点坐标
    GLKVector2 textureCoord;    //纹理坐标
    GLKVector3 normal;          //法线
} CCVertex;

// 顶点数
static NSInteger const kCoordCount = 36;

@interface ViewController ()<GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) CCVertex *vertices;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger angle;
@property (nonatomic, assign) GLuint vertexBuffer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self CommonInit];
    
    [self SetupVertex];
    
    [self addCADisplayLink];
}

- (void)CommonInit{
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:context];
    
    self.glkView = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) context:context];
    self.glkView.backgroundColor = [UIColor blackColor];
    self.glkView.delegate = self;
    
    [self.view addSubview:self.glkView];
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    glDepthRangef(1, 0);
    
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"nn" ofType:@"jpg"];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile:path];
    
    NSDictionary* options = @{GLKTextureLoaderOriginBottomLeft:@(YES)};
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage] options:options error:nil];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.enabled = YES;
    self.baseEffect.texture2d0.target = textureInfo.target;
    self.baseEffect.texture2d0.name = textureInfo.name;
    
    self.baseEffect.light0.enabled = YES;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);
}

- (void)SetupVertex{
    self.vertices = calloc(kCoordCount, sizeof(CCVertex));
    // 前面
    self.vertices[0] = (CCVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}};
    self.vertices[1] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertices[2] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertices[3] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
    self.vertices[4] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
    self.vertices[5] = (CCVertex){{0.5, -0.5, 0.5}, {1, 0}, {0, 0, 1}};
    
    // 上面
    self.vertices[6] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 1, 0}};
    self.vertices[7] = (CCVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertices[8] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertices[9] = (CCVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
    self.vertices[10] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
    self.vertices[11] = (CCVertex){{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}};
    
    // 下面
    self.vertices[12] = (CCVertex){{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}};
    self.vertices[13] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertices[14] = (CCVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertices[15] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
    self.vertices[16] = (CCVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
    self.vertices[17] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}};
    
    // 左面
    self.vertices[18] = (CCVertex){{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}};
    self.vertices[19] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertices[20] = (CCVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertices[21] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
    self.vertices[22] = (CCVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
    self.vertices[23] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}};
    
    // 右面
    self.vertices[24] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {1, 0, 0}};
    self.vertices[25] = (CCVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertices[26] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertices[27] = (CCVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
    self.vertices[28] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
    self.vertices[29] = (CCVertex){{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}};
    
    // 后面
    self.vertices[30] = (CCVertex){{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}};
    self.vertices[31] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertices[32] = (CCVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertices[33] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
    self.vertices[34] = (CCVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
    self.vertices[35] = (CCVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}};
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(CCVertex)*kCoordCount, self.vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL+offsetof(CCVertex, positionCoord));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL+offsetof(CCVertex, textureCoord));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL+offsetof(CCVertex, normal));
}

- (void)addCADisplayLink{
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    [self.baseEffect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);
}

-(void)update{
    self.angle = (self.angle + 5) % 360;
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1, 0.7);
    [self.glkView display];
}
@end
