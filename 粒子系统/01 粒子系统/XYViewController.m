//
//  XYViewController.m
//  01 粒子系统
//
//  Created by zhong on 2019/6/23.
//  Copyright © 2019年 钟晓跃. All rights reserved.
//

#import "XYViewController.h"
#import "XYVertexAttribArrayBuffer.h"
#import "XYPointParticleEffect.h"

@interface XYViewController ()

@property (nonatomic, strong) EAGLContext *mContext;

@property (nonatomic, strong) XYPointParticleEffect *particleEffect;

@property (nonatomic, assign) NSTimeInterval autoSpawnDelta;

@property (nonatomic, assign) NSTimeInterval lastSpawnTime;

@property (nonatomic, assign) NSInteger currentEmitterIndex;

@property (nonatomic, strong) NSArray *emitterBlocks;

@property (nonatomic, strong) GLKTextureInfo *ballParticleTexture;

@end

@implementation XYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mContext = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    
    [EAGLContext setCurrentContext:self.mContext];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"ball" ofType:@"png"];
    
    if (path == nil) {
        NSLog(@"ball texture image not found");
        return;
    }
    
    self.ballParticleTexture = [GLKTextureLoader textureWithContentsOfFile:path options:nil error:nil];
    
    self.particleEffect = [[XYPointParticleEffect alloc] init];
    self.particleEffect.texture2d0.name = self.ballParticleTexture.name;
    self.particleEffect.texture2d0.target = self.ballParticleTexture.target;
    
    glEnable(GL_DEPTH_TEST);
    
    glEnable(GL_BLEND);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    void (^blockA)() = ^{
        
        self.autoSpawnDelta = 0.5f;
        
        self.particleEffect.gravity = XYDefaultGravity;
        
        float randomXVelocity = -0.5 + 1.0f * (float)random() / (float)RAND_MAX;
        
        [self.particleEffect addParticleAtPosition:GLKVector3Make(0, 0, 0.9) velocity:GLKVector3Make(randomXVelocity, 1, -1) force:GLKVector3Make(0, 9, 0) size:8.0 lifeSpanSeconds:3.2 fadeDurationSeconds:0.5];
    };
    
    void (^blockB)() = ^{
        
        self.autoSpawnDelta = 0.05f;
        
        self.particleEffect.gravity = GLKVector3Make(0, 0.5, 0);
        
        int n = 50;
        
        for (int i = 0; i < n; i++) {
            
            //X轴速度
            float randomXVelocity = -0.1f + 0.2f *(float)random() / (float)RAND_MAX;
            
            //Y轴速度
            float randomZVelocity = 0.1f + 0.2f * (float)random() / (float)RAND_MAX;
            
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, -0.5f, 0.0f)
             velocity:GLKVector3Make(
                                     randomXVelocity,
                                     0.0,
                                     randomZVelocity)
             force:GLKVector3Make(0.0f, 0.0f, 0.0f)
             size:16.0f
             lifeSpanSeconds:2.2f
             fadeDurationSeconds:3.0f];
            
        }
        
    };
    
    void(^blockC)() = ^{
        
        self.autoSpawnDelta = 0.5f;
        
        //重力
        self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
        
        int n = 100;
        for(int i = 0; i < n; i++)
        {
            //X,Y,Z速度
            float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomZVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            
            //创建粒子
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
             velocity:GLKVector3Make(
                                     randomXVelocity,
                                     randomYVelocity,
                                     randomZVelocity)
             force:GLKVector3Make(0.0f, 0.0f, 0.0f)
             size:4.0f
             lifeSpanSeconds:3.2f
             fadeDurationSeconds:0.5f];
        }
        
    };
    
    void(^blockD)() = ^{
        self.autoSpawnDelta = 3.2f;
        
        //重力
        self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
        
        int n = 100;
        for(int i = 0; i < n; i++)
        {
            //X,Y速度
            float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            
            
            //GLKVector3Normalize 计算法向量
            //计算速度与方向
            GLKVector3 velocity = GLKVector3Normalize( GLKVector3Make(
                                                                      randomXVelocity,
                                                                      randomYVelocity,
                                                                      0.0f));
            
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
             velocity:velocity
             force:GLKVector3MultiplyScalar(velocity, -1.5f)
             size:4.0f
             lifeSpanSeconds:3.2f
             fadeDurationSeconds:0.1f];
        }
        
    };
    
    self.emitterBlocks = @[[blockA copy],[blockB copy],[blockC copy],[blockD copy]];
    
    float aspect = CGRectGetWidth(self.view.bounds) / CGRectGetHeight(self.view.bounds);
    
    [self preparePointOfViewWithAspectRatio:aspect];
}

- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio {
    
    self.particleEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85), aspectRatio, 0.1, 20);
    
    self.particleEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(
                                                                         0.0, 0.0, 1.0,   // Eye position
                                                                         0.0, 0.0, 0.0,   // Look-at position
                                                                         0.0, 1.0, 0.0);
}


- (void)update {
    
    NSTimeInterval timeElapsed = self.timeSinceFirstResume;
    
    self.particleEffect.elapsedSeconds = timeElapsed;
    
    if (self.autoSpawnDelta < (timeElapsed - self.lastSpawnTime)) {
        
        self.lastSpawnTime = timeElapsed;
        
        //获取当前选择的block
        void(^emitterBlock)() = [self.emitterBlocks objectAtIndex: self.currentEmitterIndex];
        
        //执行block
        emitterBlock();
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3, 0.3, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    
    //准备绘制
    [self.particleEffect prepareToDraw];
    
    //绘制
    [self.particleEffect draw];
}

- (IBAction)ChangeIndex:(UISegmentedControl *)sender {
    
    //选择不同的效果
    self.currentEmitterIndex = [sender selectedSegmentIndex];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown);
}
@end
