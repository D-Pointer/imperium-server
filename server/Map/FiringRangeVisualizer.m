
#import "FiringRangeVisualizer.h"
#import "Globals.h"
#import "Settings.h"

@interface FiringRangeVisualizer () {
    ccVertex2F vertices[32];
    ccColor3B colors[32];
}

@end


@implementation FiringRangeVisualizer

- (id)init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:sNotificationSelectionChanged object:nil];

        // define what shader program OpenGL ES 2.0 should use.
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];

        self.visible = NO;

        // fill in with the color
        for ( int index = 0; index < 32; ++index ) {
            colors[ index ] = sFiringRangeLineColor;
        }
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    [self updatePosition];
}


- (void) updatePosition {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;
    
    // precautions, any current unit?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId || ! [selected canFire] ) {
        // no unit or enemy
        self.visible = NO;
        return;
    }

    // do not show ourselves if we should not show the firing range
    if ( [Settings sharedInstance].showFiringRange == NO ) {
        self.visible = NO;
        return;
    }

    // show ourselves and recreate the firing arc
    self.visible = YES;

    // how far can the unit shoot?
    float range = selected.weapon.firingRange;
    
    // firing angle
    float angle = selected.weapon.firingAngle;
    float start = CC_DEGREES_TO_RADIANS( 90 - selected.rotation - angle / 2.0f );

    // delta angle per step. 30 steps
    const float delta = CC_DEGREES_TO_RADIANS( angle / 30.0f );

    self.position = selected.position;

    // render the arc in 30 parts
    for (unsigned int index = 0; index < 30; index++ ) {
        GLfloat x = range * cosf( start + index * delta );
        GLfloat y = range * sinf( start + index * delta );

        // the +1 is to skip the first origin vertex
        vertices[ index + 1 ].x = x;
        vertices[ index + 1 ].y = y;
    }

    // a vector pointing at a 90 degree angle from the unit's facing
    CGPoint side1 = ccpMult( ccpForAngle( CC_DEGREES_TO_RADIANS( 90 - selected.rotation - 90) ), selected.formationWidth / 2.0f );
    CGPoint side2 = ccpNeg( side1 );

    vertices[0 ].x  = side1.x;
    vertices[0 ].y  = side1.y;
    vertices[31].x = side2.x;
    vertices[31].y = side2.y;
}


- (void) draw {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // precautions, any current unit?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // no unit or enemy
        self.visible = NO;
        return;
    }
    
    // destroyed?
    if ( selected.destroyed ) {
        self.visible = NO;
        return;
    }
    
    CC_NODE_DRAW_SETUP();

    // use default blending
    ccGLBlendFunc( CC_BLEND_SRC, CC_BLEND_DST );

    // enable position and color
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    CHECK_GL_ERROR_DEBUG();

    // Pass the verticies to draw to OpenGL
    glVertexAttribPointer( kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices );
    glVertexAttribPointer( kCCVertexAttrib_Color, 3, GL_UNSIGNED_BYTE, GL_TRUE, 0, colors );

    // draw the lines
    glDrawArrays( GL_LINE_STRIP, 0, 32 );
    CHECK_GL_ERROR_DEBUG();

    // disable all arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_None );

    CC_INCREMENT_GL_DRAWS(1);
}

@end
