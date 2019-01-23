
#import "FireAtNearestHeadquarter.h"
#import "Organization.h"
#import "FireMission.h"
#import "Globals.h"
#import "Engine.h"

@implementation FireAtNearestHeadquarter

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    Unit * unit = context.unit;

    Mission * oldMission = unit.mission;
    Unit * oldTarget = nil;
    if ( oldMission && [oldMission isKindOfClass:[CombatMission class]] ) {
        oldTarget = ((CombatMission *)oldMission).targetUnit;
    }

    // find a good target
    Unit * target = nil;
    float closestDistance = MAXFLOAT;

    for ( Unit * enemy in context.blackboard.enemiesInFieldOfFire ) {
        // only handle headquarters
        if ( enemy.type != kInfantryHeadquarter && enemy.type != kCavalryHeadquarter ) {
            continue;
        }

        // distance to the target
        float distance = ccpDistance( unit.position, enemy.position );

        // new closest in range?
        if ( distance < closestDistance ) {
            closestDistance = distance;
            target = enemy;
        }
    }

    // nothing in the field of fire? check the ones in range, even though we may have to turn
    if ( target == nil ) {
        closestDistance = MAXFLOAT;
        for ( Unit * enemy in context.blackboard.enemiesInRange ) {
            // only handle headquarters
            if ( enemy.type != kInfantryHeadquarter && enemy.type != kCavalryHeadquarter ) {
                continue;
            }

            // distance to the target
            float distance = ccpDistance( unit.position, enemy.position );

            // new closest in range?
            if ( distance < closestDistance ) {
                closestDistance = distance;
                target = enemy;
            }
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
