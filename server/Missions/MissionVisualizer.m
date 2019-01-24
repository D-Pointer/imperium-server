
#import "MissionVisualizer.h"
#import "Globals.h"
#import "Settings.h"

// starting and ending path width
#define START_HALF_WIDTH 4.0f
#define END_HALF_WIDTH   2.0f

#define START_OPACITY   220.0f
#define END_OPACITY     140.0f

@interface MissionVisualizer () {
    // data for the triangles. vertices are repeated as needed
    ccVertex2F * vertices;
    ccColor4B  * colors;

    unsigned int vertexCount;

    unsigned int lastPathLength;
}

@property (nonatomic, weak)   Unit *     unit;
//@property (nonatomic, strong) CCSprite * marker;

@end


@implementation MissionVisualizer

- (id) initWithUnit:(Unit *)unit {
    self = [super init];
    if (self) {
        self.unit   = unit;
        vertices   = nil;
        colors     = nil;
        vertexCount = 0;

        // no marker yet
        //self.marker = nil;

        // Must define what shader program OpenGL ES 2.0 should use.
        // The instance variable shaderProgram exists in the CCNode class in Cocos2d 2.0.
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if ( vertices ) {
        free( vertices );
        vertices = nil;
    }
    if ( colors ) {
        free( colors );
        colors = nil;
    }

    [self removeAllChildrenWithCleanup:YES];
}


- (void) update:(ccTime)delta {
    // precautions
    if ( self.unit.destroyed || [self.unit isIdle] ) {
        return;
    }

    // is the path still valid?
    Path * path = self.unit.mission.path;
    if ( path == nil || path.count == 0 ) {
        return;
    }

    // has the number of elements in the path changed?
    if ( path.positions.count != lastPathLength ) {
        [self refresh];
        return;
    }

    CGPoint startPos = self.unit.position;
    CGPoint nextPos = [[self.unit.mission.path.positions firstObject] CGPointValue];

    // a N px long normalized vector perpendicular to start->end
    CGPoint vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( nextPos, startPos ) ) ), START_HALF_WIDTH );

    // update vertices for triangle 1
    vertices[0].x = startPos.x + vec.x;
    vertices[0].y = startPos.y + vec.y;
    vertices[1].x = startPos.x - vec.x;
    vertices[1].y = startPos.y - vec.y;

    // update vertices for triangle 2
    vertices[5].x = vertices[1].x;
    vertices[5].y = vertices[1].y;
}


- (void) refresh {
    // by default no updates
    [self unscheduleUpdate];

    // no vertices yet
    vertexCount = 0;

    // any current unit?
    if ( self.unit == nil || self.unit.destroyed ) {
        // no unit or enemy
        self.visible = NO;
        return;
    }

    // do not show ourselves if we should not show missions for non selected units
    if ( [Settings sharedInstance].showAllMissions == NO && [Globals sharedInstance].selection.selectedUnit != self.unit ) {
        self.visible = NO;
        return;
    }

    // change mode missions are special and shown nothing
    if ( self.unit.mission.type == kChangeModeMission ) {
//        if ( self.marker == nil ) {
//            self.marker = [CCSprite spriteWithSpriteFrameName:@"Buttons/ChangeMode.png"];
//            [self addChild:self.marker];
//        }
//
//        // show the marker at the unit position
//        self.marker.position = self.unit.position;
//        self.marker.visible = YES;
//        self.visible = YES;
        return;
    }

    // no change mode marker should be shown here
//    if ( self.marker ) {
//        self.marker.visible = NO;
//    }

    Mission * mission = self.unit.mission;

    // disorganized? nothing to show here then
    if ( mission.type == kDisorganizedMission || mission.type == kIdleMission ) {
        self.visible = NO;
        return;
    }

    // complex path mission or simple one line mission?
    if ( (mission.type == kMoveMission || mission.type == kMoveFastMission || mission.type == kScoutMission || mission.type == kRetreatMission ||
        mission.type == kAdvanceMission || mission.type == kAssaultMission || mission.type == kRoutMission) &&
        mission.path.positions.count >= 2) {
        [self createPathLine];
     }
    else {
        // it's a simple one line mission
        [self createSimpleLine];
    }
}


