
#import "LineOfSight.h"
#import "Globals.h"
#import "Unit.h"
#import "Map.h"

@interface LineOfSight () {
    // two arrays, one for each player
    UInt8 * data[2];

    // number of own units
    unsigned int ownUnitCount;

    // number of enemy units
    unsigned int enemyUnitCount;
}

@property (nonatomic, weak)  NSMutableArray * ownUnits;
@property (nonatomic, weak)  NSMutableArray * enemyUnits;

@end


@implementation LineOfSight

- (instancetype) init {
    self = [super init];
    if (self) {
         NSMutableArray * units1 = [Globals sharedInstance].unitsPlayer1;
         NSMutableArray * units2 = [Globals sharedInstance].unitsPlayer2;

        if ( [Globals sharedInstance].player1.type == kLocalPlayer ) {
            self.ownUnits = [Globals sharedInstance].unitsPlayer1;
            self.enemyUnits = [Globals sharedInstance].unitsPlayer2;
        }
        else {
            self.ownUnits = [Globals sharedInstance].unitsPlayer2;
            self.enemyUnits = [Globals sharedInstance].unitsPlayer1;
        }

        ownUnitCount = (unsigned int)self.ownUnits.count;
        enemyUnitCount = (unsigned int)self.enemyUnits.count;

        // allocate space for the visibility matrix and fill with 0
        data[0] = malloc( ownUnitCount * enemyUnitCount * sizeof(UInt8) );
        data[1] = malloc( ownUnitCount * enemyUnitCount * sizeof(UInt8) );
        memset( data[0], 0, ownUnitCount * enemyUnitCount * sizeof(UInt8) );
        memset( data[1], 0, ownUnitCount * enemyUnitCount * sizeof(UInt8) );

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
    MapLayer * map = [Globals sharedInstance].map;

    // clear all data
    memset( data[0], 0, ownUnitCount * enemyUnitCount * sizeof(UInt8) );
    memset( data[1], 0, ownUnitCount * enemyUnitCount * sizeof(UInt8) );

    // initially hide all enemy units, they are revealed below if seen
    for (unsigned int enemyIndex = 0; enemyIndex < enemyUnitCount; ++enemyIndex ) {
        Unit * enemyUnit = [self.enemyUnits objectAtIndex:enemyIndex];

        // DEBUG
        if ( sShowAllUnitsDebugging ) {
            enemyUnit.visible = YES;
        }
        else {
            // normal mode, hide the enemies
            enemyUnit.visible = NO;
        }

        // it also does not see anyone yet
        [enemyUnit.losData clearSeen];
    }

    // loop all the units for player 1, the human player
    for ( unsigned int ownIndex = 0; ownIndex < ownUnitCount; ++ownIndex ) {
        Unit * ownUnit = [self.ownUnits objectAtIndex:ownIndex];

        // initially sees no enemy units
        [ownUnit.losData clearSeen];

        // is the own unit alive?
        if ( ownUnit.destroyed ) {
            // yes, it can't see anything, do nothing as its row is already cleared
            ownUnit.visible = NO;
            continue;
        }

        // own ok unit, always visible
        ownUnit.visible = YES;

        // now loop all enemy units
        for (unsigned int enemyIndex = 0; enemyIndex < enemyUnitCount; ++enemyIndex ) {
            Unit * enemy = [self.enemyUnits objectAtIndex:enemyIndex];

            // is the ai unit alive?
            if ( enemy.destroyed ) {
                // it's destroyed, nothing to do
                continue;
            }

            // can the unit see to the enemy?
            if ( [map canSeeFrom:ownUnit.position to:enemy.position visualize:NO withMaxRange:ownUnit.visibilityRange] ) {
                // it is visible
                data[0][ ownUnitCount * ownIndex + enemyIndex ] = 1;
                data[1][ enemyUnitCount * enemyIndex + ownIndex ] = 1;

                // save the data in both unit's LOS data
                [ownUnit.losData setSeen:enemy];
                [enemy.losData setSeen:ownUnit];

                // was the unit hidden, ie not seen by anyone else yet?
                if ( ! enemy.visible ) {
                    // so this unit saw it first during this update, did it see it before?
                    if ( ! [ownUnit.losData wasUnitPreviouslySeen:enemy] ) {
                        // the unit did spot a new enemy it did not see last update
                        ownUnit.losData.didSpotNewEnemies = YES;
                        //NSLog( @"%@ spotted a new enemy: %@", ownUnit, enemy );
                    }

                    enemy.visible = YES;
                }
            }
        }
    }

    // loop all own units
    for ( unsigned int humanIndex = 0; humanIndex < ownUnitCount; ++humanIndex ) {
        Unit * humanUnit = [self.ownUnits objectAtIndex:humanIndex];

        // loop all the units that this unit used to see but no longer sees
        for ( unsigned int oldSeenIndex = 0; oldSeenIndex < humanUnit.losData.oldSeenCount; ++oldSeenIndex ) {
            Unit * oldSeen = [humanUnit.losData getPreviouslySeenUnit:oldSeenIndex];
            //NSLog( @"%@ saw %@, still sees: %@", humanUnit, oldSeen, oldSeen.visible ? @"yes" : @"no" );

            // if the unit that is used to see is not seen any anyone else either, then mark it with a question mark
            if ( ! oldSeen.visible && oldSeen.questionMark == nil && ! oldSeen.destroyed ) {
                //NSLog( @"=== unit has been hidden" );

                // set up the question mark
                oldSeen.questionMark = [CCSprite spriteWithSpriteFrameName:oldSeen.owner == kPlayer1 ? @"Units/QuestionMark1.png" : @"Units/QuestionMark2.png"];
                oldSeen.questionMark.position = oldSeen.position;
                [[Globals sharedInstance].map addChild:oldSeen.questionMark z:kUnitZ];
            }
        }
    }

    // now loop all visible units that have a question mark and remove it, they are now visible again
    for ( Unit * unit in self.enemyUnits) {
        if ( unit.visible && unit.questionMark != nil ) {
            [unit.questionMark removeFromParent];
            unit.questionMark = nil;
        }
    }
}

@end
