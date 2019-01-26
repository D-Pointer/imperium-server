
#import "Triangularizer.h"

@implementation Triangularizer

typedef enum PolygonWinding {
    ClockWise,
    CounterClockWise
} PolygonWinding;


//- (CGFloat) area:(CGPoint)a b:(CGPoint)b c:(CGPoint)c {
//    // Area= abs(x1*y2+x2*y3+x3*y1-x1*y3-x3*y2-x2*y1)/2 
//    return abs( a.x * b.y + b.x * c.y + c.x * a.y - a.x * c.y - c.x * b.y - b.x * a.y ) / 2.0f; 
//}


- (BOOL) pointInTriangle:(CGPoint)a b:(CGPoint)b c:(CGPoint)c point:(CGPoint)point {
    // see: http://mathforum.org/library/drmath/view/54505.html
    // z_ab = (x_d-x_a)*(y_b-y_a)-(y_d-y_a)*(x_b-x_a)

    float z_ab = (point.x - a.x) * (b.y - a.y) - (point.y - a.y) * (b.x - a.x);
    float z_bc = (point.x - b.x) * (c.y - b.y) - (point.y - b.y) * (c.x - b.x);
    float z_ca = (point.x - c.x) * (a.y - c.y) - (point.y - c.y) * (a.x - c.x);

    if ( ( z_ab <= 0 && z_bc <= 0 && z_ca <= 0 ) || ( z_ab >= 0 && z_bc >= 0 && z_ca >= 0 ) ) {
        // inside
        return YES;
    }
    
    return NO;
    
    
    // see: http://compsci.ca/v3/viewtopic.php?t=6034
    // Area PAB + Area PBC + Area PAC == Area ABC 
/*
    // areas of triangles with their center at the point
    CGFloat area_pab = [self area:point b:a c:b];
    CGFloat area_pbc = [self area:point b:b c:c];
    CGFloat area_pac = [self area:point b:a c:c];

    // whole triangle area
    CGFloat area_abc = [self area:a b:b c:c];
    
    // if the area of the smaller parts is larger than the full area, then the point is outside
    if ( area_abc - (area_pab + area_pbc + area_pac) < 0.0f ) {
        // outside
        return NO;
    }
    
    // inside
    return YES;
 */
}


- (BOOL) checkTriangleWithIndex0:(NSUInteger)index0 index1:(NSUInteger)index1 index2:(NSUInteger)index2 {
    // p1 is the central point of our triangle
    CGPoint p0 = [[vertices objectAtIndex:index0] CGPointValue];
    CGPoint p1 = [[vertices objectAtIndex:index1] CGPointValue];
    CGPoint p2 = [[vertices objectAtIndex:index2] CGPointValue];
    
    // first check the angle of the triangle
    float angle = ccpAngleSigned( ccpSub( p0, p1 ), ccpSub( p2, p1 ) );
    //CCLOG( @"Triangularizer:checkTriangle: angle: %f", angle );
    if ( angle < 0 ) {
        // the angle is larger then 180 degrees, so this triangle can not be cut off, it's no ear
        //CCLOG( @"Triangularizer:checkTriangle: too large angle: %f %f", angle, angle2 );
        //CCLOG( @"Triangularizer:checkTriangle: %.f %.f   %.f %.f   %.f %.f", p0.x, p0.y, p1.x, p1.y, p2.x, p2.y );
        return NO;
    }
    
    // now check all other points to see if they are inside the triangle 
    for ( unsigned int check_index = 0; check_index < indices.count; ++check_index ) {
        // the real vertex index
        NSUInteger vertex_index = [[indices objectAtIndex:check_index] unsignedIntegerValue];

        if ( vertex_index == index0 || vertex_index == index1 || vertex_index == index2 ) {
            // skip these, they are a part of the triangle
            continue;
        }
        
        if ( [self pointInTriangle:p0 b:p1 c:p2 point:[[vertices objectAtIndex:vertex_index] CGPointValue]] ) {
            // point is inside
            //CCLOG( @"Triangularizer:checkTriangle: point inside: %u", vertex_index );
            return NO;
        }
    }
    
    // looks good
    return TRUE;
}


