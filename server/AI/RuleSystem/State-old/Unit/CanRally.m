
#import "CanRally.h"
#import "Organization.h"

@implementation CanRally

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    return context.blackboard.rallyableUnits.count > 0 ? kSucceeded : kFailed;

//    return kFailed;
//
//    Unit * unit = context.unit;
//    BOOL found = NO;
//
//    if ( unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
//        return kFailed;
//    }
//
//    // if we're already rallying then we don't rally again to avoid the target being flipped every single
//    // time this is updated
//    if ( unit.mission.type == kRallyMission ) {
//        return kFailed;
//    }
//
//    if ( ! [unit canBeGivenMissions] ) {
//        return kFailed;
//    }
//
//    // does it have an organization?
//    Organization * organization = unit.organization;
//    if ( organization == nil ) {
//        return kFailed;
//    }
//
//    // check all subordinates to find someone that needs rallying
//    for ( Unit * subordinate in organization.units ) {
//        if ( unit == subordinate ) {
//            continue;
//        }
//
//        // is the morale of the subordinate unit low enough?
//        if ( subordinate.morale >= sMaxMoraleShaken ) {
//            continue;
//        }
//
//        // is it in command?
//        if ( ! subordinate.inCommand ) {
//            continue;
//        }
//
//        // it also can have no mission apart from being disorganized
//        if ( subordinate.mission.type != kIdleMission && subordinate.mission.type != kDisorganizedMission ) {
//            continue;
//        }
//
//        // does the HQ see the unit?
//        if  ( ! [unit.losData seesUnit:subordinate] ) {
//            // hq does not see the unit, can't rally
//            continue;
//        }
//
//        // cache the subordinate unit
//        context.blackboard.rallyableUnit = subordinate;
//        found = YES;
//        break;
//    }
//
//    // no unit needing rallying found
//    if ( found ) {
//        return kSucceeded;
//    }
//
//    return kFailed;
}

@end
