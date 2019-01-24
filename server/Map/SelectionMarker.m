
#import "SelectionMarker.h"
#import "Globals.h"
#import "Definitions.h"
#import "Unit.h"

const GLchar * SelectionMarkerVertexShader =
#import "SelectionMarkerVertexShader.h"

const GLchar * SelectionMarkerFragmentShader =
#import "SelectionMarkerFragmentShader.h"

const float extraMargin = 5;

@interface SelectionMarker () {
    GLfloat vertices[37 * 4];

    ccColor4F color1;
    ccColor4F color2;
    GLint color1Pos;
    GLint color2Pos;

    GLint timePos;
    float time;

    BOOL increase;

    // flag used to indicate if color2 is for a selected unit (YES) or a unselected unit (NO)
    BOOL colorForSelected;
}

//@property (nonatomic, weak)   Unit *     unit;
@property (nonatomic, strong) CCSprite * facingMarker;

@end


@implementation SelectionMarker

- (id) init {
    self = [super init];
    if (self) {
        // start from a max accumulated time, start by decreasing alpha
        time = 0.0f;

        // direction up by default
        increase = YES;

        // we're hidden by default
        self.visible = NO;

        // a facing marker
        self.facingMarker = [CCSprite spriteWithSpriteFrameName:@"UnitDirection.png"];
        self.facingMarker.anchorPoint = ccp( 0.5f, 0 );        
        [self addChild:self.facingMarker z:1];

        // setup the shaders to be used
        [self setupShaders];

        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:)      name:sNotificationSelectionChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitStatsChanged:) name:sNotificationEngineSimulationDone object:nil];
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) setupShaders {
    self.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:SelectionMarkerVertexShader
                                                    fragmentShaderByteArray:SelectionMarkerFragmentShader];

    [self.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];

    [self.shaderProgram link];
    [self.shaderProgram updateUniforms];

    // the u_time is a uniform that gets fed the current time in seconds at every draw call
    timePos = glGetUniformLocation( self.shaderProgram.program, [@"u_time" UTF8String] );
    CHECK_GL_ERROR_DEBUG();

    // positions of the colors
    color1Pos = glGetUniformLocation( self.shaderProgram.program, [@"u_color1" UTF8String] );
    CHECK_GL_ERROR_DEBUG();
    color2Pos = glGetUniformLocation( self.shaderProgram.program, [@"u_color2" UTF8String] );
    CHECK_GL_ERROR_DEBUG();
}


- (void) selectedUnitChanged:(NSNotification *)notification {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // first always unschedule any updates
    [self unscheduleUpdate];

    // anything selected? hide/show suitably
    if ( ! selectedUnit || selectedUnit.destroyed ) {
        self.visible = NO;
        return;
    }

    // we're visible now with a selected unit
    self.visible = YES;

    // the colors depend on the owner
    if ( selectedUnit.owner == kPlayer1 ) {
        color1 = ccc4f( 0, 0, 1, 1 );
        color2 = ccc4f( 0.8, 0.8, 0.8, 1 );
    }
    else {
        color1 = ccc4f( 1, 0, 0, 1 );
        color2 = ccc4f( 0.8, 0.8, 0.8, 1 );
    }

    // we have a selected unit, update to fit it
    [self refresh];

    // and position ourselves under it
    self.position = selectedUnit.position;

    // reschedule an update, we need to animate
    [self scheduleUpdate];
}


- (void) selectedUnitStatsChanged:(NSNotification *)notification {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // anything selected? hide/show suitably
    if ( ! selectedUnit || selectedUnit.destroyed ) {
        self.visible = NO;
        return;
    }

    // we have a selected unit, update to fit it
    [self refresh];

    // and position ourselves under it
    self.position = selectedUnit.position;
}


