//
//  CSView.m
//  GLSL_Pyramid
//
//  Created by 鲸鱼集团技术部 on 2020/8/1.
//  Copyright © 2020 com.sanqi.net. All rights reserved.
//

#import "CSView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface CSView ()
{
    float xDegree;
    float yDegree;
    float zDegree;
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    NSTimer *myTimer;
}
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, strong) EAGLContext *myContext;

@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;

@property (nonatomic, assign) GLuint myPorgram;
@property (nonatomic, assign) GLuint myVertices;

@end

@implementation CSView

- (void)layoutSubviews {
    //1. 设置图层
    [self setupLayer];

    //2. 设置上下文
    [self setupContext];

    //3. 清空缓存区
    [self deleteBuffer];

    //4. 设置renderBuffer
    [self setupRenderBuffer];

    //5. 设置FrameBuffer
    [self setupFrameBuffer];

    //6. 绘制
    [self render];
}


//1. 设置图层
- (void)setupLayer {
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    self.myEagLayer.opaque = YES;
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//2. 设置上下文
- (void)setupContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"create context failed");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"set current context failed");
        return;
    }
    self.myContext = context;
}

//3. 清空缓存区
- (void)deleteBuffer {
    glDeleteBuffers(1, &_myColorRenderBuffer);
    _myColorRenderBuffer = 0;

    glDeleteBuffers(1, &_myColorFrameBuffer);
    _myColorFrameBuffer = 0;
}

