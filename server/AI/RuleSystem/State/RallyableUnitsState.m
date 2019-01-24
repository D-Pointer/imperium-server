
#import "RallyableUnitsState.h"
#import "Unit.h"
#import "Organization.h"

@implementation RallyableUnitsState

- (void) update:(UnitContext *)context forRuleSystem:(GKRuleSystem *)ruleSystem {
    float closestDistance = MAXFLOAT;

    Unit * unit = context.unit;

    // default to no units
    ruleSystem.state[ @"rallyableUnits" ] = nil;
    ruleSystem.state[ @"closestRallyableUnit" ] = nil;

    if ( unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
        return;
    }

    // if we're already rallying then we don't rally again to avoid the target being flipped every single
    // time this is updated
    if ( unit.mission.type == kRallyMission ) {
        return;
    }

    if ( ! [unit canBeGivenMissions] ) {
        return;
    }

    // does it have an organization?
    Organization * organization = unit.organization;
    if ( organization == nil ) {
        return;
    }

    NSMutableArray * rallyableUnits = [NSMutableArray new];
    Unit * closestRallyableUnit = nil;

    // check all subordinates to find someone that needs rallying
    for ( Unit * subordinate in organization.units ) {
        if ( unit == subordinate ) {
            continue;
        }

        // is the morale of the subordinate unit low enough?
        if ( subordinate.morale >= sParameters[kParamMaxMoraleShakenF].floatValue ) {
            continue;
        }

        // is it in command?
        if ( ! subordinate.inCommand ) {
            continue;
        }

        // it also can have no mission apart from being disorganized
        if ( subordinate.mission.type != kIdleMission && subordinate.mission.type != kDisorganizedMission ) {
            continue;
        }

        // does the HQ see the unit?
        if  ( ! [unit.losData seesUnit:subordinate] ) {
            // hq does not see the unit, can't rally
            continue;
        }

        // cache the subordinate unit
        [rallyableUnits addObject:subordinate];

        // new closest rallyable unit?
        float distance = ccpDistance( unit.position, subordinate.position );
        if ( distance < closestDistance ) {
            closestDistance = distance;
            closestRallyableUnit = subordinate;
        }

        break;
    }

    ruleSystem.state[ @"rallyableUnits" ]       = rallyableUnits;
    ruleSystem.state[ @"closestRallyableUnit" ] = closestRallyableUnit;
    
    NSLog( @"rallyable units: %lu", (unsigned long)rallyableUnits.count );
}

@end