- (void) update:(ccTime)dt {
    // this oscillates the time from 0 -> 1 -> 0
    if ( increase ) {
        time += dt;

        if ( time > 1.0f ) {
            time = 1.0f;
            increase = NO;
        }
    }
    else {
        time -= dt;

        if ( time < 0.0f ) {
            time = 0.0f;
            increase = YES;
        }
    }

    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // update the facing marker if we have anything selected
    if ( selectedUnit && ! selectedUnit.destroyed ) {
        float facing = selectedUnit.rotation;

        // find out the largest dimension of the unit sprite
        float radius = MAX( selectedUnit.boundingBox.size.width, selectedUnit.boundingBox.size.height ) / 2.0f + extraMargin;

        // but never go below a certain minimum
        radius = MAX( radius, 20 );

        // position for the facing marker
        float x = radius * cosf( CC_DEGREES_TO_RADIANS( 90 - facing ) );
        float y = radius * sinf( CC_DEGREES_TO_RADIANS( 90 - facing ) );

        self.facingMarker.position = ccp( x, y );
        self.facingMarker.rotation = facing;

        // and position ourselves under the unit
        self.position = selectedUnit.position;
    }

    // the arrow is only visible for column mode
    self.facingMarker.visible = selectedUnit.mode == kColumn;
}


- (void) refresh {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    float lineWidth = 1.0f;

    // find out the largest dimension of the unit sprite
    float radius = MAX( selectedUnit.boundingBox.size.width, selectedUnit.boundingBox.size.height ) / 2.0f + extraMargin;

    // but never go below a certain minimum
    radius = MAX( radius, 20 );

    int index = 0;
    
    // loop around and finish on the
    for (unsigned int angle = 0; angle <= 360; angle += 10 ) {
        vertices[ index++ ] = (radius - lineWidth / 2.0f) * cosf( CC_DEGREES_TO_RADIANS( angle ) );
        vertices[ index++ ] = (radius - lineWidth / 2.0f) * sinf( CC_DEGREES_TO_RADIANS( angle ) );
        vertices[ index++ ] = (radius + lineWidth / 2.0f) * cosf( CC_DEGREES_TO_RADIANS( angle ) );
        vertices[ index++ ] = (radius + lineWidth / 2.0f) * sinf( CC_DEGREES_TO_RADIANS( angle ) );
    }


    // update the facing marker too
    float facing = selectedUnit.rotation;

    // position for the facing marker
    float x = radius * cosf( CC_DEGREES_TO_RADIANS( 90 - facing ) );
    float y = radius * sinf( CC_DEGREES_TO_RADIANS( 90 - facing ) );

    self.facingMarker.position = ccp( x, y );
    self.facingMarker.rotation = facing;
}


- (void) draw {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // precautions, any current unit?
    if ( ! selectedUnit || selectedUnit.destroyed ) {
        self.visible = NO;
        return;
    }

    CC_NODE_DRAW_SETUP();

    // give the time to the shader
    glUniform1f( timePos, time );

    // and the colors
    glUniform4f( color1Pos, color1.r, color1.g, color1.b, color1.a );
    glUniform4f( color2Pos, color2.r, color2.g, color2.b, color2.a );

    // enable position and color
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );

    // Pass the verticies to draw to OpenGL
    glVertexAttribPointer( kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices );

    // draw the fan
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 37 * 2 );

    // disable all arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_None );

    CC_INCREMENT_GL_DRAWS( 1 );
}

//- (void) setupColors {
//    // the colors depend on the owner
//    if ( self.unit.owner == kPlayer1 ) {
//        color1 = ccc4f( 0, 0, 1, 1 );
//
//        if ( self.unit.selected ) {
//            color2 = ccc4f( 0.8, 0.8, 0.8, 1 );
//        }
//        else {
//            color2 = ccc4f( 0, 0, 1, 1 );
//        }
//    }
//    else {
//        color1 = ccc4f( 1, 0, 0, 1 );
//
//        if ( self.unit.selected ) {
//            color2 = ccc4f( 0.8, 0.8, 0.8, 1 );
//        }
//        else {
//            color2 = ccc4f( 1, 0, 0, 1 );
//        }
//    }
//
//    colorForSelected = self.unit.selected;
//}


//- (void) refreshFacing {
//    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
//
//    float facing = selectedUnit.rotation;
//
//    // find out the largest dimension of the unit sprite + some spacing
//    self.radius = MAX( self.unit.boundingBox.size.width, self.unit.boundingBox.size.height ) / 2.0f + extraMargin;
//
//    // but never go below a certain minimum
//    self.radius = MAX( self.radius, 20 );
//
//    // position for the facing marker
//    float x = self.radius * cosf( CC_DEGREES_TO_RADIANS( 90 - facing ) );
//    float y = self.radius * sinf( CC_DEGREES_TO_RADIANS( 90 - facing ) );
//
//    self.facingMarker.position = ccp( x, y );
//    self.facingMarker.rotation = facing;
//}


@end
