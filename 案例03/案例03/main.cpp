//
//  main.cpp
//  案例03
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

GLShaderManager        shaderManager;            //着色器管理器
GLMatrixStack        modelViewMatrix;        //模型视图矩阵
GLMatrixStack        projectionMatrix;        //投影矩阵
GLFrustum            viewFrustum;            //视景体
GLGeometryTransform    transformPipeline;        //几何变换管线

//4个批次容器类
GLBatch             floorBatch;//地面
GLBatch             ceilingBatch;//天花板
GLBatch             leftWallBatch;//左墙面
GLBatch             rightWallBatch;//右墙面

//深度初始值，-65。
GLfloat             viewZ = -65.0f;

// 纹理标识符号
#define TEXTURE_BRICK   0 //墙面
#define TEXTURE_FLOOR   1 //地板
#define TEXTURE_CEILING 2 //纹理天花板
#define TEXTURE_COUNT   3 //纹理个数

GLuint  textures[TEXTURE_COUNT];//纹理标记数组
//文件tag名字数组
const char *szTextureFiles[TEXTURE_COUNT] = { "brick.tga", "floor.tga", "ceiling.tga" };

void RenderScene(){
    glClear(GL_COLOR_BUFFER_BIT);
    
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Translate(0.0f, 0.0f, viewZ);
    
    shaderManager.UseStockShader(GLT_SHADER_TEXTURE_REPLACE, transformPipeline.GetModelViewProjectionMatrix(), 0);
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_FLOOR]);
    floorBatch.Draw();
    
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_CEILING]);
    ceilingBatch.Draw();
    
    glBindTexture(GL_TEXTURE_2D, textures[TEXTURE_BRICK]);
    leftWallBatch.Draw();
    rightWallBatch.Draw();
    
    modelViewMatrix.PopMatrix();
    glutSwapBuffers();
}

void SetupRC(){
    //基本操作：清除背景色、初始化着色器、打开深度测试
    glClearColor(0.0f, 0.0f, 0.0f, 1.0);
    shaderManager.InitializeStockShaders();
//    glEnable(GL_DEPTH);
    
    //加载纹理
    GLbyte *pBytes;
    GLint iWidth, iHeight, iComponents;
    GLenum eFormat;
    //1. 生成纹理对象
    glGenTextures(TEXTURE_COUNT, textures);
    for(int i = 0; i<TEXTURE_COUNT; i++){
        //2. 绑定纹理对象
        glBindTexture(GL_TEXTURE_2D, textures[i]);
        
        //3. 读取TGA文件
        pBytes = gltReadTGABits(szTextureFiles[i], &iWidth, &iHeight, &iComponents, &eFormat);
        
        //4. 设置过滤方式
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        
        //5. 设置环绕模式
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        //6.加载纹理
        glTexImage2D(GL_TEXTURE_2D, 0, iComponents, iWidth, iHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBytes);
        
        //7. 生成mip贴图
        glGenerateMipmap(GL_TEXTURE_2D);
        
        //8. 释放原始纹理数据，不在需要纹理原始数据了
        free(pBytes);
    }
    
    GLfloat z;
    /*
    GLTools库中的容器类，GBatch，
    void GLBatch::Begin(GLenum primitive,GLuint nVerts,GLuint nTextureUnits = 0);
    参数1：图元枚举值
    参数2：顶点数
    参数3：1组或者2组纹理坐标
    */
    floorBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
    for(z = 60.0f; z >= 0.0f; z -= 10.0f){
        //左下角顶点对应用纹理的左下角
        floorBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        floorBatch.Vertex3f(-10.0f, -10.0f, z);
        
        //右下角顶点对应于纹理的右下角
        floorBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        floorBatch.Vertex3f(10.0f, -10.0f, z);
        
        //左上角顶点对应于纹理的左上角
        floorBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        floorBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
        
        //右上角顶点对应于纹理的右上角
        floorBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        floorBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);
    }
    floorBatch.End();
    //参考PPT图6-11
    ceilingBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
    for(z = 60.0f; z >= 0.0f; z -=10.0f)
    {
        ceilingBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
        ceilingBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);

        ceilingBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
        ceilingBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);

        ceilingBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
        ceilingBatch.Vertex3f(-10.0f, 10.0f, z);

        ceilingBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
        ceilingBatch.Vertex3f(10.0f, 10.0f, z);
    }
    ceilingBatch.End();
     
     //参考PPT图6-12
     leftWallBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
     for(z = 60.0f; z >= 0.0f; z -=10.0f)
     {
         leftWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
         leftWallBatch.Vertex3f(-10.0f, -10.0f, z);
         
         leftWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
         leftWallBatch.Vertex3f(-10.0f, 10.0f, z);
         
         leftWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
         leftWallBatch.Vertex3f(-10.0f, -10.0f, z - 10.0f);
         
         leftWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
         leftWallBatch.Vertex3f(-10.0f, 10.0f, z - 10.0f);
     }
     leftWallBatch.End();
    
    //参考PPT图6-13
     rightWallBatch.Begin(GL_TRIANGLE_STRIP, 28, 1);
     for(z = 60.0f; z >= 0.0f; z -=10.0f)
     {
         rightWallBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
         rightWallBatch.Vertex3f(10.0f, -10.0f, z);

         rightWallBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
         rightWallBatch.Vertex3f(10.0f, 10.0f, z);

         rightWallBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
         rightWallBatch.Vertex3f(10.0f, -10.0f, z - 10.0f);

         rightWallBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
         rightWallBatch.Vertex3f(10.0f, 10.0f, z - 10.0f);
     }
     rightWallBatch.End();
}

void ChangeSize(int w, int h){
    glViewport(0, 0, w, h);
    viewFrustum.SetPerspective(80.0f, float(w)/float(h), 1.0f, 120.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void ShutdownRC(void){
    glDeleteTextures(TEXTURE_COUNT, textures);
}

void SpecialKeys(int key, int x, int y){
    if(key == GLUT_KEY_UP){
        viewZ += 0.5f;
    }
    else if(key == GLUT_KEY_DOWN){
        viewZ -= 0.5f;
    }
    else{
        return ;
    }
    glutPostRedisplay();
}

int main(int argc, char *argv[]){
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGBA | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("tunnel");
    
    glutDisplayFunc(RenderScene);
    glutReshapeFunc(ChangeSize);
    glutSpecialFunc(SpecialKeys);
    
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
