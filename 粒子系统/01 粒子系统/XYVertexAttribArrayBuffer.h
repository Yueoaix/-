//
//  XYVertexAttribArrayBuffer.h
//  01 粒子系统
//
//  Created by 钟晓跃 on 2019/6/20.
//  Copyright © 2019 钟晓跃. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN

//重定义顶点属性
typedef enum {
    XYVertexAttribPosition = GLKVertexAttribPosition,//位置
    XYVertexAttribNormal = GLKVertexAttribNormal,//光照
    XYVertexAttribColor = GLKVertexAttribColor,//颜色
    XYVertexAttribTexCoord0 = GLKVertexAttribTexCoord0,//纹理1
    XYVertexAttribTexCoord1 = GLKVertexAttribTexCoord1,//纹理2
} XYVertexAttrib;

@interface XYVertexAttribArrayBuffer : NSObject

@property (nonatomic, readonly) GLuint name;

@property (nonatomic, readonly) GLsizeiptr bufferSizeBytes;

@property (nonatomic, readonly) GLsizeiptr stride;

//根据模式绘制已经准备数据
//绘制
+ (void)drawPerparedArraysWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfvertices:(GLsizei)count;

//初始
- (id)initWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr usage:(GLenum)usage;

//准备绘制
- (void)prepareToDrawWithAttrib:(GLuint)index numberOfCoordinates:(GLint)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable;

//绘制
- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count;

//重新初始化数据
- (void)reinitWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr;


@end

NS_ASSUME_NONNULL_END
