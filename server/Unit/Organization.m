
#import "Organization.h"
#import "Globals.h"
#import "IdleMission.h"

@implementation Organization

- (id) initWithHeadquarter:(Unit *)hq {
    self = [super init];
    if (self) {
        self.headquarter = hq;
        self.engaged = NO;
        self.objective = nil;
        self.owner = hq.owner;

        // initially only one unit here
        self.units = [ NSMutableArray new];
        [self.units addObject:hq];

        // set up the AI stuff only for the second player
        if ( self.owner == kPlayer2 ) {
            // default to something not bad
            self.order = kHold;
        }
    }

    return self;
}


- (void) dealloc {
    NSLog( @"in" );
    self.headquarter = nil;
    self.units       = nil;
    self.objective   = nil;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[Organization, hq: %@, %lu units, engaged: %@]", self.headquarter, (unsigned long)self.units.count, (self.engaged ? @"yes" : @"no")];
}


- (BOOL) containsUnit:(Unit *)unit {
    for ( Unit * tmp in self.units ) {
        if ( tmp == unit ) {
            return YES;
        }
    }

    return NO;
}


- (void) clearMissions {
    if ( self.headquarter ) {
        self.headquarter.mission = nil;
    }

    for ( Unit * unit in self.units ) {
        // only clear the missions that can be cancelled, ie. not retreats/disorganized etc
        if ( unit.mission != nil && unit.mission.canBeCancelled ) {
            unit.mission = nil;
        }
    }
}


- (void) updateCenterOfMass {
    // the start point is the first unit
    self.centerOfMass = ((Unit *)[self.units objectAtIndex:0]).position;
    float mass = self.headquarter.men;

    NSLog( @"start: %f, %f = %f", self.centerOfMass.x, self.centerOfMass.y, mass );

    // loop all other units (skip the first) and add them to the mass
    for ( unsigned int index = 1; index < self.units.count; ++index ) {
        Unit * unit = [self.units objectAtIndex:index];
        float men = unit.men;
        CGPoint pos = unit.position;

        // move the cented towards the unit as far as the weight ratio allows
        self.centerOfMass = ccpLerp( self.centerOfMass, pos, men / (mass + men) );
        mass += men;

        //NSLog( @"start: %f, %f = %f  ->  %f %f = %f", pos.x, pos.y, men, center.x, center.y, mass );
    }

    NSLog( @"center of mass: %f, %f = %f", self.centerOfMass.x, self.centerOfMass.y, mass );
}


- (void) updateEngagementState {
    // NSMutableArray * ownUnits   = [Globals sharedInstance].unitsPlayer2;
     NSMutableArray * enemyUnits = [Globals sharedInstance].unitsPlayer1;

    // initially assume not engaged
    self.engaged = NO;

    // check all enemies
    for ( Unit * enemy in enemyUnits ) {
        // is it close enough for us to be engaged?
        for ( Unit * unit in self.units ) {
            // is it close enough for us to be engaged?
            if ( ccpDistance( unit.position, enemy.position ) < sParameters[kParamMaxAIEngagedDistanceF].floatValue ) {
                NSLog( @"%@ is engaged to enemy %@", unit, enemy );
                self.engaged = YES;
                return;
            }
        }
    }
}

@end
