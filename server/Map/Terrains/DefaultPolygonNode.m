
#import "DefaultPolygonNode.h"

@implementation DefaultPolygonNode {
    // data for the triangles. vertices are repeated as needed
    ccTex2F * texcoords_;
}


- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing {
    self = [super initWithPolygon:vertices smoothing:smoothing];
    if (self) {
        // no textures yet
        texcoords_ = 0;
    }
    
    return self;    
}


- (void) setupShaders {
    // Must define what shader program OpenGL ES 2.0 should use.
    // The instance variable shaderProgram exists in the CCNode class in Cocos2d 2.0.
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];
}


//- (void) bindTextures {
//    // bind the texture
//    ccGLBindTexture2D( [self.texture name] );
//}


- (void) dealloc {
    if ( texcoords_ ) {
        free( texcoords_ );
        texcoords_ = 0;
    }
}


- (void) rotateTextureBy:(float)degrees {
    float sin = sinf( CC_DEGREES_TO_RADIANS( degrees ) );
    float cos = cosf( CC_DEGREES_TO_RADIANS( degrees ) );

    // loop all vertices
    for ( unsigned int index = 0; index < vertex_count; ++index ) {
        texcoords_[ index ].u = texcoords_[ index ].u * cos - texcoords_[ index ].v * sin;
        texcoords_[ index ].v = texcoords_[ index ].u * sin + texcoords_[ index ].v * cos;
    }
}


- (void) scaleTextureBy:(float)factor {
    for ( unsigned int index = 0; index < vertex_count; ++index ) {
        texcoords_[ index ].u *= factor;
        texcoords_[ index ].v *= factor;
    }
}


- (void) setTexture:(CCTexture2D *)texture {
    _texture = texture;
    
    // texture valid?
    if ( texture == nil ) {
        CCLOG( @"nil texture given for %@", self );

        // no, any old texcoords?
        if ( texcoords_ ) {
            free( texcoords_ );
            texcoords_ = 0;
        }
        
        return;
    }
    
    if ( texcoords_ != 0 ) {
        // tex coords already set up
        return;
    }
    
    // allocate some space
    texcoords_ = malloc( vertex_count * sizeof(ccTex2F) );
    
    float w = self.texture.contentSize.width;
    float h = self.texture.contentSize.height;

    // max possible v coordinate
    float max_v = ( max_y - min_y ) / h;
    
    // loop all vertices
    for ( unsigned int index = 0; index < vertex_count; ++index ) {
        // coordinate 0..max
        float x = vertices_[ index ].x - min_x;
        float y = vertices_[ index ].y - min_y;
        
        // the u,v can go from 0..n where n is the multiple of the dimensions, so 3.1 means to tile it 3.1 times
        float u = x / w;
        
        // the v is flipped
        float v = max_v - y / h; 

        ccTex2F texCoord = { u, v };
        texcoords_[ index ] = texCoord;
    }

    ccTexParams texParams = { GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT };
    [_texture setTexParameters:&texParams];
}


- (void) draw {
    CC_NODE_DRAW_SETUP();

    NSAssert( self.texture != nil && texcoords_ != 0, @"invalid state" );

    //[self bindTextures];
    ccGLBindTexture2D( [self.texture name] );

    // enable arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords  );
    
    // Pass the verticies and textures to OpenGL
    glVertexAttribPointer( kCCVertexAttrib_Position,  2, GL_FLOAT, GL_FALSE, 0, vertices_ );
    glVertexAttribPointer( kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0, texcoords_ );

    // draw the triangles
    glDrawArrays( GL_TRIANGLES, 0, (int)vertex_count );

    // disable all arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_None );

    CC_INCREMENT_GL_DRAWS(1);
}


@end
