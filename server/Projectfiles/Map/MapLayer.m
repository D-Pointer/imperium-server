
#import "MapLayer.h"
#import "PolygonNode.h"
#import "Definitions.h"
#import "Unit.h"
#import "Globals.h"
#import "Scenario.h"
#import "HitPosition.h"
#import "House.h"
#import "Smoke.h"

@interface MapLayer ()

@property (nonatomic, strong) CCSpriteBatchNode * bodiesNode;
@property (nonatomic, strong) CCSpriteBatchNode * housesNode;
@property (nonatomic, strong) NSMutableArray *    bodies;

@end

@implementation MapLayer

- (id) init {

	if ((self = [super init])) {
        self.polygons = [CCArray new];
        self.smoke1 = [CCArray new];
        self.smoke2 = [CCArray new];

        // set up our size
        self.mapWidth = [Globals sharedInstance].scenario.width;
        self.mapHeight = [Globals sharedInstance].scenario.height;
        [self setContentSize:CGSizeMake( self.mapWidth, self.mapHeight )];

        // unit selection marker
        self.selectionMarker = [[SelectionMarker alloc] init];
        [self addChild:self.selectionMarker z:kSelectionMarkerZ];

        // mission visualizer
        self.losVisualizer = [[LineOfSightVisualizer alloc] init];
        [self addChild:self.losVisualizer z:kLineOfSightVisualizerZ];

        // firing range visualizer
        self.rangeVisualizer = [[FiringRangeVisualizer alloc] init];
        [self addChild:self.rangeVisualizer z:kRangeVisualizerZ];

        // command range visualizer
        self.commandRangeVisualizer = [[CommandRangeVisualizer alloc] init];
        [self addChild:self.commandRangeVisualizer z:kCommandRangeVisualizerZ];

        // the batch node for all houses
        self.housesNode = [CCSpriteBatchNode batchNodeWithFile:@"Spritesheet.png"];
        self.housesNode.anchorPoint = ccp( 0, 0 );
        [self addChild:self.housesNode z:kHouseZ];

        // the batch node for all bodies
        self.bodiesNode = [CCSpriteBatchNode batchNodeWithFile:@"Spritesheet.png"];
        self.bodiesNode.anchorPoint = ccp( 0, 0 );
        [self addChild:self.bodiesNode z:kCorpseZ];

        // also store all bodies in a list for easy getting rid of them
        self.bodies = [NSMutableArray new];
	}

	return self;
}


- (void) dealloc {
    CCLOG( @"in" );
}


- (void) reset {
    // all polygons
    [self.polygons removeAllObjects];
    self.polygons = nil;

    // los visualizer
    [self.losVisualizer removeFromParentAndCleanup:YES];
    self.losVisualizer = nil;
    
    [self.rangeVisualizer removeFromParentAndCleanup:YES];
    self.rangeVisualizer = nil;

    [self.commandRangeVisualizer removeFromParentAndCleanup:YES];
    self.commandRangeVisualizer = nil;

    // get rid of all other children
    [self removeAllChildrenWithCleanup:YES];

    [self removeFromParentAndCleanup:YES];
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

    MapLayer * map = [Globals sharedInstance].mapLayer;

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

    //CCLOG( @"found %d collisions", collisions.count );

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
    if ( self.smoke1.count > 0 || self.smoke2.count > 0 ) {
        // a rect that contains start and losEnd with a 20 m margin in all directions. We check to see if any of the
        // smoke is inside this rect before doing anything more advanced
        CGRect rect = CGRectMake( MIN( start.x, losEnd.x) - 20,
                                 MIN( start.y, losEnd.y) - 20,
                                 fabs( start.x - losEnd.x) + 40,
                                 fabs(start.y - losEnd.y ) + 40 );

        // max radius that the smoke blocks LOS
        const float maxSmokeRadiusSq = 15.0f * 15.0f;

        CGPoint hit;
        for ( Smoke * smoke in self.smoke1 ) {
            //for ( Smoke * smoke in self.smoke ) {
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

        for ( Smoke * smoke in self.smoke2 ) {
            //for ( Smoke * smoke in self.smoke ) {
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

    if ( visualize ) {
        if ( canSee ) {
            [self.losVisualizer showFrom:start to:end];
        }
        else {
            // was it too far?
            if ( tooFar ) {
                // the end was further away than we can see
                [self.losVisualizer showFrom:start toMiddle:losEnd withEnd:realEnd];
            }
            else {
                // the destination was within how far we can see
                [self.losVisualizer showFrom:start toMiddle:losEnd withEnd:end];
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

- (void) addBodies:(int)bodies around:(Unit *)unit {
    NSString * bodyName = unit.owner == kPlayer1 ? @"Body1.png" : @"Body2.png";

    float x = unit.position.x;
    float y = unit.position.y;

    // find out the largest dimension of the unit sprite
    float radius = MAX( unit.boundingBox.size.width, unit.boundingBox.size.height ) / 2.0f;

    // add in some bodies
    for ( int index = 0; index < bodies; ++index ) {
        CCSprite * body = [CCSprite spriteWithSpriteFrameName:bodyName];

        // random position around the given position
        body.position = ccp( x - radius + CCRANDOM_0_1() * radius * 2,
                             y - radius + CCRANDOM_0_1() * radius * 2 );

        // random rotation
        body.rotation = CCRANDOM_0_1() * 360;

        [self.bodiesNode addChild:body];
        [self.bodies addObject:body];
    }

    int maxBodies = sParameters[kParamMaxBodiesI].intValue;

    // too many bodies?
    while ( self.bodies.count > maxBodies ) {
        CCSprite * body = self.bodies[0];
        [self.bodies removeObjectAtIndex:0];

        // and get rid of the node too
        [self.bodiesNode removeChild:body cleanup:YES];
    }

    CCLOG( @"added %d bodies, now: %lu", bodies, (unsigned long)self.bodies.count );
}


- (void) addHouse:(House *)house withShadow:(CCSprite *)shadow {
    [self.housesNode addChild:house z:kHouseZ];
    [self.housesNode addChild:shadow z:kHouseShadowZ];
}


- (void) addSmoke:(CGPoint)position forPlayer:(PlayerId)player {
    Smoke * smoke = [Smoke spriteWithSpriteFrameName:@"Smoke.png"];
    smoke.creator = player;
    smoke.position = position;
    smoke.rotation = arc4random_uniform( 360 );
    [self addChild:smoke z:kSmokeZ];

    if ( player == kPlayer1 ) {
        [self.smoke1 addObject:smoke];
    }
    else {
        [self.smoke2 addObject:smoke];
    }

    // add first in the smoke chain
//    smoke.next = self.smoke;
//    smoke.prev = nil;
//    self.smoke = smoke;
    //[self.smoke addObject:smoke];
}


- (void) addOffMapArtilleryExplosion:(CGPoint)position {
    CCLOG( @"adding explosion at %.0f %.0f", position.x, position.y );
}

@end
