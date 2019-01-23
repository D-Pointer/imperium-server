
#import "CanRally.h"
#import "Organization.h"

@implementation CanRally

- (void) update {
    // by default there is no unit that can be rallied
    self.foundUnit = nil;
    
    Unit * unit = self.unit;

    if ( unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
        self.isTrue = NO;
        return;
    }

    // if we're already rallying then we don't rally again to avoid the target being flipped every single
    // time this is updated
    if ( unit.mission.type == kRallyMission ) {
        self.isTrue = NO;
        return;
    }

    if ( ! [unit canBeGivenMissions] ) {
        self.isTrue = NO;
        return;
    }

    // does it have an organization?
    Organization * organization = unit.organization;
    if ( organization == nil ) {
        self.isTrue = NO;
        return;
    }

    // check all subordinates to find someone that needs rallying
    for ( Unit * subordinate in organization.units ) {
        if ( unit == subordinate ) {
            continue;
        }

        // is the morale of the subordinate unit low enough?
        if ( subordinate.morale >= sMaxMoraleShaken ) {
            continue;
        }

        // is it in command?
        if ( ! subordinate.inCommand ) {
            return NO;
        }

        // it also can have no mission apart from being disorganized
        if ( subordinate.mission.type != kIdleMission && subordinate.mission.type != kDisorganizedMission ) {
            continue;
        }

        // does the HQ see the unit?
        if  ( ! [unit.losData seesUnit:subordinate] ) {
            // hq does not see the unit, can't rally
            return NO;
        }

        // at least one unit found that needs rallying
        self.isTrue = YES;

        // cache the subordinate unit
        self.foundUnit = subordinate;
        return;
    }

    // no unit needing rallying found
    self.isTrue = NO;
}

@end
