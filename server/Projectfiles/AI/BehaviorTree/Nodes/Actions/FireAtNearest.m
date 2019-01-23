
#import "FireAtNearest.h"
#import "Organization.h"
#import "FireMission.h"
#import "Globals.h"
#import "Engine.h"

@implementation FireAtNearest

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    Unit * unit = context.unit;

    Mission * oldMission = unit.mission;
    Unit * oldTarget = nil;
    if ( oldMission && [oldMission isKindOfClass:[CombatMission class]] ) {
        oldTarget = ((CombatMission *)oldMission).targetUnit;
    }

    // find a good target
    Unit * target;
    if ( ( target = context.blackboard.closestEnemyInFieldOfFire) == nil ) {
        if ( ( target = context.blackboard.closestEnemyInRange) == nil ) {
            // no suitable taget
            CCLOG( @"no suitable target?" );
            return [self failed:context];
        }
    }

    // did we get a new target?
    if ( oldTarget != nil && target == oldTarget ) {
        CCLOG( @"best target still the old target, doing nothing and succeeding" );
        return [self succeeded:context];
    }

    CCLOG( @"assigning new target %@", target );

    // have it fire at the found target
    unit.mission = [[FireMission alloc] initWithTarget:target];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}


@end
