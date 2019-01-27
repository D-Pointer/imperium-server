
#import "ScoreCounter.h"
#import "Unit.h"
#import "Globals.h"
#import "Objective.h"

@interface ScoreCounter () {
    unsigned short total_men[2];
    unsigned short lost_men[2];
    unsigned short objectives[2];
}

@end


@implementation ScoreCounter


- (id) init {
    self = [super init];
    if (self) {
        // nothing to do
    }
    
    return self;
}


- (void) calculateFinalScores {
    // clear all values
    for ( int index = 0; index < 2; ++index ) {
        total_men[ index ]   = 0;
        lost_men[ index ]    = 0;
        objectives[ index ]  = 0;
    }

    // number of units and lost units
    for ( Unit * unit in [Globals sharedInstance].units ) {
        // total men at start
        total_men[ unit.owner ] += unit.originalMen;

        // casualties
        int killed = unit.originalMen - unit.men;
        lost_men[ unit.owner ] += killed;
    }
    
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        int near[2] = { 0, 0 };
        
        // loop all the units and see which are close enough
        for ( Unit * unit in [Globals sharedInstance].units ) {
            // is this unit close enough?
            if ( ccpDistance( unit.position, objective.position ) <  sParameters[kParamObjectiveMaxDistanceF].floatValue ) {
                near[ unit.owner ]++;
            }
        }
        
        if ( near[ kPlayer1 ] > 0 && near[ kPlayer2 ] == 0 ) {
            // player 1 has units near it
            objectives[ kPlayer1 ] += sParameters[kParamObjectiveFullValueF].floatValue;
            //NSLog( @"player 1 has objective" );
        }
        
        else if ( near[ kPlayer1 ] == 0 && near[ kPlayer2 ] > 0 ) {
            // player 2 has units near it
            objectives[ kPlayer2 ] += sParameters[kParamObjectiveFullValueF].floatValue;
            //NSLog( @"player 2 has objective" );
        }

        else if ( near[ kPlayer1 ] > 0 && near[ kPlayer2 ] > 0 ) {
            // both players have units near it
            objectives[ kPlayer1 ] += sParameters[kParamObjectiveSharedValueF].floatValue;
            objectives[ kPlayer2 ] += sParameters[kParamObjectiveSharedValueF].floatValue;
            //NSLog( @"both players have objective" );
        }
        
        else {
            // none has it
            //NSLog( @"no player has objective" );
        }
    }
}


- (void) setTotalMen1:(unsigned short)totalMen1 totalMen2:(unsigned short)totalMen2
             lostMen1:(unsigned short)lostMen1 lostMen2:(unsigned short)lostMen2
          objectives1:(unsigned short)objectives1 objectives2:(unsigned short)objectives2 {
    total_men[kPlayer1]  = totalMen1;
    total_men[kPlayer2]  = totalMen2;
    lost_men[kPlayer1]   = lostMen1;
    lost_men[kPlayer2]   = lostMen2;
    objectives[kPlayer1] = objectives1;
    objectives[kPlayer2] = objectives2;
}


- (unsigned short) getTotalMen:(PlayerId)player {
    return total_men[ player ];    
}


- (unsigned short) getLostMen:(PlayerId)player {
    return lost_men[ player ];    
}


- (unsigned short) getObjectivesScore:(PlayerId)player {
    return objectives[ player ];        
}


@end
