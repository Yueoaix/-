//
//  XYPointParticleEffect.h
//  01 粒子系统
//
//  Created by 钟晓跃 on 2019/6/20.
//  Copyright © 2019 钟晓跃. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN

extern const GLKVector3 XYDefaultGravity;

@interface XYPointParticleEffect : NSObject

@property (nonatomic, assign) GLKVector3 gravity;

@property (nonatomic, assign) GLfloat elapsedSeconds;

@property (nonatomic, strong, readonly) GLKEffectPropertyTexture *texture2d0;

@property (strong, nonatomic, readonly) GLKEffectPropertyTransform *transform;

//添加粒子
/*
 aPosition:位置
 aVelocity:速度
 aForce:重力
 aSize:大小
 aSpan:跨度
 aDuration:时长
 */
- (void)addParticleAtPosition:(GLKVector3)aPosition velocity:(GLKVector3)aVelocity force:(GLKVector3)aForce size:(float)aSize lifeSpanSeconds:(NSTimeInterval)aSpan fadeDurationSeconds:(NSTimeInterval)aDuration;

- (void)prepareToDraw;

- (void)draw;

@end

NS_ASSUME_NONNULL_END
