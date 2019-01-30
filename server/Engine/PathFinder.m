
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "PathFinder.h"
#import "Globals.h"
#import "PathNode.h"
#import "Map.h"
#import "TerrainModifiers.h"
#import "Scenario.h"

@interface PathFinder () {
    // an array of closed positions
    Byte * closed;

    // navigation data
    Byte * terrains;

    // map size in tiles
    int mapWidth;
    int mapHeight;

    // number of positions
    int positions;
}

@end

@implementation PathFinder

- (id) initWithData:(Byte *)data {

    self = [super init];
    if (self) {
        // save the data, we take ownership of it
        terrains = data;

        // map size in tiles
        mapWidth  = [Globals sharedInstance].map.mapWidth / sParameters[kParamPathMapTileSizeI].intValue;
        mapHeight = [Globals sharedInstance].map.mapHeight / sParameters[kParamPathMapTileSizeI].intValue;

        // number of positions
        positions = mapWidth * mapHeight;

        // an array with flags set for closed hexes
        closed = (Byte *)malloc( positions * sizeof(Byte) );

        NSLog( @"created a %d x %d navigation map, total bytes: %d", mapWidth, mapHeight, positions );

        // get the nav file
//        NSString * navFilename = [[Globals sharedInstance].scenario.filename stringByReplacingOccurrencesOfString:@".map" withString:@".nav"];
//
//        NSLog( @"loading navigation data from: %@", navFilename );
//
//        // an array with terrain types
//        NSError * error = nil;
//        NSData * terrainData = [NSData dataWithContentsOfFile:navFilename options:NSDataReadingUncached error:&error];
//        if ( error ) {
//            NSLog( @"failed to read navigation data: %@", error.localizedDescription );
//            return nil;
//        }
//
//        // precautions
//        NSAssert( terrainData.length == positions, @"invalid navigation data. Expected %d, got %lu", positions, terrainData.length );
//
//        // copy the bytes
//        terrains = (Byte *)malloc( positions * sizeof(Byte) );
//        [terrainData getBytes:terrains length:positions];
    }

    return self;
}


- (void) dealloc {
    if ( terrains != nil ) {
        free( terrains );
        terrains = nil;
    }
    if ( closed != nil ) {
        free( closed );
        closed = nil;
    }
}


- (Path *) findPathFrom:(CGPoint)source to:(CGPoint)destination forUnit:(Unit *)unit {
    int tileSize = sParameters[kParamPathMapTileSizeI].intValue;

    // source and destination positions
    Position sourcePos      = { (int)source.x / tileSize, (int)source.y / tileSize };
    Position destinationPos = { (int)destination.x / tileSize, (int)destination.y / tileSize };

    // set up deltas for all positions that are around some
    Position around[8] = {
        { -1,  0 }, // left
        {  1,  0 }, // right
        {  0,  1 }, // up
        {  0, -1 }, // down
        { -1,  1 }, // up left
        {  1,  1 }, // up right
        { -1, -1 }, // down left
        {  1, -1 } // down right
    };

    NSMutableArray * open = [ NSMutableArray arrayWithCapacity:100];

    // no positions are closed when we start
    memset( closed, 0, positions );

    // start with the start node in the open set
    [open addObject:createPathNode( 0, [self getEstimateFrom:&sourcePos to:&destinationPos forUnit:unit], sourcePos, nil )];

    // loop while there are still open nodes
    while ( [open count] > 0 ) {
        // get the node with the lowest cost
        PathNode * node = [self findPathNode:open]; //[open nextObject];

        // is this the destination?
        if ( node->pos.x == destinationPos.x && node->pos.y == destinationPos.y ) {
            NSLog( @"destination found, total cost: %1f", node->total );
             NSMutableArray * result = [ NSMutableArray new];

            // assemble the final path by traversing back from the destination along the "before" links
            PathNode * loop = node;
            while ( loop != nil ) {
                //NSLog( @"%d %d", loop->pos.x, loop->pos.y );

                // convert the path map pos to a full coordinate
                CGPoint tmpPos = { loop->pos.x * tileSize, loop->pos.y * tileSize };
                //CGPoint tmpPos = { loop->pos.x * sPathMapTileSize + sPathMapTileSize / 2, loop->pos.y * sPathMapTileSize + sPathMapTileSize / 2 };

                // save only if it's not the same as the starting position. this avoids adding a first path position that is the same as the unit's
                // current position
                if ( (int)unit.position.x != (int)tmpPos.x || (int)unit.position.y != (int)tmpPos.y ) {
                    [result addObject:[NSValue valueWithCGPoint:tmpPos]];
                }

                loop = loop->before;
            }

            //destroyPathNode( node );
            return [self createPath:result];
        }

        // it's now closed
        closed[ node->pos.y * mapWidth + node->pos.x ] = 1;

        // check all 8 possible locations around the current
        for ( int aroundIndex = 0; aroundIndex < 8; ++aroundIndex ) {
            Position position = { node->pos.x + around[ aroundIndex ].x, node->pos.y + around[ aroundIndex ].y };

            // is the position inside the map?
            if ( position.x < 0 || position.x >= mapWidth || position.y < 0 || position.y >= mapHeight ) {
                continue;
            }

            // is this terrain already closed?
            if ( closed[ position.y * mapWidth + position.x ] == 1 ) {
                continue;
            }

            // get the terrain modifier for the unit at the given pos. this works as a
            // cost to enter the position
            float terrainCost = [self getCostToEnterTerrainAt:&position forUnit:unit];

            // can it even move there?
            if ( terrainCost < 0.5f ) {
                continue;
            }

            // modify the cost if we're moving diagonally
            terrainCost *= ( around[ aroundIndex ].x != 0 && around[ aroundIndex ].y != 0 ) ? 1.41f : 1.0f;

            BOOL found = NO;

            // is it on the open list? check all
            for ( unsigned int index = 0; index < open.count; ++index ) {
                PathNode * tmp = [open objectAtIndex:index];

                // is this the current node?
                if ( tmp->pos.x == position.x && tmp->pos.y == position.y ) {
                    // found it already in the open set
                    found = YES;

                    // did we arrive through a shorter route?
                    if ( tmp->costSoFar > node->costSoFar + terrainCost ) {
                        // yes, we sure did, so take this node and update it
                        [open removeObject:tmp];

                        tmp->costSoFar = node->costSoFar + terrainCost;
                        tmp->total = tmp->estimate + tmp->costSoFar;

                        // update the way we got here. get rid of the old node
                        //tmp->before->usage--;
                        //destroyPathNode( tmp->before );
                        tmp->before = node; 
                        //tmp->before->usage++;
                        
                        // and insert back into the map
                        [open addObject:tmp];
                        break;
                    }
                }
            }

            if ( ! found ) {
                // not on the open list yet. add a new node to the open list
                [open addObject:createPathNode( node->costSoFar + terrainCost,
                                               [self getEstimateFrom:&position to:&destinationPos forUnit:unit],
                                               position,
                                               node ) ];
            }
        }
        
        //destroyPathNode( node );
    }

    // we got this far, no path
    //free( closed );
    //closed = nil;
    return nil;
}