- (void) smoothPolygon:( NSMutableArray *)originalVertices {
    CGPoint p0, p2;
    
    // how far out from the center point are the smoothed points
    float distance = 0.10f;
    
    float min_angle = M_PI * 0.85;
    
    unsigned int index = 0;
    
    // loop. note, do not cache the count as the vertices and the count changes
    while ( index < originalVertices.count ) {
        // p1 is the central point of our triangle
        CGPoint p1 = [[originalVertices objectAtIndex:index + 0] CGPointValue];

        if ( index == 0 ) {
            // still at the first, so the first leg is using the last vertex
            p0 = [[originalVertices lastObject] CGPointValue];
        }
        else {
            // use the previous vertex
            p0 = [[originalVertices objectAtIndex:index - 1] CGPointValue];            
        }

        if ( index < originalVertices.count - 1 ) {
            p2 = [[originalVertices objectAtIndex:index + 1] CGPointValue];
        }
        else {
            // p1 is at the last vertex, so use the first
            p2 = [[originalVertices objectAtIndex:0] CGPointValue];            
        }
        
        // check the angle of the triangle
        float angle = ccpAngleSigned( ccpSub( p0, p1 ), ccpSub( p2, p1 ) );

        //CCLOG( @"Triangularizer.smoothPolygon: smooth index: %d, angle: %f, size: %u", index, angle, originalVertices.count );

        // small/sharp enough?
        if ( angle < -min_angle || angle > min_angle ) {
            // no need to smooth
            ++index;
            continue;
        }

        // the smoothed angle
        float smooth_angle = (M_PI - angle) / 5.0f;
        
        if ( angle < 0 ) {
            smooth_angle = (-M_PI - angle) / 5.0f;
        }

        //CCLOG( @"Triangularizer.smoothPolygon: angle: %f -> %f", angle, smooth_angle );

        // two points rotated around p1
        CGPoint extra_point1 = ccpRotateByAngle( p0, p1, -smooth_angle );
        CGPoint extra_point2 = ccpRotateByAngle( p2, p1,  smooth_angle );

        // the point is too far away (as far as p0), so bring it closer to p1
        extra_point1 = ccpAdd( ccpMult( ccpSub( extra_point1, p1 ), distance ), p1 );
        extra_point2 = ccpAdd( ccpMult( ccpSub( extra_point2, p1 ), distance ), p1 );
        
        [originalVertices insertObject:[NSValue valueWithCGPoint:extra_point1] atIndex:index];
        
        // the second may need to go after the last point
        if ( index == originalVertices.count - 2 ) {
            // append last
            [originalVertices addObject:[NSValue valueWithCGPoint:extra_point2]];
        }
        else {
            [originalVertices insertObject:[NSValue valueWithCGPoint:extra_point2] atIndex:index + 2];            
        }
        
        //index += 2; //3;
        
//        CCLOG( @"Triangularizer.smoothPolygon: %f %f -> %f %f  == %f %f", p1.x, p1.y, p0.x, p0.y, extra_point1.x, extra_point1.y );
//        CCLOG( @"Triangularizer.smoothPolygon: %f %f -> %f %f  == %f %f", p1.x, p1.y, p2.x, p2.y, extra_point2.x, extra_point2.y );

    }
    
//    for ( unsigned int index = 0; index < vertices.count; ++index ) {
//        CGPoint p = [[vertices objectAtIndex:index] CGPointValue];
//        CCLOG( @"Triangularizer.smoothPolygon: %f %f", p.x, p.y );
//    }
}


- (PolygonWinding) getWinding:( NSMutableArray *)originalVertices {
    // see: http://chipmunk-physics.net/forum/viewtopic.php?f=1&t=109
    CGFloat accum = 0;

    for ( unsigned int index1 = 0; index1 < originalVertices.count; ++index1 ) {
        unsigned int index2 = ( index1 + 1 ) % originalVertices.count;
    
        CGPoint p1 = [[originalVertices objectAtIndex:index1] CGPointValue];
        CGPoint p2 = [[originalVertices objectAtIndex:index2] CGPointValue];

        accum += p2.x * p1.y - p1.x * p2.y;
    }

    if ( accum >= 0 ) {
        return ClockWise;
    }
    
    return CounterClockWise;
}


