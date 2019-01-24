
#import "CommandRangeVisualizer.h"
#import "Globals.h"
#import "Definitions.h"

@interface CommandRangeVisualizer () {
    ccVertex2F * vertices;
    ccColor4B * colors;

    GLfloat * unitVertices;
    ccColor3B * unitColors;
    NSUInteger subordinateCount;
}

@end


@implementation CommandRangeVisualizer

- (id)init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:sNotificationSelectionChanged object:nil];

        // define what shader program OpenGL ES 2.0 should use.
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];

        self.visible = NO;

        vertices = malloc( 37 * 2 * sizeof(ccVertex2F) );
        colors   = malloc( 37 * 2 * sizeof(ccColor4B) );

        // same color for the command range circle
        int colorIndex = 0;
        for ( int index = 0; index < 37; ++index ) {
            colors[ colorIndex++ ] = sCommandRangeLineColorNear;
            colors[ colorIndex++ ] = sCommandRangeLineColorFar;
        }

        unitVertices = NULL;
        unitColors = NULL;
        subordinateCount = 0;
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if ( vertices != NULL ) {
        free( vertices );
        vertices = NULL;
    }

    if ( colors != NULL ) {
        free( colors );
        colors = NULL;
    }

    if ( unitVertices != NULL ) {
        free( unitVertices );
        unitVertices = NULL;
    }

    if ( unitColors != NULL ) {
        free( unitColors );
        unitColors = NULL;
    }
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    [self updatePosition];
}


- (void) updatePosition {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;
    
    // precautions, any current unit?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId || ! selected.isHeadquarter ) {
        // no unit or enemy or no hq
        self.visible = NO;
        return;
    }

    // do not show ourselves if we should not show command control
    if ( [Settings sharedInstance].showCommandControl == NO ) {
        self.visible = NO;
        return;
    }

    // show ourselves and recreate the firing arc
    self.visible = YES;

    self.position = selected.position;

    // how far does the HQ's command reach?
    float commandRange = selected.commandRange;

    // first and last position is the unit center
    int index = 0;

    float halfWidth = sParameters[kParamCommandRangeLineWidthF].floatValue / 2.0f;

    // loop around
    for (unsigned int angle = 0; angle <= 360; angle += 10 ) {
        vertices[ index ].x = (commandRange - halfWidth) * cosf( CC_DEGREES_TO_RADIANS( angle ) );
        vertices[ index++ ].y = (commandRange - halfWidth) * sinf( CC_DEGREES_TO_RADIANS( angle ) );
        vertices[ index ].x = (commandRange + halfWidth) * cosf( CC_DEGREES_TO_RADIANS( angle ) );
        vertices[ index++ ].y = (commandRange + halfWidth) * sinf( CC_DEGREES_TO_RADIANS( angle ) );
        //vertices[ index++ ] = commandRange * sinf( CC_DEGREES_TO_RADIANS( angle ) );
    }

    // set up subordinates too
    [self updateSubordinates];
}


- (void) updateSubordinates {
    // free old and allocate new memory
    if ( unitVertices != NULL ) {
        free( unitVertices );
        unitVertices = NULL;
    }

    if ( unitColors != NULL ) {
        free( unitColors );
        unitColors = NULL;
    }

    Unit * selectedHq = [Globals sharedInstance].selection.selectedUnit;

    // precautions, any current unit?
    if ( selectedHq == nil || selectedHq.owner != [Globals sharedInstance].localPlayer.playerId || ! selectedHq.isHeadquarter ) {
        // no unit or enemy or no hq
        self.visible = NO;
        return;
    }

    // get the local player's units
    CCArray * units = selectedHq.owner == kPlayer1 ? [Globals sharedInstance].unitsPlayer1 : [Globals sharedInstance].unitsPlayer2;
    CCArray * subordinates = [CCArray new];
    for ( Unit * unit in units ) {
        if ( !unit.destroyed && unit.headquarter && unit.headquarter.unitId == selectedHq.unitId ) {
            [subordinates addObject:unit];
        }
    }

    // any subordinate units?
    subordinateCount = subordinates.count;
    if ( subordinateCount == 0 ) {
        return;
    }

    // how far does the HQ's command reach?
    float commandRange = selectedHq.commandRange;

    // 6 vertices per line, each 2 floats
    unitVertices = malloc( subordinateCount * 6 * 2 * sizeof(CGFloat) );

    // 6 colors per line
    unitColors = malloc( subordinateCount * 6 * sizeof(ccColor3B) );

    float width = sParameters[kParamCommandRangeLineWidthF].floatValue / 2.0f;

    // lines to all subordinate units
    int index = 0;
    int colorIndex = 0;
    for ( Unit * subordinate in subordinates ) {
        // a Npx long normalized vector perpendicular to start->end
        CGPoint vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( subordinate.position, selectedHq.position ) ) ), width );

        //       v1                    v2
        // start ----------------------> end
        //       v4                    v3
        //
        // triangles: v1-v2-v3, v3-v4-v1

        // triangle 1
        unitVertices[ index++ ] = vec.x;
        unitVertices[ index++ ] = vec.y;
        unitVertices[ index++ ] = subordinate.position.x - selectedHq.position.x + vec.x;
        unitVertices[ index++ ] = subordinate.position.y - selectedHq.position.y + vec.y;
        unitVertices[ index++ ] = subordinate.position.x - selectedHq.position.x - vec.x;
        unitVertices[ index++ ] = subordinate.position.y - selectedHq.position.y - vec.y;

        // triangle 2
        unitVertices[ index++ ] = subordinate.position.x - selectedHq.position.x - vec.x;
        unitVertices[ index++ ] = subordinate.position.y - selectedHq.position.y - vec.y;
        unitVertices[ index++ ] = -vec.x;
        unitVertices[ index++ ] = -vec.y;
        unitVertices[ index++ ] = vec.x;
        unitVertices[ index++ ] = vec.y;

        // is the unit in command?
        if ( ccpDistance( subordinate.position, selectedHq.position ) < commandRange ) {
            // in command
            for ( int tmp = 0; tmp < 6; ++tmp ) {
                unitColors[ colorIndex++ ] = sSubordinateLineColor1;
            }
        }
        else {
            // not in command
            for ( int tmp = 0; tmp < 6; ++tmp ) {
                unitColors[ colorIndex++ ] = sSubordinateLineColor2;
            }
        }
    }
}


- (void) draw {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // precautions, any current unit?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId || ! selected.isHeadquarter ) {
        // no unit or enemy or no hq
        self.visible = NO;
        return;
    }
    
    // destroyed?
    if ( selected.destroyed ) {
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

    // draw the fan
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 37 * 2 );
    CHECK_GL_ERROR_DEBUG();

    // any subordinate units?
    if ( subordinateCount > 0 && unitVertices != NULL && unitColors != NULL ) {
        glVertexAttribPointer( kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, unitVertices );

        // Pass the colors of the vertices to draw to OpenGL
        glVertexAttribPointer( kCCVertexAttrib_Color, 3, GL_UNSIGNED_BYTE, GL_TRUE, 0, unitColors );
        CHECK_GL_ERROR_DEBUG();

        // use default blending
        ccGLBlendFunc( CC_BLEND_SRC, CC_BLEND_DST );

        // draw the lines to the units
        glDrawArrays( GL_TRIANGLES, 0, (int)subordinateCount * 6 );
        CHECK_GL_ERROR_DEBUG();
    }

    // disable all arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_None );

    CC_INCREMENT_GL_DRAWS(2);
}

@end
