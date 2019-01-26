
#import "PolygonNode.h"
#import "Triangularizer.h"
#import "HitPosition.h"

@implementation PolygonNode

- (id) initWithPolygon:( NSMutableArray *)vertices {
    self = [super init];
    if (self) {
        vertices_ = nil;
        originalVertices_ = nil;

        // sane default values for the bounding helpers
        min_x = FLT_MAX;
        min_y = FLT_MAX;
        max_x = FLT_MIN;
        max_y = FLT_MIN;

        // the number of original vertices in total
        original_count = vertices.count;
        vertex_count = vertices.count;
        
        // always save the original vertices too
        originalVertices_ = malloc( vertices.count * sizeof( ccVertex2F ) );

        for ( unsigned int index = 0; index < original_count; ++index ) {
            // copy the position into our own array
            CGPoint pos = [[vertices objectAtIndex:index] CGPointValue];
            originalVertices_[ index ].x = pos.x;
            originalVertices_[ index ].y = pos.y;

            // handle bounding box
            min_x = min( min_x, pos.x );
            min_y = min( min_y, pos.y );
            max_x = max( max_x, pos.x );
            max_y = max( max_y, pos.y );
        }

        // set a content size to match the bound
        [self setContentSize:CGSizeMake( max_x - min_x, max_y - min_y )];

        boundingBox_ = CGRectMake( min_x, min_y, max_x - min_x, max_y - min_y );

        // setup the shaders to be used
        [self setupShaders];

        // use default z order
        self.mapLayerZ = kTerrainZ;
    }
    
    return self;    
}


- (id) initWithPolygon:( NSMutableArray *)vertices smoothing:(BOOL)smoothing {
    self = [super init];
    if (self) {
        vertices_ = nil;
        originalVertices_ = nil;

        // triangulate the polygon
         NSMutableArray * indices = [[[Triangularizer alloc] init] triangularize:vertices withSmoothing:smoothing];
        
        NSAssert( indices.count % 3 == 0, @"Invalid index count" );

        // the number of vertices in total
        vertex_count = indices.count;
        
        //CCLOG( @"PolygonNode.initWithPolygon: %u triangles", vertex_count / 3 );

        
        // the number of original vertices in total
        original_count = vertices.count;
        
        // always save the original vertices too
        originalVertices_ = malloc( original_count * sizeof( ccVertex2F ) );
        
        for ( unsigned int index = 0; index < original_count; ++index ) {
            // copy the position into our own array
            CGPoint pos = [[vertices objectAtIndex:index] CGPointValue];
            originalVertices_[ index ].x = pos.x;
            originalVertices_[ index ].y = pos.y;
        }

        // sane default values for the bounding helpers
        min_x = FLT_MAX;
        min_y = FLT_MAX;
        max_x = FLT_MIN;
        max_y = FLT_MIN;
        
        // set up vertices
        vertices_ = malloc( vertex_count * sizeof( ccVertex2F ) );
        for ( unsigned int index = 0; index < vertex_count; ++index ) {
            // the real vertex index takes from the indices array
            NSUInteger vertex_index = [[indices objectAtIndex:index] unsignedIntegerValue];
            
            // copy the position into our own array
            CGPoint pos = [[vertices objectAtIndex:vertex_index] CGPointValue];
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

        // setup the shaders to be used
        [self setupShaders];

        // use default z order
        self.mapLayerZ = kTerrainZ;
    }
    
    return self;    
}


//- (void) bindTextures {
//    // do nothing
//}


- (void) dealloc {
    if ( vertices_ ) {
        free( vertices_ );
        vertices_ = nil;
    }
    if ( originalVertices_ ) {
        free( originalVertices_ );
        originalVertices_ = nil;
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

            CCLOG( @"PolygonNode.containsPoint: %f %f -> %f %f", vertices_[index].x, vertices_[index].y, vertices_[index + 1].x, vertices_[index + 1].y );
        }
    }
    
    CCLOG( @"PolygonNode.containsPoint: crossed: %d", crossed );

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
    if ( vertex_count < 3) {
        return NO;
    }

    xold = originalVertices_[ original_count - 1 ].x;
    yold = originalVertices_[ original_count - 1 ].y;
    
    for ( unsigned int i = 0 ; i < original_count ; i++) {
        xnew = originalVertices_[ i ].x;
        ynew = originalVertices_[ i ].y;
        
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
    
    for ( unsigned int index = 0; index < original_count; ++index ) {
        // line along the polygon
        v1 = originalVertices_[ index ]; 
        
        // handle wrapping
        if ( index + 1 == original_count ) {
            v2 = originalVertices_[ 0 ]; 
        }
        else {
            // not last yet
            v2 = originalVertices_[ index + 1 ];
        }
        
        p1.x = v1.x;
        p1.y = v1.y;
        p2.x = v2.x;
        p2.y = v2.y;
        
        // check intersection
        if ( ccpLineIntersect( start, end, p1, p2, &s, &t ) && s >= 0.0f && s <= 1.0f && t >= 0.0f && t <= 1.0f) {
            //CCLOG( @"PolygonNode.intersectsLineFrom: hit at %f", s );
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

    for ( unsigned int index = 0; index < original_count; ++index ) {
        // line along the polygon
        v1 = originalVertices_[ index ];

        // handle wrapping
        if ( index + 1 == original_count ) {
            v2 = originalVertices_[ 0 ];
        }
        else {
            // not last yet
            v2 = originalVertices_[ index + 1 ];
        }

        p1.x = v1.x;
        p1.y = v1.y;
        p2.x = v2.x;
        p2.y = v2.y;

        // check intersection
        if ( ccpLineIntersect( start, end, p1, p2, &s, &t ) && s >= 0.0f && s <= 1.0f && t >= 0.0f && t <= 1.0f) {
            //CCLOG( @"PolygonNode.intersectsLineFrom: hit at %f", s );
            [result addObject:[[HitPosition alloc] initWithPolygon:self atPosition:s]];
        }
    }
}


- (CGRect) boundingBox {
    return boundingBox_;
}

@end
