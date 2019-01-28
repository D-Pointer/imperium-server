
#import "Map.h"
#import "PolygonNode.h"
#import "Definitions.h"
#import "Unit.h"
#import "Globals.h"
#import "Scenario.h"
#import "HitPosition.h"
#import "House.h"
#import "Smoke.h"


@implementation Map

- (id) init {

	if ((self = [super init])) {
        self.polygons = [ NSMutableArray new];

        // set up our size
        self.mapWidth = [Globals sharedInstance].scenario.width;
        self.mapHeight = [Globals sharedInstance].scenario.height;

	}

	return self;
}


- (void) dealloc {
    NSLog( @"in" );
}


- (void) reset {
    // all polygons
    [self.polygons removeAllObjects];
    self.polygons = nil;
}


- (BOOL) isInsideMap:(CGPoint)pos {
    return pos.x >= 0 && pos.x <= self.mapWidth && pos.y >= 0 && pos.y <= self.mapHeight;
}


- (TerrainType) getTerrainAt:(CGPoint)pos {
    // this loops all polygons from the last to the first, as the higher up polygons were added last. this makes sure that
    // a road through woods is checked before the woods it goes through
    int count = (int)self.polygons.count - 1;
    for ( int index = count; index >= 0; index-- ) {
        PolygonNode * polygon = [self.polygons objectAtIndex:index];
        if ( [polygon containsPoint:pos] ) {
            // found it
            return polygon.terrainType;
        }
    }

    // no polygon contains the point
    return kGrass;
}


- (TerrainType) getTerrainForUnit:(Unit *)unit {
    // no terrains yet
    int terrains[ kNoTerrain ] = { 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    MapLayer * map = [Globals sharedInstance].map;

    // directly under the unit
    terrains[ [map getTerrainAt:unit.position] ] = 2;

    // distance from the center point
    const int distance = 5;

    for ( int angle = 0; angle <= 270; angle += 90 ) {
        CGPoint direction = ccpMult( ccpForAngle( CC_DEGREES_TO_RADIANS( unit.rotation + angle ) ), distance );
        CGPoint pos = ccpAdd( unit.position, direction );

        // get the terrain under that position and add to the frequency table
        TerrainType terrain = [map getTerrainAt:pos];

        // column units always assume they are on the road if even one sample is on a road
        if ( terrain == kRoad && unit.mode == kColumn ) {
            return kRoad;
        }

        // add to the frequency table
        terrains[ terrain ]++;
    }

    int max = terrains[0];
    int max_index = 0;

    // find the terrain type that has most hits from the frequency table
    for ( int index = 0; index < kNoTerrain; ++index ) {
        if ( terrains[index] > max ) {
            max = terrains[index];
            max_index = index;
        }
    }

    return (TerrainType)max_index;
}


- (PolygonNode *) getPolygonAt:(CGPoint)pos {
    for ( PolygonNode * polygon in self.polygons ) {
        if ( [polygon containsPoint:pos] ) {
            // found it
            return polygon;
        }
    }

    // no polygon contains the point, so it's base grass
    return self.baseGrass;
}


- (Unit *) getUnitAt:(CGPoint)pos {
    Unit * found = nil;
    float minDistance = 10000;

    for ( Unit * unit in [Globals sharedInstance].units ) {
        float distance = ccpDistance( pos, unit.position );

        // new closest hit?
        if ( distance < unit.selectionRadius && distance < minDistance ) {
            // new best unit
            found = unit;
            minDistance = distance;
        }
    }

    // return whatever we found
    return found;
}


- (Objective *) getObjectiveAt:(CGPoint)pos {
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        if ( [objective isHit:pos] ) {
            return objective;
        }
    }

    // found no objective at that pos
    return nil;
}