- (TerrainType) getTerrainAtX:(int)x y:(int)y {
    // terrain at the destination
    return terrains[ y * mapWidth + x ];
}


- (PathNode *) findPathNode:( NSMutableArray *)open {
    PathNode * best = nil;
    int pos = 0, bestPos = -1;

    for ( PathNode * node in open ) {
        if ( best == nil || node->total < best->total ) {
            // new best
            best = node;
            bestPos = pos;
        }

        pos++;
    }

    NSAssert( best != nil && bestPos >= 0, @"no path node found" );
    [open removeObjectAtIndex:bestPos];

    return best;
}


- (float) getEstimateFrom:(Position *)sourcePos to:(Position *)destinationPos forUnit:(Unit *)unit {
    // movement modifier. this is a suitable average modifier for the cost
    float movementModifier = 2.5f;

    // distance to destination is a manhattan distance
    int distance = abs( sourcePos->x - destinationPos->x ) + abs( sourcePos->y - destinationPos->y );

    // return the seconds it take to travel the distance
    float estimate = distance * movementModifier;

    //NSLog( @"estimate from %d,%d -> %d,%d, distance: %d, estimate: %d", sourcePos->x, sourcePos->y, destinationPos->x, destinationPos->y, distance, estimate );
    //NSLog( @"estimate from %d,%d -> %d,%d, index: %d, terrain: %d, distance: %d, estimate: %.1f", sourcePos->x, sourcePos->y, destinationPos->x, destinationPos->y, index, terrain, distance, estimate );
    return estimate;
}


- (float) getCostToEnterTerrainAt:(Position *)position forUnit:(Unit *)unit {
    // index of the position into the terrain data
    int index = position->y * mapWidth + position->x;

    // terrain at the destination
    TerrainType terrain = terrains[ index ];

    // movement modifier
    float cost = getTerrainPathFindingCost( unit, terrain );

    //NSLog( @"cost to enter %d at %d, %d = %.0f", terrain, position->x, position->y, cost );
    return cost;
}


- (Path *) createPath:( NSMutableArray *)pathPositions {
    Path * path = [Path new];

    // reverse the path to be correct
    [pathPositions reverseObjects];

    // DEBUG
    if ( sPathFinderDebugging ) {
        [self debugResult:pathPositions];
    }

    for ( NSValue * element in pathPositions ) {
        [path addPosition:[element CGPointValue]];
    }

    return path;
}

@end

