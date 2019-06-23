//
//  XYPointParticleEffect.m
//  01 粒子系统
//
//  Created by 钟晓跃 on 2019/6/20.
//  Copyright © 2019 钟晓跃. All rights reserved.
//

#import "XYPointParticleEffect.h"
#import "XYVertexAttribArrayBuffer.h"

//用于定义粒子属性的类型
typedef struct
{
    GLKVector3 emissionPosition;//发射位置
    GLKVector3 emissionVelocity;//发射速度
    GLKVector3 emissionForce;//发射重力
    GLKVector2 size;//发射大小
    GLKVector2 emissionTimeAndLife;//发射时间和寿命
}XYParticleAttributes;

//GLSL程序Uniform 参数
enum
{
    XYMVPMatrix,//MVP矩阵
    XYSamplers2D,//Samplers2D纹理
    XYElapsedSeconds,//耗时
    XYGravity,//重力
    XYNumUniforms//Uniforms个数
};

//属性标识符
typedef enum {
    XYParticleEmissionPosition = 0,//粒子发射位置
    XYParticleEmissionVelocity,//粒子发射速度
    XYParticleEmissionForce,//粒子发射重力
    XYParticleSize,//粒子发射大小
    XYParticleEmissionTimeAndLife,//粒子发射时间和寿命
} XYParticleAttrib;

@interface XYPointParticleEffect() {
    
    GLfloat elapsedSeconds;
    GLuint program;
    GLint uniforms[XYNumUniforms];
}

@property (strong, nonatomic, readwrite) XYVertexAttribArrayBuffer *particleAttributeBuffer;

@property (nonatomic, assign, readonly)  NSUInteger numberOfParticles;

@property (nonatomic, strong, readonly) NSMutableData *particleAttributesData;

@property (nonatomic, assign, readwrite) BOOL particleDataWasUpdated;

- (BOOL)loadShaders;

- (BOOL)compileShader:(GLuint *)shader type: (GLenum)type file:(NSString *)file;

- (BOOL)linkProgram:(GLuint)prog;

- (BOOL)validateProgram:(GLuint)prig;

@end

@implementation XYPointParticleEffect

@synthesize gravity;
@synthesize elapsedSeconds;
@synthesize texture2d0;
@synthesize transform;
@synthesize particleAttributeBuffer;
@synthesize particleAttributesData;
@synthesize particleDataWasUpdated;

const GLKVector3 XYDefaultGravity = {0.0f, -9.80665f, 0.0f};

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        
        texture2d0 = [[GLKEffectPropertyTexture alloc] init];
        texture2d0.enabled = YES;
        texture2d0.name = 0;
        texture2d0.target = GLKTextureTarget2D;
        texture2d0.envMode = GLKTextureEnvModeReplace;
        transform = [[GLKEffectPropertyTransform alloc] init];
        gravity = XYDefaultGravity;
        elapsedSeconds = 0.0;
        particleAttributesData = [NSMutableData data];
    }
    
    return self;
}

- (XYParticleAttributes)particleAtIndex:(NSUInteger)anIndex {
    
    const XYParticleAttributes *particlesPtr = (const XYParticleAttributes *)[self.particleAttributesData bytes];
    
    return particlesPtr[anIndex];
}

- (void)setParticle:(XYParticleAttributes)aParticle atIndex:(NSUInteger)anIndex {
    
    XYParticleAttributes *particlesPtr = (XYParticleAttributes *)[self.particleAttributesData mutableBytes];
    
    particlesPtr[anIndex] = aParticle;
    
    self.particleDataWasUpdated = YES;
}

- (void)addParticleAtPosition:(GLKVector3)aPosition velocity:(GLKVector3)aVelocity force:(GLKVector3)aForce size:(float)aSize lifeSpanSeconds:(NSTimeInterval)aSpan fadeDurationSeconds:(NSTimeInterval)aDuration {
    
    XYParticleAttributes newParticle;
    
    newParticle.emissionPosition = aPosition;
    newParticle.emissionVelocity = aVelocity;
    newParticle.emissionForce = aForce;
    newParticle.size = GLKVector2Make(aSize, aDuration);
    newParticle.emissionTimeAndLife = GLKVector2Make(elapsedSeconds, elapsedSeconds + aSpan);
    
    BOOL foundSlot = NO;
    
    const long count = self.numberOfParticles;
    
    for (int i = 0; i < count && !foundSlot; i++) {
        
        XYParticleAttributes oldParticle = [self particleAtIndex:i];
        if (oldParticle.emissionTimeAndLife.y < self.elapsedSeconds) {
            
            [self setParticle:newParticle atIndex:i];
            foundSlot = YES;
        }
    }
    
    if (!foundSlot) {
        [self.particleAttributesData appendBytes:&newParticle length:sizeof(newParticle)];
        self.particleDataWasUpdated = YES;
    }
    
}

