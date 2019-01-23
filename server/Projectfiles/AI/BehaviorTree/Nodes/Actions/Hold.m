
#import "Hold.h"
#import "IdleMission.h"

@implementation Hold

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    // make a retreat mission of it
    context.unit.mission = [IdleMission new];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}


@end
