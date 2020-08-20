//
//  main.m
//  案例02
//
//  Created by macbook pro on 2020/8/20.
//  Copyright © 2020 hq. All rights reserved.
//

#include "GLTools.h"
#include "GLShaderManager.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLFrame.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

GLShaderManager        shaderManager;
GLMatrixStack        modelViewMatrix;
GLMatrixStack        projectionMatrix;
GLFrame                cameraFrame;
GLFrame             objectFrame;
GLFrustum            viewFrustum;

GLBatch             pyramidBatch;

//纹理变量，一般使用无符号整型
GLuint              textureID;

GLGeometryTransform    transformPipeline;
M3DMatrix44f        shadowMatrix;

void RenderScene(){
    //1.清理缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    modelViewMatrix.PushMatrix();
    M3DMatrix44f mCamera;
    cameraFrame.GetCameraMatrix(mCamera);
    modelViewMatrix.MultMatrix(mCamera);
    
    M3DMatrix44f mObject;
    objectFrame.GetMatrix(mObject);
    modelViewMatrix.MultMatrix(mObject);
    
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_REPLACE, transformPipeline.GetModelViewProjectionMatrix(), 0);
    
    pyramidBatch.Draw();
    
    modelViewMatrix.PopMatrix();
    glutSwapBuffers();
}

// 将TGA文件加载为2D纹理。
bool LoadTGATexture(const char *szFileName, GLenum minFilter, GLenum magFilter, GLenum wrapMode){
    GLbyte* pBits;
    int nWidth, nHeight, nComponents;
    GLenum eFormat;
    
    //1、读纹理位，读取像素
    //参数1：纹理文件名称
    //参数2：返回纹理宽度
    //参数3：返回纹理高度
    //参数4：返回纹理组件
    //参数5：返回纹理格式
    //返回值：pBits,指向图像数据的指针
    pBits = gltReadTGABits(szFileName, &nWidth, &nHeight, &nComponents, &eFormat);
    if(pBits == NULL){
        return false;
    }
    
    //2、设置纹理参数
    //参数1：纹理维度
    //参数2：为S/T坐标设置模式
    //参数3：wrapMode,环绕模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
    
    //参数1：纹理维度
    //参数2：线性过滤
    //参数3: 缩小/放大过滤方式.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
    
    //3.载入纹理
    //参数1：纹理维度
    //参数2：mip贴图层次
    //参数3：纹理单元存储的颜色成分（从读取像素图是获得）
    //参数4：加载纹理宽
    //参数5：加载纹理高
    //参数6：加载纹理的深度
    //参数7：加载纹理的格式
    //参数8：像素数据的数据类型（GL_UNSIGNED_BYTE，每个颜色分量都是一个8位无符号整数）
    //参数9：指向纹理图像数据的指针
    glTexImage2D(GL_TEXTURE_2D, 0, nComponents, nWidth, nHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBits);
    
    //使用完毕释放pBits
    free(pBits);
    
    //只有minFilter 等于以下四种模式，才可以生成Mip贴图
    //GL_NEAREST_MIPMAP_NEAREST具有非常好的性能，并且闪烁现象非常弱
    //GL_LINEAR_MIPMAP_NEAREST常常用于对游戏进行加速，它使用了高质量的线性过滤器
    //GL_LINEAR_MIPMAP_LINEAR 和GL_NEAREST_MIPMAP_LINEAR 过滤器在Mip层之间执行了一些额外的插值，以消除他们之间的过滤痕迹。
    //GL_LINEAR_MIPMAP_LINEAR 三线性Mip贴图。纹理过滤的黄金准则，具有最高的精度。
    if(minFilter == GL_LINEAR_MIPMAP_LINEAR ||
       minFilter == GL_LINEAR_MIPMAP_NEAREST ||
       minFilter == GL_NEAREST_MIPMAP_LINEAR ||
       minFilter == GL_NEAREST_MIPMAP_NEAREST){
        //4.纹理生成所有的Mip层
        //参数：GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    
    return true;
}

//绘制金字塔
void MakePyramid(GLBatch& pyramidBatch){
    /*1、通过pyramidBatch组建三角形批次
      参数1：类型
      参数2：顶点数
      参数3：这个批次中将会应用1个纹理
      注意：如果不写这个参数，默认为0。
     */
    pyramidBatch.Begin(GL_TRIANGLES, 18, 1);
    
    //塔顶
    M3DVector3f vApex = { 0.0f, 1.0f, 0.0f };
    M3DVector3f vFrontLeft = { -1.0f, -1.0f, 1.0f };
    M3DVector3f vFrontRight = { 1.0f, -1.0f, 1.0f };
    M3DVector3f vBackLeft = { -1.0f,  -1.0f, -1.0f };
    M3DVector3f vBackRight = { 1.0f,  -1.0f, -1.0f };
    
    //金字塔底部
    //MultiTexCoord2f：指定纹理坐标，参数1：图层，即纹理的level,一般情况下为0，参数2、3：纹理坐标s，t
    //底部的四边形 = 三角形X + 三角形Y
    //三角形X = (vBackLeft,vBackRight,vFrontRight)
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    
    //三角形Y =(vFrontLeft,vBackLeft,vFrontRight)
    //vFrontLeft
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);

    
    // 金字塔前面
    //三角形：（Apex，vFrontLeft，vFrontRight）
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);

    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);

    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //金字塔左边
    //三角形：（vApex, vBackLeft, vFrontLeft）
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    
    //金字塔右边
    //三角形：（vApex, vFrontRight, vBackRight）
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);

    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    //金字塔后边
    //三角形：（vApex, vBackRight, vBackLeft）
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    //结束批次设置
    pyramidBatch.End();
}

