//
//  XYVertexAttribArrayBuffer.m
//  01 粒子系统
//
//  Created by 钟晓跃 on 2019/6/20.
//  Copyright © 2019 钟晓跃. All rights reserved.
//

#import "XYVertexAttribArrayBuffer.h"

@implementation XYVertexAttribArrayBuffer

//根据模式绘制已经准备数据
//绘制
+ (void)drawPerparedArraysWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfvertices:(GLsizei)count {
    
    glDrawArrays(mode, first, count);
    
}

//初始
- (id)initWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr usage:(GLenum)usage {
    
    self = [super init];
    
    if (self != nil) {
        _stride = stride;
        _bufferSizeBytes = _stride * count;
        
        glGenBuffers(1, &_name);
        glBindBuffer(GL_ARRAY_BUFFER, self.name);
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, usage);
        
    }
    
    return self;
}

//准备绘制
- (void)prepareToDrawWithAttrib:(GLuint)index numberOfCoordinates:(GLint)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable {
    
    if (count < 0 || count > 4) {
        NSLog(@"Error:Count Error");
        return ;
        
    }
    
    if (_stride < offset) {
        NSLog(@"Error:_stride < Offset");
        return;
    }
    
    if (_name == 0) {
        NSLog(@"Error:name == Null");
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    
    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, (int)self.stride, NULL + offset);
    
}

//绘制
- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count {
    
    if (self.bufferSizeBytes < (first + count) * self.stride) {
        NSLog(@"Vertex Error!");
    }
    
    glDrawArrays(mode, first, count);
}

//重新初始化数据
- (void)reinitWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr {
    
    _stride = stride;
    
    _bufferSizeBytes = _stride * count;
    
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, GL_DYNAMIC_DRAW);
}
@end