- ( NSMutableArray *) triangularize:( NSMutableArray *)originalVertices withSmoothing:(BOOL)smooth {
     NSMutableArray * result = [ NSMutableArray array];
    
    // precautions, there needs to be enough vertices to do this stuff
    if ( originalVertices == nil || originalVertices.count < 3 ) {
        CCLOG( @"Triangularizer.triangularize: invalid vertices" );
        return result;
    }
    
    // find out the winding of the polygon
    PolygonWinding winding = [self getWinding:originalVertices];

    // for a counter clockwise winding we simply reverse the polygon
    if ( winding == CounterClockWise ) {
        [originalVertices reverseObjects];
    }
    
    // optionally smooth the polygon
    if ( smooth ) {
        [self smoothPolygon:originalVertices];
    }

    // save locally
    vertices = originalVertices;
    
    NSUInteger vertex_count = vertices.count;

    //CCLOG( @"Triangularizer.triangularize: handling %u vertices", vertex_count );

    // fill an array with the indices, 0..n. these point to the vertices in 'vertices_copy'
    indices = [ NSMutableArray arrayWithCapacity:vertex_count];
    for ( unsigned int index = 0; index < vertex_count; ++index ) {
        [indices insertObject:[NSNumber numberWithUnsignedInt:index] atIndex:index];
        //CGPoint p1 = [[vertices objectAtIndex:index] CGPointValue];
        //CCLOG( @"%u -> %f %f", index, p1.x, p1.y );
    }

    //CCLOG( @"Triangularizer.triangularize: winding: %@", winding == ClockWise ? @"clockwise" : @"counterclockwise" );    
    
    // now loop while we still have vertices
    while ( indices.count >= 3 ) {
        NSUInteger start_count = indices.count;
        //CCLOG( @"Triangularizer.triangularize: indices left: %u", indices.count );

        unsigned int index = 0;
        
        // loop forward until we find an ear of the polygon that can be snipped off. three vertices are checked. when we've moved 
        // through all indices the above for-loop will rerun this loop
        while ( index < indices.count ) {
            // the indices that will be used for this triangle
            // BUG: can this index 2 steps too far?
            NSUInteger vertex_index0 = [[indices objectAtIndex:(index + 0) % indices.count] unsignedIntegerValue];
            NSUInteger vertex_index1 = [[indices objectAtIndex:(index + 1) % indices.count] unsignedIntegerValue];
            NSUInteger vertex_index2 = [[indices objectAtIndex:(index + 2) % indices.count] unsignedIntegerValue];
            
            // check if the three vertices form an acceptable triangle
            if ( [self checkTriangleWithIndex0:vertex_index0 
                                        index1:vertex_index1 
                                        index2:vertex_index2] ) {
                // this is an ok triangle! that means we can remove the point after index (the central point) from the
                // vertex set and form a triangle
                
                //CGPoint p1 = [[vertices objectAtIndex:vertex_index1] CGPointValue];
                //CCLOG( @"Triangularizer.triangularize: triangle %u %u %u, %f %f", vertex_index0, vertex_index1, vertex_index2, p1.x, p1.y );

                // snip off the center of the triangle
                [indices removeObjectAtIndex:(index + 1) % indices.count];    
                
                // save in the index result array. always save with clockwise winding
                [result addObject:[NSNumber numberWithUnsignedInt:(unsigned int)vertex_index0]];
                [result addObject:[NSNumber numberWithUnsignedInt:(unsigned int)vertex_index1]];
                [result addObject:[NSNumber numberWithUnsignedInt:(unsigned int)vertex_index2]];
            }
            else {
                index++;
            }
        }

        // precautions
        NSAssert( indices.count < start_count, @"Trianglularization failed, no triangles found during loop" );
    }
    
    vertices = nil;
    indices = nil;
    
    return result;
}

@end
