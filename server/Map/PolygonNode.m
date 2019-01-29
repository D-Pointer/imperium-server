
#import "PolygonNode.h"
#import "HitPosition.h"

@implementation PolygonNode

//- (id) initWithPolygon:(NSArray *)vertices {
//    self = [super init];
//    if (self) {
//        vertices_ = nil;
//        originalVertices_ = nil;
//
//        // sane default values for the bounding helpers
//        min_x = FLT_MAX;
//        min_y = FLT_MAX;
//        max_x = FLT_MIN;
//        max_y = FLT_MIN;
//
//        // the number of original vertices in total
//        original_count = vertices.count;
//        vertexCount = vertices.count;
//
//        // always save the original vertices too
//        originalVertices_ = malloc( vertices.count * sizeof( CGPoint ) );
//
//        for ( unsigned int index = 0; index < original_count; ++index ) {
//            // copy the position into our own array
//            CGPoint pos = [[vertices objectAtIndex:index] CGPointValue];
//            originalVertices_[ index ].x = pos.x;
//            originalVertices_[ index ].y = pos.y;
//
//            // handle bounding box
//            min_x = min( min_x, pos.x );
//            min_y = min( min_y, pos.y );
//            max_x = max( max_x, pos.x );
//            max_y = max( max_y, pos.y );
//        }
//
//        boundingBox_ = CGRectMake( min_x, min_y, max_x - min_x, max_y - min_y );
//    }
//
//    return self;
//}


- (id) initWithPolygon:(NSMutableArray *)vertices terrainType:(TerrainType)type smoothing:(BOOL)smoothing {
    self = [super init];
    if (self) {
        vertices_ = nil;
        _terrainType = type;

        // triangulate the polygon
         //NSMutableArray * indices = [[[Triangularizer alloc] init] triangularize:vertices withSmoothing:smoothing];
        
        //NSAssert( indices.count % 3 == 0, @"Invalid index count" );

        // the number of vertices in total
        vertexCount = vertices.count;
        
        //NSLog( @"PolygonNode.initWithPolygon: %u triangles", vertexCount / 3 );

        
        vertices_ = malloc( vertexCount * sizeof( CGPoint ) );

        // sane default values for the bounding helpers
        min_x = FLT_MAX;
        min_y = FLT_MAX;
        max_x = FLT_MIN;
        max_y = FLT_MIN;
        
        for ( unsigned int index = 0; index < vertexCount; ++index ) {
            // copy the position into our own array
            CGPoint pos = [vertices[index] CGPointValue];
            vertices_[ index ].x = pos.x;
            vertices_[ index ].y = pos.y;
            
            // handle bounding box
            min_x = MIN( min_x, pos.x );
            min_y = MIN( min_y, pos.y );
            max_x = MAX( max_x, pos.x );
            max_y = MAX( max_y, pos.y );
        }
                
        // set a content size to match the bound
        [self setContentSize:CGSizeMake( max_x - min_x, max_y - min_y )];

        boundingBox_ = CGRectMake( min_x, min_y, max_x - min_x, max_y - min_y );
    }
    
    return self;    
}


- (void) dealloc {
    if ( vertices_ ) {
        free( vertices_ );
        vertices_ = nil;
    }
}