- (NSUInteger)numberOfParticles {
    
    static long last;
    long ret = [self.particleAttributesData length] / sizeof(XYParticleAttributes);
    
    if (last != ret) {
        last = ret;
        NSLog(@"count %ld", ret);
    }
    
    return ret;
}

- (void)prepareToDraw {
    
    if (program == 0) {
        
        [self loadShaders];
    }
    
    if (program != 0) {
        
        glUseProgram(program);
        
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix, self.transform.modelviewMatrix);
        
        glUniformMatrix4fv(uniforms[XYMVPMatrix], 1, 0, modelViewProjectionMatrix.m);
        
        glUniform1i(uniforms[XYSamplers2D], 0);
        
        glUniform3fv(uniforms[XYElapsedSeconds], 1, &elapsedSeconds);
        
        glUniform3fv(uniforms[XYGravity], 1, self.gravity.v);
        
        glUniform1fv(uniforms[XYElapsedSeconds], 1, &elapsedSeconds);
        
        if (self.particleDataWasUpdated) {
            
            GLsizeiptr size = sizeof(XYParticleAttributes);
            
            int count = (int)[self.particleAttributesData length] / sizeof(XYParticleAttributes);
            
            if (self.particleAttributeBuffer == nil && [self.particleAttributesData length] > 0) {
                
                self.particleAttributeBuffer = [[XYVertexAttribArrayBuffer alloc]initWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes] usage:GL_DYNAMIC_DRAW];
            }else{
                
                [self.particleAttributeBuffer reinitWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes]];
            }
            
            self.particleDataWasUpdated = NO;
        }
        
        [self.particleAttributeBuffer prepareToDrawWithAttrib:XYParticleEmissionPosition numberOfCoordinates:3 attribOffset:offsetof(XYParticleAttributes, emissionPosition) shouldEnable:YES];
        
        [self.particleAttributeBuffer prepareToDrawWithAttrib:XYParticleEmissionVelocity numberOfCoordinates:3 attribOffset:offsetof(XYParticleAttributes, emissionVelocity) shouldEnable:YES];
        
        [self.particleAttributeBuffer prepareToDrawWithAttrib:XYParticleEmissionForce numberOfCoordinates:3 attribOffset:offsetof(XYParticleAttributes, emissionForce) shouldEnable:YES];
        
        [self.particleAttributeBuffer prepareToDrawWithAttrib:XYParticleSize numberOfCoordinates:2 attribOffset:offsetof(XYParticleAttributes, size) shouldEnable:YES];
        
        [self.particleAttributeBuffer prepareToDrawWithAttrib:XYParticleEmissionTimeAndLife numberOfCoordinates:2 attribOffset:offsetof(XYParticleAttributes, emissionTimeAndLife) shouldEnable:YES];
        
        glActiveTexture(GL_TEXTURE0);
        if (0 != self.texture2d0.name && self.texture2d0.enabled) {
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        }else{
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
    }
}

- (void)draw {
    
    glDepthMask(GL_FALSE);
    
    [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
    
    glDepthMask(GL_TRUE);
}


- (BOOL)loadShaders {
    
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    program = glCreateProgram();
    
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:
                          @"XYPointParticleShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:
                          @"XYPointParticleShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER
                        file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    glBindAttribLocation(program, XYParticleEmissionPosition, "a_emissionPosition");
    glBindAttribLocation(program, XYParticleEmissionVelocity,
                         "a_emissionVelocity");
    glBindAttribLocation(program, XYParticleEmissionForce,
                         "a_emissionForce");
    glBindAttribLocation(program, XYParticleSize,
                         "a_size");
    glBindAttribLocation(program, XYParticleEmissionTimeAndLife,
                         "a_emissionAndDeathTimes");
    
    if (![self linkProgram:program]) {
        NSLog(@"Failed to link program: %d", program);
        
        //link识别,删除vertex shader\fragment shader\program
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return NO;
    }
    
    uniforms[XYMVPMatrix] = glGetUniformLocation(program, "u_mvpMatrix");
    
    uniforms[XYSamplers2D] = glGetUniformLocation(program,"u_samplers2D");
    
    uniforms[XYGravity] = glGetUniformLocation(program,"u_gravity");
    
    uniforms[XYElapsedSeconds] = glGetUniformLocation(program,"u_elapsedSeconds");
    
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
    
}

- (BOOL)compileShader:(GLuint *)shader type: (GLenum)type file:(NSString *)file {
    
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
    
    GLint logLength;
    
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0) {
        
        GLchar *log = (GLchar *)malloc(logLength);
        
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        
        NSLog(@"Shader compile log:\n%s", log);
        
        free(log);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog {
    
    glLinkProgram(prog);
    
    GLint logLength;
    
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0) {
        
        GLchar *log = (GLchar *)malloc(logLength);
        
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        
        NSLog(@"Program link log:\n%s", log);
        
        free(log);
        
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog {
    
    GLint logLength, status;
    
    glValidateProgram(prog);
    
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
