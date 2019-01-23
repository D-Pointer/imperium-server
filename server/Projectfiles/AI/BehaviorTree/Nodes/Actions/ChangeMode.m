
#import "ChangeMode.h"
#import "Organization.h"
#import "ChangeModeMission.h"

@implementation ChangeMode

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );
    context.unit.mission = [ChangeModeMission new];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}



@end