- (BOOL) canSeeFrom:(CGPoint)start to:(CGPoint)end visualize:(BOOL)visualize withMaxRange:(float)maxSightRange {
    // total distance we're trying to look
    float distance = ccpDistance( start, end );

    // by default the unit can see until the end point
    BOOL canSee = YES;
    BOOL tooFar = NO;
    CGPoint realEnd = end;

    // too far total distance?
    if ( distance > maxSightRange ) {
        // too far away, we can not see all the way
        tooFar = YES;
        realEnd = end;

        // modify the position where the LOS checks will end
        end = ccpLerp( start, end, maxSightRange / distance );
        canSee = NO;
    }

    CGPoint losEnd = end;

    // a rect that is bounded by our given positions. we do a coarse check to see if each polygon bb intersects
    CGRect full = CGRectMake( MIN( start.x, end.x ), MIN( start.y, end.y ), fabs( start.x - end.x ), fabs( start.y - end.y ));

    NSMutableArray * collisions = [NSMutableArray new];

    // check all polygons
    for ( PolygonNode * polygon in self.polygons ) {
        // only some terrains block LOS
        if ( polygon.terrainType == kWoods || polygon.terrainType == kScatteredTrees ) {
            // can block LOS, first check the bounding boxes
            if ( CGRectIntersectsRect( full, polygon.boundingBox ) ) {
                [polygon addAllIntersectionsFrom:start to:end into:collisions];
            }
        }
    }

    //NSLog( @"found %d collisions", collisions.count );

    // convert all the positions to meters, now they are 0..1
    for ( HitPosition * hit in collisions ) {
        hit.position = hit.position *= distance;
    }

    // total amount of distance inside woods
    float totalDistanceInWoods = 0.0f;

    // do we start with a unit in woods?
    PolygonNode * startPolygon = [self getPolygonAt:start];
    PolygonNode * lastPolygon = startPolygon;

    // do we start in woods?
    BOOL inWoods = (startPolygon.terrainType == kWoods) || (startPolygon.terrainType == kScatteredTrees);

    // position where we entered woods
    float inWoodsStart = 0.0f;
    float maxVisibilityIntoWoods = sParameters[kParamMaxVisibilityIntoWoodsF].floatValue;

    if ( collisions.count > 0 ) {
        // sort them based on distance from the start point
        [collisions sortUsingFunction:compareHitPositions context:nil];

        for ( HitPosition * hit in collisions ) {
            lastPolygon = hit.polygon;

            // hit terrain was woods. are we now in woods or exiting it?
            if ( inWoods ) {
                // we're exiting woods
                inWoods = NO;
                float distanceInWoods = hit.position - inWoodsStart;
                
                // if the terrain is scattered trees then halve the distance, we see further into scattered trees
                if ( hit.polygon.terrainType == kScatteredTrees ) {
                    distanceInWoods *= 0.5f;
                }

                // have we now seen too far into woods?
                if ( totalDistanceInWoods + distanceInWoods > maxVisibilityIntoWoods ) {
                    // indeed we have, so stop the los as far in as the unit could see
                    float canSeeDistance = maxVisibilityIntoWoods - totalDistanceInWoods;

                    // we can see double into scattered trees
                    if ( hit.polygon.terrainType == kScatteredTrees ) {
                        canSeeDistance *= 2;
                    }

                    // how far did we really see
                    float endPosition = inWoodsStart + canSeeDistance;

                    // interpolate along the LOS line to get the end point for as far as we could see
                    losEnd = ccpLerp( start, end, endPosition / distance );
                    canSee = NO;
                    break;
                }

                totalDistanceInWoods += distanceInWoods;
            }
            else {
                // entering woods
                inWoods = YES;
                inWoodsStart = hit.position;
            }
        }
    }

    // did we end inside woods?
    if ( inWoods ) {
        float distanceInWoods = distance - inWoodsStart;

        // we can see double into scattered trees
        if ( lastPolygon.terrainType == kScatteredTrees ) {
            distanceInWoods *= 0.5f;
        }

        // have we now seen too far into woods?
        if ( totalDistanceInWoods + distanceInWoods > maxVisibilityIntoWoods ) {
            // indeed we have, so stop the los as far in as the unit could see
            float canSeeDistance = maxVisibilityIntoWoods - totalDistanceInWoods;

            // we can see double into scattered trees
            if ( lastPolygon.terrainType == kScatteredTrees ) {
                canSeeDistance *= 2;
            }

            float endPosition = inWoodsStart + canSeeDistance;
            losEnd = ccpLerp( start, end, endPosition / distance );
            canSee = NO;
        }
    }

    // check all smoke
    NSArray * smoke = [Globals sharedInstance].smoke;
    if ( self.smoke.count > 0 ) {
        // a rect that contains start and losEnd with a 20 m margin in all directions. We check to see if any of the
        // smoke is inside this rect before doing anything more advanced
        CGRect rect = CGRectMake( MIN( start.x, losEnd.x) - 20,
                                 MIN( start.y, losEnd.y) - 20,
                                 fabs( start.x - losEnd.x) + 40,
                                 fabs(start.y - losEnd.y ) + 40 );

        // max radius that the smoke blocks LOS
        const float maxSmokeRadiusSq = 15.0f * 15.0f;

        CGPoint hit;
        for ( Smoke * smoke in self.smoke ) {
            if ( CGRectContainsPoint( rect, smoke.position ) ) {
                // this smoke is inside, it can potentially block los
                if ( visualize ) {
                    // get the squared distance from the smoke center to the line segment
                    float sqDistance = [self squaredDistanceToPoint:smoke.position fromLineSegmentBetween:start and:losEnd hit:&hit];

                    // is the smoke center close enough? The smoke opacity makes the radius smaller
                    if ( sqDistance < maxSmokeRadiusSq * ((float)smoke.opacity / 255.0f ) ) {
                        // can definitely not see, is the new breaking point closer?
                        canSee = NO;
                        if ( ccpDistanceSQ( start, hit ) < ccpDistanceSQ( start, losEnd ) ) {
                            // yes, close LOS break
                            losEnd = hit;
                        }
                    }
                }
            }
        }
    }

    return canSee;
}

- (float)squaredDistanceToPoint:(CGPoint)p fromLineSegmentBetween:(CGPoint)l1 and:(CGPoint)l2 hit:(CGPoint *)hit {
    float A = p.x - l1.x;
    float B = p.y - l1.y;
    float C = l2.x - l1.x;
    float D = l2.y - l1.y;

    float dot = A * C + B * D;
    float len_sq = C * C + D * D;
    float param = dot / len_sq;

    float xx, yy;

    if (param < 0 || (l1.x == l2.x && l1.y == l2.y)) {
        xx = l1.x;
        yy = l1.y;
    }
    else if (param > 1) {
        xx = l2.x;
        yy = l2.y;
    }
    else {
        xx = l1.x + param * C;
        yy = l1.y + param * D;
    }

    float dx = p.x - xx;
    float dy = p.y - yy;

    hit->x = xx;
    hit->y = yy;

    return dx * dx + dy * dy;
    //return sqrtf( dx * dx + dy * dy );
}

@end
