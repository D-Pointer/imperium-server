
#import "PotentialField.h"
#import "Globals.h"
#import "PotentialFieldLayer.h"
#import "EnemyLayer.h"
#import "ObjectivesLayer.h"
#import "TerrainLayer.h"
#import "ResultLayer.h"
#import "OwnUnitsLayer.h"
#import "FrontLayer.h"

@interface PotentialField ()

@property (nonatomic, strong) EnemyLayer *      enemiesLayer;
@property (nonatomic, strong) ObjectivesLayer * objectivesLayer;
@property (nonatomic, strong) TerrainLayer *    terrainLayer;
@property (nonatomic, strong) OwnUnitsLayer *   ownUnitsLayer;
@property (nonatomic, strong) FrontLayer *      frontLayer;
@property (nonatomic, strong) NSArray *         layers;
@property (nonatomic, strong) ResultLayer *     combined;

@end


@implementation PotentialField

- (instancetype) init {
    self = [super init];
    if (self) {
        self.enemiesLayer    = [EnemyLayer new];
        self.objectivesLayer = [ObjectivesLayer new];
        self.terrainLayer    = [TerrainLayer new];
        self.ownUnitsLayer   = [OwnUnitsLayer new];
        self.frontLayer      = [FrontLayer new];

        self.layers = @[ self.enemiesLayer,
                         self.objectivesLayer,
                         self.terrainLayer,
                         self.ownUnitsLayer,
                         self.frontLayer];

        // set weights
        self.enemiesLayer.weight    = 100.0f;
        self.objectivesLayer.weight =  60.0f;
        self.terrainLayer.weight    =  50.0f;
        self.ownUnitsLayer.weight   =  80.0f;
        self.frontLayer.weight      =  50.0f;

        // final result layer
        self.combined = [ResultLayer new];
    }

    return self;
}


- (void) updateField {
    NSLog( @"updating fields" );

    // update all layers
    for ( PotentialFieldLayer * layer in self.layers ) {
        [layer update];
    }

    // clear the combined
    [self.combined clear];

    NSLog( @"combining result field" );

    // merge them
    for ( PotentialFieldLayer * layer in self.layers ) {
        [layer applyTo:self.combined];
    }
}


- (float) getValue:(CGPoint)pos {
    return [self.combined getValue:pos];
}


- (BOOL) findMaxPositionFrom:(CGPoint)pos into:(CGPoint *)result {
    // map to the low res coordinate system
    int x = pos.x / sParameters[kParamPotentialFieldTileSizeI].intValue;
    int y = pos.y / sParameters[kParamPotentialFieldTileSizeI].intValue;

    NSLog( @"finding best position for: %.0f %.0f (%d %d)", pos.x, pos.y, x, y );

    // the data array
    float * data = [self.combined getData];
    int width = self.combined.width;
    int height = self.combined.height;

    // current value
    float current = data[ y * width + x ];

    NSLog( @"current potential: %.1f", current );

    // set up deltas for all positions that are around
    int around[16] = {
        -1,  0 , // left
        1,  0 , // right
        0,  1 , // up
        0, -1 , // down
        -1,  1 , // up left
        1,  1 , // up right
        -1, -1 , // down left
        1, -1  // down right
    };

    float bestValue = current;
    int bestX, bestY;
    BOOL bestFound = NO;

    // check all the 8 positions around
    for ( int index = 0; index < 8; ++index ) {
        int tmpX = x + around[ index * 2 + 0];
        int tmpY = y + around[ index * 2 + 1];

        // inside?
        if ( tmpX >= 0 && tmpX < width && tmpY >= 0 && tmpY < height ) {
            // a better value with higher potential?
            float value = data[ tmpY * width + tmpX ];
            if ( value > bestValue ) {
                bestValue = value;
                bestX = tmpX;
                bestY = tmpY;
                bestFound = YES;
            }

            NSLog( @"checking %d %d = %.1f", tmpX, tmpY, value );
        }
    }

    if ( bestFound ) {
        NSLog( @"best found: %d %d, potential: %.1f", bestX, bestY, bestValue );
        int tileSize = sParameters[kParamPotentialFieldTileSizeI].intValue;

        // the result is in the middle of the result tile
        result->x = bestX * tileSize + tileSize / 2;
        result->y = bestY * tileSize + tileSize / 2;
        return YES;
    }

    // nothing found
    NSLog( @"no better potential position found" );
    return NO;
}


- (BOOL) findMinThreatPositionFrom:(CGPoint)pos into:(CGPoint *)result {
    // map to the low res coordinate system
    int x = pos.x / sParameters[kParamPotentialFieldTileSizeI].intValue;
    int y = pos.y / sParameters[kParamPotentialFieldTileSizeI].intValue;

    NSLog( @"finding min threat position for: %.0f %.0f (%d %d)", pos.x, pos.y, x, y );

    // the data array
    float * data = [self.enemiesLayer getData];
    int width    = self.enemiesLayer.width;
    int height   = self.enemiesLayer.height;

    // current value
    float current = data[ y * width + x ];

    NSLog( @"current potential: %.1f", current );

    // set up deltas for all positions that are around
    int around[16] = {
         -1,  0 , // left
          1,  0 , // right
          0,  1 , // up
          0, -1 , // down
         -1,  1 , // up left
          1,  1 , // up right
         -1, -1 , // down left
          1, -1  // down right
    };

    float bestValue = current;
    int bestX = 0, bestY = 0;
    BOOL bestFound = NO;

    // check all the 8 positions around
    for ( int index = 0; index < 8; ++index ) {
        int tmpX = x + around[ index * 2 + 0];
        int tmpY = y + around[ index * 2 + 1];

        // inside?
        if ( tmpX >= 0 && tmpX < width && tmpY >= 0 && tmpY < height ) {
            // a better value with higher potential?
            float value = data[ tmpY * width + tmpX ];
            if ( value < bestValue ) {
                bestValue = value;
                bestX = tmpX;
                bestY = tmpY;
                bestFound = YES;
            }

            NSLog( @"checking %d %d = %.1f", tmpX, tmpY, value );
        }
    }

    if ( bestFound ) {
        NSLog( @"min found: %d %d, potential: %.1f", bestX, bestY, bestValue );
        int tileSize = sParameters[kParamPotentialFieldTileSizeI].intValue;

        // the result is in the middle of the result tile
        result->x = bestX * tileSize + tileSize / 2;
        result->y = bestY * tileSize + tileSize / 2;
        return YES;
    }

    // nothing found
    NSLog( @"no better potential position found" );
    return NO;
}


- (void) getThreatForPosition:(CGPoint)pos intoAbsolute:(float *)absThreat scaled:(float *)scaledThreat {
    // map to the low res coordinate system
    int x = pos.x / sParameters[kParamPotentialFieldTileSizeI].intValue;
    int y = pos.y / sParameters[kParamPotentialFieldTileSizeI].intValue;

    NSLog( @"finding threat level for position: %.0f %.0f (%d %d)", pos.x, pos.y, x, y );

    // threat value
    float * data = [self.enemiesLayer getData];
    *absThreat = data[ y * self.enemiesLayer.width + x ];

    // scaled threat
    *scaledThreat = *absThreat / self.enemiesLayer.max;

    NSLog( @"finding threat level for position: %.0f %.0f (%d %d). Absolute: %.1f, scaled: %.1f", pos.x, pos.y, x, y, *absThreat, *scaledThreat );
}


@end
