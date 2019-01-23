
#import "LineOfSightVisualizer.h"
#import "Globals.h"

@interface LineOfSightVisualizer () {
	ccVertex2F vertices[15];
	ccColor4B  colors[15];

    int count;
    BOOL valid;

    ccColor4B losOkColor;
    ccColor4B losBlockedColor;

    // line width
    float width;
}

@end


@implementation LineOfSightVisualizer

- (id) init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:sNotificationSelectionChanged object:nil];

        // shader for positions and colors
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];

        // default line width
        width = 2.0f;

        losOkColor      = ccc4( 100, 255, 100, 160 );
        losBlockedColor = ccc4( 255, 0, 0, 160 );
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    // always assume we haven't been given positions yet
    valid = NO;

    Unit * selected = [Globals sharedInstance].selection.selectedUnit;
    
    // any current unit?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // no unit or enemy
        self.visible = NO;
        return;
    }
    
    self.visible = YES;
}


- (void) showFrom:(CGPoint)start to:(CGPoint)end {
    // a Npx long normalized vector perpendicular to start->end
    CGPoint vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( end, start ) ) ), width );

    //       v1                    v2
    // start ----------------------> end
    //       v4                    v3

    // triangle 1
    vertices[0].x = start.x + vec.x;
    vertices[0].y = start.y + vec.y;
    vertices[1].x = end.x   + vec.x;
    vertices[1].y = end.y   + vec.y;
    vertices[2].x = end.x   - vec.x;
    vertices[2].y = end.y   - vec.y;

    // triangle 2
    vertices[3].x = end.x   - vec.x;
    vertices[3].y = end.y   - vec.y;
    vertices[4].x = start.x - vec.x;
    vertices[4].y = start.y - vec.y;
    vertices[5].x = start.x + vec.x;
    vertices[5].y = start.y + vec.y;

    // fill in the colors with "ok" 
    for ( int index = 0; index < 6; ++index ) {
        colors[ index ] = losOkColor;
    }

    // create the final arrow
    [self createArrowFrom:start to:end atIndex:6 witColor:losOkColor];

    // arrow color
    colors[6] = losOkColor;
    colors[7] = losOkColor;
    colors[8] = losOkColor;

    // we now have 6 vertices
    count = 9;
    
    self.visible = YES;
    valid = YES;
}


- (void) showFrom:(CGPoint)start toMiddle:(CGPoint)middle withEnd:(CGPoint)end {
    // a Npx long normalized vector perpendicular to start->end
    CGPoint vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( end, start ) ) ), width );


    //       v1                    v2
    // start ----------------------> middle
    //       v4                    v3

    // triangle 1
    vertices[0].x = start.x  + vec.x;
    vertices[0].y = start.y  + vec.y;
    vertices[1].x = middle.x + vec.x;
    vertices[1].y = middle.y + vec.y;
    vertices[2].x = middle.x - vec.x;
    vertices[2].y = middle.y - vec.y;

    // triangle 2
    vertices[3].x = middle.x - vec.x;
    vertices[3].y = middle.y - vec.y;
    vertices[4].x = start.x  - vec.x;
    vertices[4].y = start.y  - vec.y;
    vertices[5].x = start.x  + vec.x;
    vertices[5].y = start.y  + vec.y;
    
    //        v1                    v2
    // middle ----------------------> end
    //        v4                    v3

    // triangle 1
    vertices[6].x = middle.x  + vec.x;
    vertices[6].y = middle.y  + vec.y;
    vertices[7].x = end.x + vec.x;
    vertices[7].y = end.y + vec.y;
    vertices[8].x = end.x - vec.x;
    vertices[8].y = end.y - vec.y;

    // triangle 2
    vertices[9].x = end.x - vec.x;
    vertices[9].y = end.y - vec.y;
    vertices[10].x = middle.x  - vec.x;
    vertices[10].y = middle.y  - vec.y;
    vertices[11].x = middle.x  + vec.x;
    vertices[11].y = middle.y  + vec.y;

    // fill in the colors too
    for ( int index = 0; index < 6; ++index ) {
        // first part is "ok"
        colors[ index ] = losOkColor;

        // second part is "blocked"
        colors[ index + 6] = losBlockedColor;
    }

    // create the final arrow
    [self createArrowFrom:start to:end atIndex:12 witColor:losBlockedColor];

    // arrow color
    colors[12] = losBlockedColor;
    colors[13] = losBlockedColor;
    colors[14] = losBlockedColor;

    // we now have 15 vertices
    count = 15;

    self.visible = YES;
    valid = YES;
}


- (void) createArrowFrom:(CGPoint)start to:(CGPoint)end atIndex:(unsigned int)index witColor:(ccColor4B)color {
    // last add the arrow triangle
    float arrowLength = 8;
    float halfArrowWidth = 5;

    // the position along the start->end vector where the arrow base is (the back line)
    CGPoint direction = ccpMult( ccpNormalize( ccpSub( end, start ) ), arrowLength );

    // a N px long normalized vector perpendicular to start->end, used to give the two position along the base line
    CGPoint vec = ccpMult( ccpNormalize( ccpPerp( direction ) ), halfArrowWidth );

    // the three vertices: top, base1, base2
    vertices[index + 0].x = end.x + direction.x;
    vertices[index + 0].y = end.y + direction.y;
    vertices[index + 1].x = end.x + vec.x;
    vertices[index + 1].y = end.y + vec.y;
    vertices[index + 2].x = end.x - vec.x;
    vertices[index + 2].y = end.y - vec.y;
}


- (void) draw {
    // can't paint without valid data
    if ( ! valid ) {
        self.visible = NO;
        return;
    }
    
    CC_NODE_DRAW_SETUP();

    ccGLBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );

    // enable position and color
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    CHECK_GL_ERROR_DEBUG();

    // Pass the verticies to draw to OpenGL
    glVertexAttribPointer( kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices );
    glVertexAttribPointer( kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, colors );

    // draw the triangles
    glDrawArrays( GL_TRIANGLES, 0, count );
    CHECK_GL_ERROR_DEBUG();

    // disable all arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_None );
    
    CC_INCREMENT_GL_DRAWS(1);
}

@end
