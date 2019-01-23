
#import "GlobalConditionContainer.h"

@implementation GlobalConditionContainer

- (instancetype) init {
    self = [super init];
    if (self) {
        // create the global rules
        self.areAllObjectivesHeld       = [AreAllObjectivesHeld new];
        self.isAttackScenarioCondition  = [AttackScenario new];
        self.isMeetingScenarioCondition = [MeetingScenario new];
        self.isDefendScenarioCondition  = [DefendScenario new];
        self.isBeginningOfGameCondition = [BeginningOfGame new];
        self.isFirstTurnCondition       = [FirstTurn new];

        // a convenient list of all conditions
        self.globalConditions = @[ self.areAllObjectivesHeld,
                                   self.isAttackScenarioCondition,
                                   self.isMeetingScenarioCondition,
                                   self.isDefendScenarioCondition,
                                   self.isBeginningOfGameCondition,
                                   self.isFirstTurnCondition
                                   ];

        CCLOG( @"set up %lu globals conditions", (unsigned long)self.globalConditions.count );
    }

    return self;
}


- (void) update {
    CCLOG( @"updating globals conditions" );

    for ( Action * condition in self.globalConditions ) {
        [condition update];
        CCLOG( @"condition %@ == %@", condition.name, condition.isTrue ? @"yes" : @"no" );
    }
}

@end
