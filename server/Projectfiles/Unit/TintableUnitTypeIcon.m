

#import "TintableUnitTypeIcon.h"
#import "Globals.h"

#define kTintableUnitTypeIconFragmentShader		@"TintableUnitTypeIconFragmentShader"

const GLchar * TintableUnitTypeIconFragmentShader =
#import "TintableUnitTypeIconFragmentShader.h"

@interface TintableUnitTypeIcon () {

    GLint tintColorPos;

    ccColor4F _tintColor;
}

@end


@implementation TintableUnitTypeIcon

- (void) setTintColor:(ccColor4F)tintColor {
    _tintColor = tintColor;
}

- (ccColor4F) tintColor {
    return _tintColor;
}


- (void) setupShaders {
    // try to get the shader from the cache first
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kTintableUnitTypeIconFragmentShader];
    if ( self.shaderProgram == nil ) {
        // not found, so create and add it
        self.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTexture_vert
                                                        fragmentShaderByteArray:TintableUnitTypeIconFragmentShader];
        [[CCShaderCache sharedShaderCache] addProgram:self.shaderProgram forKey:kTintableUnitTypeIconFragmentShader];
    }

    [self.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    [self.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
    [self.shaderProgram addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];

    [self.shaderProgram link];
    [self.shaderProgram updateUniforms];

    // default to a black tint color that adds nothing
    _tintColor = ccc4f( 1.0f, 0, 0, 1.0f);

    // the u_level is a uniform that gets fed the current time in seconds at every draw call
    tintColorPos = [self.shaderProgram uniformLocationForName:@"u_tintColor"];

    CHECK_GL_ERROR_DEBUG();

    [self.shaderProgram setUniformLocation:tintColorPos with4fv:(GLfloat *)&_tintColor.r count:1];
    [self scheduleUpdate];
}


//- (void) draw {
//    CC_NODE_DRAW_SETUP();
//
//    // give the color to the shader
//    glUniform4fv( tintColorPos, 4, &_tintColor.r );
//
//    [super draw];
//}


@end