- (void) createPathLine {
    Mission * mission = self.unit.mission;

    //
    // 1   3   5   7
    // --------------->
    // 2   4   6   8
    //

    Path * path = mission.path;
    NSArray * positions = path.positions;
    unsigned int positionCount = (unsigned int)positions.count;

    // the number of elements in the path now. We then check this later when updating to see if the path
    // length has changed, and if it has we refresh the path
    lastPathLength = positionCount;

    // 6 vertices per path element + 3 triangle for the arrow. the first pos is the unit pos, thus
    // there's not a -1
    vertexCount = positionCount * 6 + 3;

    // anything found?
    if ( vertexCount == 0 ) {
        self.visible = NO;
        return;
    }

    // allocate one color and vertex per needed vertex
    colors   = malloc( vertexCount * sizeof( ccColor4B ) );
    vertices = malloc( vertexCount * sizeof( ccVertex2F ) );

    CGPoint end;
    CGPoint vec;

    int index = 0;

    float pathLength = path.length + ccpDistance( self.unit.position, [[positions firstObject] CGPointValue] );
    float currentLength = 0, segmentLength;
    float widthStart, widthEnd;

    // temporary storage of the vertices
    ccVertex2F tmpVertices[ (positionCount + 1) * 2 ];
    GLubyte opacities[ positionCount + 1 ];

    CGPoint start = self.unit.position;

    // loop
    for ( unsigned int tmp = 0; tmp < positionCount; ++tmp ) {
        end = [positions[ tmp ] CGPointValue];

        // current length of this segment
        segmentLength = ccpDistance( start, end );

        // interpolate the opacity
        opacities[ tmp ] = (GLubyte)( START_OPACITY - (START_OPACITY - END_OPACITY) * (currentLength / pathLength) );

        // interpolate the width at the start and end of this segment
        widthStart = START_HALF_WIDTH - (START_HALF_WIDTH - END_HALF_WIDTH) * (currentLength / pathLength);
        currentLength += segmentLength;
        widthEnd = START_HALF_WIDTH - (START_HALF_WIDTH - END_HALF_WIDTH) * (currentLength / pathLength);

        // a N px long normalized vector perpendicular to start->end, used to give the line width
        vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( end, start ) ) ), widthStart );
        tmpVertices[index].x = start.x + vec.x;
        tmpVertices[index].y = start.y + vec.y;
        index++;

        // a new vector with the end width
        vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( end, start ) ) ), widthEnd );
        tmpVertices[index].x = start.x - vec.x;
        tmpVertices[index].y = start.y - vec.y;
        index++;

        start = end;
    }

    // last opacity
    opacities[ positionCount ] = (GLubyte)END_OPACITY;

    // start/end for the last segment
    start = [mission.path.positions[ positionCount - 2 ] CGPointValue];
    end   = mission.endPoint;

    // add the last point pairs
    vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( end, start ) ) ), widthEnd );

    // fill in the last two positions
    tmpVertices[index].x = end.x + vec.x;
    tmpVertices[index].y = end.y + vec.y;
    index++;

    tmpVertices[index].x = end.x - vec.x;
    tmpVertices[index].y = end.y - vec.y;
    index++;

    ccColor4B color = mission.color;

    // now create the triangles by copying from the temporary vertex array
    index = 0;
    for ( unsigned int tmp = 0; tmp < positionCount; ++tmp ) {
        // triangle 1
        vertices[ index + 0 ] = tmpVertices[ tmp * 2 + 0];
        vertices[ index + 1 ] = tmpVertices[ tmp * 2 + 1];
        vertices[ index + 2 ] = tmpVertices[ tmp * 2 + 2];

        // triangle 2
        vertices[ index + 3 ] = tmpVertices[ tmp * 2 + 2];
        vertices[ index + 4 ] = tmpVertices[ tmp * 2 + 3];
        vertices[ index + 5 ] = tmpVertices[ tmp * 2 + 1];

        colors[ index + 0 ] = ccc4( color.r, color.g, color.b, opacities[ tmp ] );
        colors[ index + 1 ] = ccc4( color.r, color.g, color.b, opacities[ tmp ] );
        colors[ index + 2 ] = ccc4( color.r, color.g, color.b, opacities[ tmp ] );

        colors[ index + 3 ] = ccc4( color.r, color.g, color.b, opacities[ tmp + 1 ] );
        colors[ index + 4 ] = ccc4( color.r, color.g, color.b, opacities[ tmp + 1 ] );
        colors[ index + 5 ] = ccc4( color.r, color.g, color.b, opacities[ tmp + 1 ] );

        index += 6;
    }

    // create the final arrow
    [self createArrowFrom:start to:end atIndex:index witColor:color];

    // arrow color
    colors[ index + 0 ] = ccc4( color.r, color.g, color.b, (GLubyte)END_OPACITY );
    colors[ index + 1 ] = ccc4( color.r, color.g, color.b, (GLubyte)END_OPACITY );
    colors[ index + 2 ] = ccc4( color.r, color.g, color.b, (GLubyte)END_OPACITY );

    self.visible = YES;

    // also update each frame
    [self scheduleUpdate];
}


- (void) createSimpleLine {
    // three triangles
    vertexCount = 9;

    // allocate one color and vertex per needed vertex
    colors   = malloc( vertexCount * sizeof( ccColor4B ) );
    vertices = malloc( vertexCount * sizeof( ccVertex2F ) );

    CGPoint start = self.unit.position;

    Mission * mission = self.unit.mission;
    ccColor4B color = mission.color;

    // all vertices have the same colors
    for ( int index = 0; index < vertexCount; ++index ) {
        colors[ index] = color;
    }

    CGPoint end = mission.endPoint;

    // a N px long normalized vector perpendicular to start->end
    CGPoint vec = ccpMult( ccpNormalize( ccpPerp( ccpSub( end, start ) ) ), END_HALF_WIDTH );

    //       v1                   v2
    // start ----------------------> end
    //       v4                   v3

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

    // create the arrow too
    [self createArrowFrom:start to:end atIndex:6 witColor:color];

    self.visible = YES;

    // also update each frame
    [self scheduleUpdate];
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
    if ( vertexCount == 0 || vertices == nil ) {
        return;
    }

    CC_NODE_DRAW_SETUP();

    ccGLBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );

    // enable position and color
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    CHECK_GL_ERROR_DEBUG();

    // Pass the verticies to draw to OpenGL
    glVertexAttribPointer( kCCVertexAttrib_Position, 2, GL_FLOAT,         GL_FALSE, 0, vertices );
    glVertexAttribPointer( kCCVertexAttrib_Color,    4, GL_UNSIGNED_BYTE, GL_TRUE,  0, colors );
    
    // draw the triangles
    glDrawArrays( GL_TRIANGLES, 0, vertexCount );
    CHECK_GL_ERROR_DEBUG();
    
    // disable all arrays
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_None );
    
    CC_INCREMENT_GL_DRAWS(1);
}


@end
