//
//  main.m
//  案例04-球体世界
//
//  Created by macbook pro on 2020/8/20.
//  Copyright © 2020 hq. All rights reserved.
//

#include "GLTools.h"
#include "GLShaderManager.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"
#include "StopWatch.h"

#include <math.h>
#include <stdio.h>

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

#define NUM_SPHERES 50
GLFrame spheres[NUM_SPHERES];

GLShaderManager        shaderManager;            // 着色器管理器
GLMatrixStack        modelViewMatrix;        // 模型视图矩阵
GLMatrixStack        projectionMatrix;        // 投影矩阵
GLFrustum            viewFrustum;            // 视景体
GLGeometryTransform    transformPipeline;        // 几何图形变换管道

GLTriangleBatch        torusBatch;             // 花托批处理
GLBatch                floorBatch;             // 地板批处理

//**2、定义公转球的批处理（公转自转）**
GLTriangleBatch     sphereBatch;            //球批处理

//**3、角色帧 照相机角色帧（全局照相机实例）
GLFrame             cameraFrame;

//**5、添加纹理
//纹理标记数组
GLuint uiTextures[3];

void LoadTGATexture(const char *szFileName, GLenum minFilter, GLenum magFilter, GLenum wrapMode){
    GLbyte *pBits;
    int nWidth, nHeight, nComponents;
    GLenum eFormat;
    pBits = gltReadTGABits(szFileName, &nWidth, &nHeight, &nComponents, &eFormat);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
    
    glTexImage2D(GL_TEXTURE_2D, 0, nComponents, nWidth, nHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBits);
    
    if(minFilter == GL_LINEAR_MIPMAP_LINEAR ||
       minFilter == GL_LINEAR_MIPMAP_NEAREST ||
       minFilter == GL_NEAREST_MIPMAP_LINEAR ||
       minFilter == GL_NEAREST_MIPMAP_NEAREST){
        //4.加载Mip,纹理生成所有的Mip层
        //参数：GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    free(pBits);
}

void SetupRC(){
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    //4.设置大球
    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    
    //5.设置小球(公转自转)
    gltMakeSphere(sphereBatch, 0.1f, 26, 13);
    
    //6.设置地板顶点数据&地板纹理
    GLfloat texSize = 10.0f;
    floorBatch.Begin(GL_TRIANGLE_FAN, 4,1);
    floorBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    floorBatch.Vertex3f(-20.f, -0.41f, 20.0f);
    
    floorBatch.MultiTexCoord2f(0, texSize, 0.0f);
    floorBatch.Vertex3f(20.0f, -0.41f, 20.f);
    
    floorBatch.MultiTexCoord2f(0, texSize, texSize);
    floorBatch.Vertex3f(20.0f, -0.41f, -20.0f);
    
    floorBatch.MultiTexCoord2f(0, 0.0f, texSize);
    floorBatch.Vertex3f(-20.0f, -0.41f, -20.0f);
    floorBatch.End();

    //7.随机小球球顶点坐标数据
    for (int i = 0; i < NUM_SPHERES; i++) {
        
        //y轴不变，X,Z产生随机值
        GLfloat x = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        GLfloat z = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        
        //在y方向，将球体设置为0.0的位置，这使得它们看起来是飘浮在眼睛的高度
        //对spheres数组中的每一个顶点，设置顶点数据
        spheres[i].SetOrigin(x, 0.0f, z);
    }
    
    //生成纹理对象
    glGenTextures(3, uiTextures);
    
    //将TGA文件（地板）加载为2D纹理。
    //GL_LINEAR_MIPMAP_LINEAR：在Mip层之间执行线性插补，并执行线性过滤，又称三线性Mip贴图
    //GL_LINEAR：在Mip基层上执行线性过滤
    //GL_REPEAT:OpenGL在纹理坐标超过1.0的⽅向上对纹理进行重复
    glBindTexture(GL_TEXTURE_2D, uiTextures[0]);
    LoadTGATexture("marble.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_REPEAT);
    
    //将TGA文件（大球）加载为2D纹理。
    //GL_LINEAR_MIPMAP_LINEAR:在Mip层之间执行线性插补，并执行线性过滤，又称三线性Mip贴图
    //GL_LINEAR:在Mip基层上执行线性过滤
    //GL_CLAMP_TO_EDGE:纹理坐标会被约束到0和1之间，超出的部分会重复纹理坐标的边缘，产生一种边缘被拉伸的效果
    glBindTexture(GL_TEXTURE_2D, uiTextures[1]);
    LoadTGATexture("marslike.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    //将TGA文件（小球）加载为2D纹理。
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    LoadTGATexture("moonlike.tga", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_CLAMP_TO_EDGE);
}

void drawSomething(GLfloat yRot){
    //1.定义光源位置&漫反射颜色
    static GLfloat vWhite[] = { 1.0f, 1.0f, 1.0f, 1.0f };
    static GLfloat vLightPos[] = { 0.0f, 3.0f, 0.0f, 1.0f };
    
    //2.绘制大球球
    glBindTexture(GL_TEXTURE_2D, uiTextures[1]);
    modelViewMatrix.Translate(0.0f, 0.2f, 0.0f);
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot, 0, 1, 0);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vLightPos, vWhite, 0);
    torusBatch.Draw();
    modelViewMatrix.PopMatrix();
    
    //3.绘制悬浮小球
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    for(int i = 0; i<NUM_SPHERES; i++){
        modelViewMatrix.PushMatrix();
        modelViewMatrix.MultMatrix(spheres[i]);
        shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vLightPos, vWhite, 0);
        sphereBatch.Draw();
        modelViewMatrix.PopMatrix();
    }
    
    //4.绘制公转小球球（公转自转)
    glBindTexture(GL_TEXTURE_2D, uiTextures[2]);
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot*-2.0f, 0, 1, 0);
    modelViewMatrix.Translate(0.8f, 0.0f, 0.0f);
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vLightPos, vWhite, 0);
    sphereBatch.Draw();
    modelViewMatrix.PopMatrix();
}

