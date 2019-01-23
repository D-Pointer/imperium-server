

#import "Water.h"
#import "Globals.h"
#import "GameLayer.h"

const GLchar * WaterFragmentShader =
#import "WaterFragmentShader.h"

@interface Water () {

    GLint timePos;
    GLint offsetPos;
    float accumulatedTime;

    float offset[2];
}

@end


@implementation Water

- (void) setupShaders {
    self.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTexture_vert
                                                    fragmentShaderByteArray:WaterFragmentShader];

    [self.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    [self.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];

    [self.shaderProgram link];
    [self.shaderProgram updateUniforms];

    // the u_time is a uniform that gets fed the current time in seconds at every draw call
    timePos = glGetUniformLocation( self.shaderProgram.program, [@"u_time" UTF8String] );
    CHECK_GL_ERROR_DEBUG();

    // the u_offset is a uniform that gets fed the current map scrolling offset
    offsetPos = glGetUniformLocation( self.shaderProgram.program, [@"u_offset" UTF8String] );
    CHECK_GL_ERROR_DEBUG();

    // start from no accumukated time.
    accumulatedTime = 0;

    // default offsets
    offset[0] = 0;
    offset[1] = 0;

    [self scheduleUpdate];
}


- (void) update:(ccTime)dt {
    accumulatedTime += dt;
}


- (void) draw {
    CC_NODE_DRAW_SETUP();

    // give the time to the shader
    glUniform1f( timePos, accumulatedTime );

    // current panning offset
    CGPoint panOffset = [Globals sharedInstance].gameLayer.panOffset;
    offset[0] = panOffset.x;
    offset[1] = panOffset.y;
    
    // give the offset to the shader
    glUniform2fv( offsetPos, 1, offset );

    [super draw];
}


@end
