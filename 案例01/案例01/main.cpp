//
//  main.m
//  案例01
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

GLShaderManager        shaderManager;            // 着色器管理器
GLMatrixStack        modelViewMatrix;        // 模型视图矩阵堆栈
GLMatrixStack        projectionMatrix;        // 投影矩阵堆栈
GLFrustum            viewFrustum;            // 视景体
GLGeometryTransform    transformPipeline;        // 几何图形变换管道

GLTriangleBatch        torusBatch;             //甜甜圈
GLTriangleBatch     sphereBatch;            //小球
GLBatch             floorBatch;          //地板

//角色帧 照相机角色帧
GLFrame   cameraFrame;
GLFrame  objectFrame;

//**4、添加附加随机球
#define NUM_SPHERES 50
GLFrame spheres[NUM_SPHERES];

void RenderScene(void){
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    
    //1. 颜色(地板,甜甜圈颜色,小球颜色)
    static GLfloat vFloorColor[] = {0.0f,1.0f,0.0f,1.0f};
    static GLfloat vTorusColor[] = {1.0f,0.0f,0.0f,1.0f};
    static GLfloat vSpereColor[] = {0.0f,0.0f,1.0f,1.0f};
    
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vFloorColor);
    floorBatch.Draw();
    
    //2. 动画
    static CStopWatch rotTimer;
    float yRot = rotTimer.GetElapsedSeconds()*60.0f;
    
    modelViewMatrix.PushMatrix();
    M3DMatrix44f mCamer;
    cameraFrame.GetCameraMatrix(mCamer);
    modelViewMatrix.MultMatrix(mCamer);
    
    //5. 设置点光源位置
    M3DVector4f vLightPos = {0,10,5,1};
    modelViewMatrix.Translate(0.0f, 0.0f, -5.0f);
    //7. 甜甜圈
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot, 0, 1, 0);
    shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vLightPos, vTorusColor);
    torusBatch.Draw();
    modelViewMatrix.PopMatrix();

    //8. 小球
    for (int i = 0; i < NUM_SPHERES; i++) {
        modelViewMatrix.PushMatrix();
        modelViewMatrix.MultMatrix(spheres[i]);
        shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vLightPos, vSpereColor);
        sphereBatch.Draw();
        modelViewMatrix.PopMatrix();
    }
    
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Rotate(yRot * -2.0f, 0, 1, 0);
    modelViewMatrix.Translate(0.8f, 0.0f, 0.0f);
    shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vLightPos, vSpereColor);
    sphereBatch.Draw();
    modelViewMatrix.PopMatrix();

    modelViewMatrix.PopMatrix();
    
    glutSwapBuffers();
    glutPostRedisplay();
}

void ChangeSize(int w, int h){
    glViewport(0, 0, w, h);
    viewFrustum.SetPerspective(35, float(w)/float(h), 1, 500);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
}

void SpeacialKeys(int key, int x, int y){
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

void SetupRC(){
    glClearColor(0, 0, 0, 1);
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);
    
    //3. 地板数据(物体坐标系)
    floorBatch.Begin(GL_LINES, 324);
    for(GLfloat x = -20.0; x <= 20.0f; x+= 0.5) {
        floorBatch.Vertex3f(x, -0.55f, 20.0f);
        floorBatch.Vertex3f(x, -0.55f, -20.0f);
        
        floorBatch.Vertex3f(20.0f, -0.55f, x);
        floorBatch.Vertex3f(-20.0f, -0.55f, x);
    }
    floorBatch.End();
    
    //4. 设置一个球体(基于gltools模型)
//    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    gltMakeTorus(torusBatch, 0.4f, 0.2f, 52, 26);

    //5. 随机位置放置小球球
    for (int i = 0; i < NUM_SPHERES; i++) {

        //y轴不变，X,Z产生随机值
        GLfloat x = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);
        GLfloat z = ((GLfloat)((rand() % 400) - 200 ) * 0.1f);

        //在y方向，将球体设置为0.0的位置，这使得它们看起来是飘浮在眼睛的高度
        //对spheres数组中的每一个顶点，设置顶点数据
        spheres[i].SetOrigin(x, 0.0f, z);
    }
    
    //6. 绘制小球;
    gltMakeSphere(sphereBatch, 0.1f, 13, 26);
}

int main(int argc, char * argv[]) {
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DEPTH | GLUT_RGB | GLUT_DOUBLE);
    glutInitWindowSize(800, 600);
    glutCreateWindow("test");
    
    glutDisplayFunc(RenderScene);
    glutReshapeFunc(ChangeSize);
    glutSpecialFunc(SpeacialKeys);
    
    GLenum error = glewInit();
    if(error != GLEW_OK){
        return 1;
    }
    
    SetupRC();
    glutMainLoop();
    
    return 0;
}

