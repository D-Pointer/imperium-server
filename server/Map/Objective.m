
#import "Objective.h"
#import "Globals.h"
#import "Unit.h"
#import "CGPointExtension.h"

@implementation Objective

- (NSString *) description {
    return [NSString stringWithFormat:@"[Objective %@]", self.title];
}


- (BOOL) isHit:(CGPoint)pos {
    return ccpDistance( self.position, pos ) < sParameters[kParamObjectiveRadiusF].floatValue;
}


+ (void) updateOwnerForAllObjectives {
    // all units
     NSMutableArray * units = [Globals sharedInstance].units;

    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        BOOL near[2] = { NO, NO };

        // check all units
        for ( Unit * unit in units ) {
            // destroyed units don't count...
            if ( unit.destroyed ) {
                continue;
            }
            
            // don't check if we already have one unit for that player that is close enough
            if ( near[ unit.owner ] == YES ) {
                continue;
            }

            float distance = ccpDistance( unit.position, objective.position );

            // is the unit within range to capture the objective?
            if ( distance < sParameters[kParamObjectiveMaxDistanceF].floatValue ) {
                near[ unit.owner ] = YES;
            }
        }

        // it's contested if both are near it
        if ( near[ kPlayer1 ] && near[ kPlayer2 ] ) {
            // contested
            objective.state = kContested;
            NSLog( @"%@ contested", objective.title );
        }
        else if ( near[ kPlayer1 ] ) {
            objective.state = kOwnerPlayer1;
            NSLog( @"%@ owned by player 1", objective.title );
        }
        else if ( near[ kPlayer2 ] ) {
            objective.state = kOwnerPlayer2;
            NSLog( @"%@ owned by player 2", objective.title );
        }
        else {
            // neutral
            objective.state = kNeutral;
            NSLog( @"%@ neutral", objective.title );
        }
    }
}


+ (Objective *) create {
    Objective * objective = [Objective new];
    objective.objectiveId = -1;
    objective.state = kNeutral;

    return objective;
}

@end