//4. 设置renderBuffer
- (void)setupRenderBuffer {
    //1. 定义一个缓存区
    GLuint buffer;
    //2. 申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    //3. 将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

//5. 设置FrameBuffer
- (void)setupFrameBuffer {
    //1. 定义一个缓存区
    GLuint buffer;
    //2. 申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    //3.设置当前的framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //4. 将myColorRenderBuffer 装配到GL_COLOR_ATTACHMENT0附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

//6. 绘制
- (void)render {
    //1.清屏颜色
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    CGFloat scale = [UIScreen mainScreen].scale;
    //2. 设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);

    //3. 获取顶点着色器和片元着色器程序文件位置
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
//    NSLog(@"vertFile == %@ \n\n fragFile == %@", vertFile, fragFile);

    //4. 判断self.myProgram是否存在，存在则清空其文件
    if (self.myPorgram) {
        glDeleteProgram(self.myPorgram);
        self.myPorgram = 0;
    }

    //5. 加载程序到myProgram中
    self.myPorgram = [self loadShader:vertFile withFrag:fragFile];

    //6. 链接
    glLinkProgram(self.myPorgram);
    GLint linkSuccess;

    //7.获取链接状态
    glGetProgramiv(self.myPorgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(self.myPorgram, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"error %@", messageStr);
        return;
    }else {
        glUseProgram(self.myPorgram);
    }

    //8. -------创建顶点数组 和 索引数组-----
    //(1)顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB)
//    GLfloat attrArr[] =
//    {
//        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上0
//        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上1
//        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下2
//
//        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下3
//        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点4
//    };

    //前3个元素是顶点数据，中间3个是颜色值，最后2个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,       0.0f, 0.0f,//左下

        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,       0.5f, 0.5f,//顶点
    };

    //(2).索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };

    //(3).判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }

    //9.-------处理顶点数据------
    //(1).将_myVertices绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //(2).把顶点数据从CPU内复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    //(3).将顶点数据通过myProgram中的传递到顶点着色器程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myPorgram, "position");
    //(4)打开position
    glEnableVertexAttribArray(position);
    //(5).设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, NULL);

    //10.-------处理顶点颜色值------
    //(1).glGetAttribLocation,用来获取vertex attribute的入口的.
    //注意：第二参数字符串必须和shaderv.glsl中的输入变量：positionColor保持一致
    GLuint positionColor = glGetAttribLocation(self.myPorgram, "positionColor");
    //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(positionColor);
    //(3).设置读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (float *)NULL + 3);

    //10.1 -----处理纹理数据
    GLuint textCoor = glGetAttribLocation(self.myPorgram, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (float *)NULL + 6);

    //10.2 加载纹理
    [self setupTexture:@"xiannv"];

    //10.3 设置纹理采样器 sampler2D
    glUniform1i(glGetUniformLocation(self.myPorgram, "colorMap"), 0);

    //11.找到myPrograme的projectionMatrix, modelViewMatrix 2个矩阵的地址，如果找到则返回地址，否则返回-1，表示没有找到2个对象
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myPorgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myPorgram, "modelViewMatrix");

    float width = self.frame.size.width;
    float height = self.frame.size.height;

    //12.创建4*4投影矩阵
    KSMatrix4 _projectionMatrix;
    //(1).获取单元矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    //(2).计算纵横比
    float aspect = width / height;
    //(3).获取透视矩阵
    /*
    参数1：矩阵
    参数2：视角，度数为单位
    参数3：纵横比
    参数4：近平面距离
    参数5：远平面距离
    */
    //透视变换，视角30度
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f);
    //(4).将投影矩阵传递到顶点着色器
    /*
    void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
    参数列表：
    location:指要更改的uniform变量的位置
    count:更改矩阵的个数
    transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
    value:执行count个元素的指针，用来更新指定uniform变量
    */
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);

    //13. 创建一个4*4矩阵，模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //(1)获取单元矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //(2)平移，z轴平移-10
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    //(3)创建一个4*4的旋转矩阵
    KSMatrix4 _rotationMatrix;
    //(4)初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
    //(5)旋转
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0); //围绕X轴
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //围绕y轴
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0); //围绕z轴
    //(6)把变换矩阵相乘，将——modelViewMatrix矩阵与_rotaionMatrix矩阵相乘，结合到模型视图
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    //(7)将模型视图矩阵传递到顶点着色器
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);

    //14.开启剔除正面操作
    glEnable(GL_CULL_FACE);

    //15.使用索引绘制图片
    /*
    void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
    参数列表：
    mode:要呈现的画图的模型
               GL_POINTS
               GL_LINES
               GL_LINE_LOOP
               GL_LINE_STRIP
               GL_TRIANGLES
               GL_TRIANGLE_STRIP
               GL_TRIANGLE_FAN
    count:绘图个数
    type:类型
            GL_BYTE
            GL_UNSIGNED_BYTE
            GL_SHORT
            GL_UNSIGNED_SHORT
            GL_INT
            GL_UNSIGNED_INT
    indices：绘制索引数组
    */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);

    //16.要求本地窗口系统显示渲染目标
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)setupTexture:(NSString *)filePath {
    //1.将图片uiimage转换成CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:filePath].CGImage;
    if (!spriteImage) {
        NSLog(@"failed to load image %@", filePath);
        return 1;
    }
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);

    GLubyte *spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));

    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

    CGRect rect = CGRectMake(0, 0, width, height);

    CGContextDrawImage(spriteContext, rect, spriteImage);

    CGContextRelease(spriteContext);

    glBindTexture(GL_TEXTURE_2D, 0);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    float fw = width, fh = height;

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

    free(spriteData);
    return 0;
}

- (GLuint)loadShader:(NSString *)vertFile withFrag:(NSString *)fragFile {

    //创建2个临时变量，verShander, fragShader
    GLuint verShader, fragShader;
    //创建一个空的program
    GLuint program = glCreateProgram();

    //编译文件
    //编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self complieShader:&verShader type:GL_VERTEX_SHADER file:vertFile];
    [self complieShader:&fragShader type:GL_FRAGMENT_SHADER file:fragFile];

    //创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);

    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);

    return program;
}

//编译连接shader
- (void)complieShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //获取文件路径字符串，转为C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];

    //创建shader
    *shader = glCreateShader(type);

    //将顶点着色器源码附加到着色器对象上
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);

    //把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

- (IBAction)xButtonClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bX = !bX;
}
- (IBAction)yButtonClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bY = !bY;
}
- (IBAction)zButtonClick:(id)sender {
    //开启定时器
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    bZ = !bZ;
}

- (void)reDegree {
    //如果停止X轴旋转，X= 0则度数就停留在暂停前的度数
    //更新度数
    xDegree += bX * 5;
    yDegree += bY * 5;
    zDegree += bZ * 5;
    //重新渲染
    [self render];
}

@end
