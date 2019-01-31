
#import "LineOfSight.h"
#import "Globals.h"
#import "Unit.h"
#import "Map.h"

@interface LineOfSight () {
    // two arrays, one for each player
    UInt8 * data[2];

    // number of own units
    unsigned int units1Count;

    // number of enemy units
    unsigned int units2Count;
}

@end


@implementation LineOfSight

- (instancetype) init {
    self = [super init];
    if (self) {
         NSMutableArray * units1 = [Globals sharedInstance].unitsPlayer1;
         NSMutableArray * units2 = [Globals sharedInstance].unitsPlayer2;

        units1Count = (unsigned int)units1.count;
        units2Count = (unsigned int)units2.count;

        // allocate space for the visibility matrix and fill with 0
        data[0] = malloc( units1Count * units2Count * sizeof(UInt8) );
        data[1] = malloc( units1Count * units2Count * sizeof(UInt8) );
        memset( data[0], 0, units1Count * units2Count * sizeof(UInt8) );
        memset( data[1], 0, units1Count * units2Count * sizeof(UInt8) );

        // set up LOS data for all units
        int index = 0;
        for ( Unit * unit in units1 ) {
            // the LOS index is a number indicating the unit's index in the units array
            unit.losIndex = index++;

            // the LOS data is used to contain LOS info about the AI units
            unit.losData = [[LineOfSightData alloc] initWithUnits:units2];
        }

        index = 0;
        for ( Unit * unit in units2 ) {
            unit.losIndex = index++;
            unit.losData = [[LineOfSightData alloc] initWithUnits:units1];
        }
    }

    return self;
}


- (void) dealloc {
    for ( int index = 0; index < 2; ++index ) {
        if ( data[ index ] ) {
            free( data[ index ] );
            data[ index ] = 0;
        }
    }
}


- (void) update {
    Map * map = [Globals sharedInstance].map;

    NSMutableArray * units1 = [Globals sharedInstance].unitsPlayer1;
    NSMutableArray * units2 = [Globals sharedInstance].unitsPlayer2;

    units1Count = (unsigned int)units1.count;
    units2Count = (unsigned int)units2.count;

    // clear all data
    memset( data[0], 0, units1Count * units2Count * sizeof(UInt8) );
    memset( data[1], 0, units1Count * units2Count * sizeof(UInt8) );

    // initially hide all enemy units, they are revealed below if seen
    for (unsigned int index = 0; index < units2Count; ++index ) {
        Unit * unit2 = units2[index];
        //units2.visible = NO;

        // it also does not see anyone yet
        [unit2.losData clearSeen];
    }

    // loop all the units for player 1, the human player
    for ( unsigned int index1 = 0; index1 < units1Count; ++index1 ) {
        Unit * unit1 = units1[index1];

        // initially sees no enemy units
        [unit1.losData clearSeen];

        // is the own unit alive?
        if ( unit1.destroyed ) {
            // yes, it can't see anything, do nothing as its row is already cleared
            //units1.visible = NO;
            continue;
        }

        // own ok unit, always visible
        //units1.visible = YES;

        // now loop all enemy units
        for (unsigned int index2 = 0; index2 < units2Count; ++index2 ) {
            Unit * unit2 = units2[index2];

            // is the ai unit alive?
            if ( unit2.destroyed ) {
                // it's destroyed, nothing to do
                continue;
            }

            // can the unit see to the enemy?
            if ( [map canSeeFrom:unit1.position to:unit2.position visualize:NO withMaxRange:unit1.visibilityRange] ) {
                // it is visible
                data[0][ units1Count * index1 + index2 ] = 1;
                data[1][ units2Count * index2 + index1 ] = 1;

                // save the data in both unit's LOS data
                [unit1.losData setSeen:unit2];
                [unit2.losData setSeen:unit1];

                // was the unit hidden, ie not seen by anyone else yet?
                if ( ! unit2.visible ) {
                    // so this unit saw it first during this update, did it see it before?
                    if ( ! [unit1.losData wasUnitPreviouslySeen:unit2] ) {
                        // the unit did spot a new enemy it did not see last update
                        unit1.losData.didSpotNewEnemies = YES;
                        //NSLog( @"%@ spotted a new enemy: %@", units1, enemy );
                    }

                    //unit2.visible = YES;
                }
            }
        }
    }

    // loop all own units
//    for ( unsigned int humanIndex = 0; humanIndex < units1Count; ++humanIndex ) {
//        Unit * humanUnit = [self.units1s objectAtIndex:humanIndex];
//
//        // loop all the units that this unit used to see but no longer sees
//        for ( unsigned int oldSeenIndex = 0; oldSeenIndex < humanUnit.losData.oldSeenCount; ++oldSeenIndex ) {
//            Unit * oldSeen = [humanUnit.losData getPreviouslySeenUnit:oldSeenIndex];
//            //NSLog( @"%@ saw %@, still sees: %@", humanUnit, oldSeen, oldSeen.visible ? @"yes" : @"no" );
//
//            // if the unit that is used to see is not seen any anyone else either, then mark it with a question mark
//            if ( ! oldSeen.visible && oldSeen.questionMark == nil && ! oldSeen.destroyed ) {
//                //NSLog( @"=== unit has been hidden" );
//
//                // set up the question mark
//                oldSeen.questionMark = [CCSprite spriteWithSpriteFrameName:oldSeen.owner == kPlayer1 ? @"Units/QuestionMark1.png" : @"Units/QuestionMark2.png"];
//                oldSeen.questionMark.position = oldSeen.position;
//                [[Globals sharedInstance].map addChild:oldSeen.questionMark z:kUnitZ];
//            }
//        }
//    }

    // now loop all visible units that have a question mark and remove it, they are now visible again
//    for ( Unit * unit in self.units2s) {
//        if ( unit.visible && unit.questionMark != nil ) {
//            [unit.questionMark removeFromParent];
//            unit.questionMark = nil;
//        }
//    }
}

@end