- (BOOL) containsPoint:(CGPoint)point {
    // see: http://www.visibone.com/inpoly/

    // inside our bounding rect?
    if ( ! CGRectContainsPoint( self.boundingBox, point ) ) {
        // not inside
        return NO;
    }
    
  
    // alternative version that feels a bit slower
/*
    int crossed = 0;
    unsigned int count = self.originalVertices.count;
    
    // a vertical line
    CGPoint end = ccp( point.x, -10000 );

    // check all line segments
    for ( unsigned int index = 0; index < count - 1; ++index ) {
        if ( ccpSegmentIntersect( [[self.originalVertices objectAtIndex:index]     CGPointValue], 
                                  [[self.originalVertices objectAtIndex:index + 1] CGPointValue],
                                  point, end ) ) {
            // crosses
            crossed++;

            NSLog( @"PolygonNode.containsPoint: %f %f -> %f %f", vertices_[index].x, vertices_[index].y, vertices_[index + 1].x, vertices_[index + 1].y );
        }
    }
    
    NSLog( @"PolygonNode.containsPoint: crossed: %d", crossed );

    return (crossed % 2) == 1;
 */
    
   
    float xt = point.x;
    float yt = point.y;
    float xnew,ynew;
    float xold,yold;
    float x1,y1;
    float x2,y2;
    BOOL inside= NO;
    
    // can't be inside a point or line
    if ( vertexCount < 3) {
        return NO;
    }

    xold = vertices_[ vertexCount - 1 ].x;
    yold = vertices_[ vertexCount - 1 ].y;
    
    for ( unsigned int i = 0 ; i < vertexCount ; i++) {
        xnew = vertices_[ i ].x;
        ynew = vertices_[ i ].y;
        
        if (xnew > xold) {
            x1 = xold;
            x2 = xnew;
            y1 = yold;
            y2 = ynew;
        }
        else {
            x1 = xnew;
            x2 = xold;
            y1 = ynew;
            y2 = yold;
        }
        
        if ( (xnew < xt) == (xt <= xold)          // edge "open" at one end 
            && (yt - y1) * (x2-x1) < (y2 - y1) * (xt-x1)) {
            inside = !inside;
        }
        
        xold = xnew;
        yold = ynew;
    }
    
    return inside;
}


- (BOOL) intersectsLineFrom:(CGPoint)start to:(CGPoint)end atPos:(float *)pos {
    float s, t;
    CGPoint p1, p2;
    ccVertex2F v1, v2;
    BOOL found = NO;
    
    // reset the pos to something large
    *pos = 100000;
    
    for ( unsigned int index = 0; index < vertexCount; ++index ) {
        // line along the polygon
        v1 = vertices_[ index ]; 
        
        // handle wrapping
        if ( index + 1 == vertexCount ) {
            v2 = vertices_[ 0 ]; 
        }
        else {
            // not last yet
            v2 = vertices_[ index + 1 ];
        }
        
        p1.x = v1.x;
        p1.y = v1.y;
        p2.x = v2.x;
        p2.y = v2.y;
        
        // check intersection
        if ( ccpLineIntersect( start, end, p1, p2, &s, &t ) && s >= 0.0f && s <= 1.0f && t >= 0.0f && t <= 1.0f) {
            //NSLog( @"PolygonNode.intersectsLineFrom: hit at %f", s );
            found = YES;
            
            // closer hit?
            if ( s < *pos ) {
                *pos = s;
            }
        }
    }
    
    // no intersection
    return found;
}


- (void) addAllIntersectionsFrom:(CGPoint)start to:(CGPoint)end into:(NSMutableArray *)result {
    float s, t;
    CGPoint p1, p2;
    ccVertex2F v1, v2;

    for ( unsigned int index = 0; index < vertexCount; ++index ) {
        // line along the polygon
        v1 = vertices_[ index ];

        // handle wrapping
        if ( index + 1 == vertexCount ) {
            v2 = vertices_[ 0 ];
        }
        else {
            // not last yet
            v2 = vertices_[ index + 1 ];
        }

        p1.x = v1.x;
        p1.y = v1.y;
        p2.x = v2.x;
        p2.y = v2.y;

        // check intersection
        if ( ccpLineIntersect( start, end, p1, p2, &s, &t ) && s >= 0.0f && s <= 1.0f && t >= 0.0f && t <= 1.0f) {
            //NSLog( @"PolygonNode.intersectsLineFrom: hit at %f", s );
            [result addObject:[[HitPosition alloc] initWithPolygon:self atPosition:s]];
        }
    }
}


- (CGRect) boundingBox {
    return boundingBox_;
}

@end