void SetupRC(){
    glClearColor(0.7f, 0.7f, 0.7f, 1.0f);
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);
    
    //分配纹理对象 参数1:纹理对象个数，参数2:纹理对象指针
    glGenTextures(1, &textureID);
    
    //绑定纹理状态 参数1：纹理状态2D 参数2：纹理对象
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //将TGA文件加载为2D纹理。
    //参数1：纹理文件名称
    //参数2&参数3：需要缩小&放大的过滤器
    //参数4：纹理坐标环绕模式
    LoadTGATexture("stone.tga", GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    //4.创造金字塔pyramidBatch
    MakePyramid(pyramidBatch);
    
}

//清除纹理、删除纹理对象
void ShutdownRC(){
    glDeleteTextures(1, &textureID);
}

void SpecialKeys(int key, int x, int y){
    switch (key) {
        case GLUT_KEY_UP:
            objectFrame.RotateWorld(m3dDegToRad(-5.0f), 1, 0, 0);
            break;
        case GLUT_KEY_DOWN:
            objectFrame.RotateWorld(m3dDegToRad(5.0f), 1, 0, 0);
            break;
        case GLUT_KEY_LEFT:
            objectFrame.RotateWorld(m3dDegToRad(-5.0f), 0, 1, 0);
            break;
        case GLUT_KEY_RIGHT:
            objectFrame.RotateWorld(m3dDegToRad(5.0f), 0, 1, 0);
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
    
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
    cameraFrame.MoveForward(-10.0f);
}

int main(int argc, char * argv[]) {
    gltSetWorkingDirectory(argv[0]);
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DEPTH | GLUT_RGBA | GLUT_DOUBLE | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("test");
    
    glutDisplayFunc(RenderScene);
    glutReshapeFunc(ChangeSize);
    glutSpecialFunc(SpecialKeys);
    
    GLenum err = glewInit();
    if(GLEW_OK != err){
        return 1;
    }
    
    SetupRC();
    glutMainLoop();
    ShutdownRC();
    return 0;
}

