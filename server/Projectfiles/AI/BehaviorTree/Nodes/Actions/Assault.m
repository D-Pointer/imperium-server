
#import "Assault.h"
#import "AssaultMission.h"
#import "Globals.h"

@implementation Assault

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );
    
    Unit * attacker = context.unit;

    // find a good target
    Unit * target;
    if ( ( target = context.blackboard.closestEnemyInFieldOfFire) == nil ) {
        if ( ( target = context.blackboard.closestEnemyInRange) == nil ) {
            // no suitable taget
            CCLOG( @"no suitable target?" );
            return [self failed:context];
        }
    }

    // is the target weak enough?
    if ( target.men <= target.men * 1.5f ) {
        CCLOG( @"target %@ is too strong, not assaulting", target );
        return [self failed:context];
    }

    CCLOG( @"%@ trying to assault %@", attacker, target );

    // still inside, so try to find a path there
    Path * path = [[Globals sharedInstance].pathFinder findPathFrom:attacker.position to:target.position forUnit:attacker];
    if ( path == nil ) {
        CCLOG( @"did not find a path from %@ to %@, not assaulting", attacker, target );
        return [self failed:context];
    }

    // DEBUG
    if ( sAIDebugging ) {
        [path debugPath];
    }

    // have it fire at the found target
    attacker.mission = [[AssaultMission alloc] initWithPath:path];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}

@end
