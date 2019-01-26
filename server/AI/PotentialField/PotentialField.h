
#include <Foundation/Foundation.h>


@interface PotentialField : NSObject

- (void) updateField;

- (float) getValue:(CGPoint)pos;

/**
 * Finds the position on the potential field that is the best available from the given position.
 **/
- (BOOL) findMaxPositionFrom:(CGPoint)pos into:(CGPoint *)result;

- (BOOL) findMinThreatPositionFrom:(CGPoint)pos into:(CGPoint *)result;

/**
 * Find the enemy threat level for the given position. The value is scaled from 0 (no enemy influence or threat at
 * all to 100 maximum as well as an absolute value. The scaled does not work too well as if the enemy is weak and no real
 * threat anymore, there are still places with 100 threat, even though the absolute threat is minimal.
 **/
- (void) getThreatForPosition:(CGPoint)pos intoAbsolute:(float *)absThreat scaled:(float *)scaledThreat;

- (void) showDebugInfo;

@end
