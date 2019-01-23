
#import <Foundation/Foundation.h>

#import "Definitions.h"

@class Unit;

@interface ScoreCounter : NSObject

- (void) calculateFinalScores;

// set everything externally. Used in multiplayer games.
- (void) setTotalMen1:(unsigned short)totalMen1 totalMen2:(unsigned short)totalMen2
             lostMen1:(unsigned short)lostMen1 lostMen2:(unsigned short)lostMen2
          objectives1:(unsigned short)objectives1 objectives2:(unsigned short)objectives2;

- (unsigned short) getTotalMen:(PlayerId)player;
- (unsigned short) getLostMen:(PlayerId)player;
- (unsigned short) getObjectivesScore:(PlayerId)player;

@end