void RenderScene(){
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //1.地板颜色值
    static GLfloat vFloorColor[] = { 1.0f, 1.0f, 0.0f, 0.75f};
    
    //2.基于时间动画
    static CStopWatch    rotTimer;
    float yRot = rotTimer.GetElapsedSeconds() * 60.0f;
    
    modelViewMatrix.PushMatrix();
    M3DMatrix44f mCamer;
    cameraFrame.GetCameraMatrix(mCamer);
    modelViewMatrix.MultMatrix(mCamer);
    
    //6.压栈(镜面)
    modelViewMatrix.PushMatrix();
    //7.---添加反光效果---
    //翻转Y轴
    modelViewMatrix.Scale(1.0f, -1.0f, 1.0f);
    modelViewMatrix.Translate(0, 0.8, 0);
    
    //8.指定顺时针为正面，默认逆时针（GL_CCW）是正面。
    glFrontFace(GL_CW);
    
    //9.绘制地面以外其他部分(镜面)
    drawSomething(yRot);
    
    //10.恢复为逆时针为正面
    glFrontFace(GL_CCW);
    
    //11.绘制镜面，恢复矩阵
    modelViewMatrix.PopMatrix();
    //---添加反光效果除地板以外的镜面效果绘制完成---
    
    //12.开启混合功能(绘制地板)
    glEnable(GL_BLEND);
    
    //13. 指定glBlendFunc 颜色混合方程式
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    //14.绑定地面纹理
    glBindTexture(GL_TEXTURE_2D, uiTextures[0]);
    
    /*15.
     纹理调整着色器(将一个基本色乘以一个取自纹理的单元nTextureUnit的纹理)
     参数1：GLT_SHADER_TEXTURE_MODULATE
     参数2：模型视图投影矩阵
     参数3：颜色
     参数4：纹理单元（第0层的纹理单元）
     */
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_MODULATE, transformPipeline.GetModelViewProjectionMatrix(), vFloorColor, 0);
    
    //开始绘制
    floorBatch.Draw();
    //取消混合
    glDisable(GL_BLEND);
    
    //16.绘制地面以外其他部分
    modelViewMatrix.PushMatrix();
    drawSomething(yRot);
    modelViewMatrix.PopMatrix();
    
    modelViewMatrix.PopMatrix();
    glutSwapBuffers();
    glutPostRedisplay();
}

void SpeacialKeys(int key,int x,int y){
    float linear = 0.1f;
    float angular = float(m3dDegToRad(5.0f));
    switch (key) {
        case GLUT_KEY_UP:
            cameraFrame.MoveForward(linear);
            break;
        case GLUT_KEY_DOWN:
            cameraFrame.MoveForward(-linear);
            break;
        case GLUT_KEY_LEFT:
            cameraFrame.RotateWorld(angular, 0, 1, 0);
        break;
        case GLUT_KEY_RIGHT:
            cameraFrame.RotateWorld(-angular, 0, 1, 0);
        break;
        default:
            break;
    }
    glutPostRedisplay();
}

void ChangeSize(int w, int h){
    glViewport(0, 0, w, h);
    viewFrustum.SetPerspective(35, float(w)/float(h), 1, 100);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    cameraFrame.MoveForward(-5.0f);
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void ShutdownRC(void){
    glDeleteTextures(3, uiTextures);
}

int main(int argc, char * argv[]) {
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
    glutInitWindowSize(800, 600);
    glutCreateWindow("OpenGL SphereWorld");
    
    glutReshapeFunc(ChangeSize);
    glutDisplayFunc(RenderScene);
    glutSpecialFunc(SpeacialKeys);
    
    GLenum err = glewInit();
    if(GLEW_OK != err){
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    SetupRC();
    glutMainLoop();
    ShutdownRC();
    
    return 0;
}
