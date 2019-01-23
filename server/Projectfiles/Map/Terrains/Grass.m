

#import "Grass.h"
#import "Globals.h"
#import "GameLayer.h"
#import "Globals.h"

const GLchar * grassVertexShader =
#import "GrassVertexShader.h"

const GLchar * grassFragmentShader =
#import "GrassFragmentShader.h"

@interface Grass () {
    // sample locations
    GLint terrainPos;
    GLint normalMapPos;
    GLint mapWidthPos;
    GLint mapHeightPos;
    GLint offsetPos;

    float offset[2];
}
@end


@implementation Grass

- (void) setupShaders {
    self.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:grassVertexShader
                                                    fragmentShaderByteArray:grassFragmentShader];

    [self.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    [self.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];

    [self.shaderProgram link];
    [self.shaderProgram updateUniforms];

    [self.shaderProgram use];

    // query all uniforms
    terrainPos   = glGetUniformLocation( self.shaderProgram.program, [@"u_terrain" UTF8String]);
    CHECK_GL_ERROR_DEBUG();
    normalMapPos = glGetUniformLocation( self.shaderProgram.program, [@"u_normalMap" UTF8String]);
    CHECK_GL_ERROR_DEBUG();
    mapWidthPos   = glGetUniformLocation( self.shaderProgram.program, [@"u_mapWidth" UTF8String] );
    CHECK_GL_ERROR_DEBUG();
    mapHeightPos   = glGetUniformLocation( self.shaderProgram.program, [@"u_mapHeight" UTF8String] );
    CHECK_GL_ERROR_DEBUG();

    // the u_offset is a uniform that gets fed the current map scrolling offset
    offsetPos = glGetUniformLocation( self.shaderProgram.program, [@"u_offset" UTF8String] );
    CHECK_GL_ERROR_DEBUG();

    // give the map size to the shader
    glUniform1f( mapWidthPos, [Globals sharedInstance].mapLayer.mapWidth );
    CHECK_GL_ERROR_DEBUG();
    glUniform1f( mapHeightPos, [Globals sharedInstance].mapLayer.mapHeight );
    CHECK_GL_ERROR_DEBUG();
}


//- (void) bindTextures {
//    // bind the textures
//    glUniform1i( terrainPos, 0 );
//    glActiveTexture( GL_TEXTURE0 );
//    glBindTexture( GL_TEXTURE_2D, [self.texture name] );
//    CHECK_GL_ERROR_DEBUG();
//
//    glUniform1i( normalMapPos, 1 );
//    glActiveTexture( GL_TEXTURE1 );
//    glBindTexture( GL_TEXTURE_2D, [self.normalMap name] );
//    CHECK_GL_ERROR_DEBUG();
//}


- (void) draw {
    [self.shaderProgram use];

    // current panning offset
    CGPoint panOffset = [Globals sharedInstance].gameLayer.panOffset;
    offset[0] = panOffset.x;
    offset[1] = panOffset.y;

    // give the offset to the shader
    glUniform2fv( offsetPos, 1, offset );
    CHECK_GL_ERROR_DEBUG();

    [super draw];
    CHECK_GL_ERROR_DEBUG();

    glActiveTexture( GL_TEXTURE0 );
}

@end
