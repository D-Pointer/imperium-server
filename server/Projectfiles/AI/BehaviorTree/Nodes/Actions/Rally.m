#import "Rally.h"
#import "LineOfSight.h"
#import "RallyMission.h"
#import "Globals.h"

@implementation Rally

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    Unit *unit = context.unit;

    if ( unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
        return kFailed;
    }

    // we simply assume this unit can rally...
    Unit *rallyTarget = context.blackboard.closestRallyableUnit;
    if ( ! rallyTarget ) {
        CCLOG( @"no rally target, can not rally" );
        return [self failed:context];
    }

    NSAssert( rallyTarget != nil, @"rally target is nil" );

    CCLOG( @"%@ trying to assault %@", unit, rallyTarget );

    // all ok, set up a rallying missing
    unit.mission = [[RallyMission alloc] initWithTarget:rallyTarget];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}

@end
