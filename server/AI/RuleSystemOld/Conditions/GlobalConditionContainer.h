
#import "Globals.h"

#import "AttackScenario.h"
#import "MeetingScenario.h"
#import "DefendScenario.h"
#import "BeginningOfGame.h"
#import "FirstTurn.h"
#import "AreAllObjectivesHeld.h"

@interface GlobalConditionContainer : NSObject

// unit specific conditions
@property (nonatomic, strong) AreAllObjectivesHeld * areAllObjectivesHeld;
@property (nonatomic, strong) AttackScenario *       isAttackScenarioCondition;
@property (nonatomic, strong) MeetingScenario *      isMeetingScenarioCondition;
@property (nonatomic, strong) DefendScenario *       isDefendScenarioCondition;
@property (nonatomic, strong) BeginningOfGame *      isBeginningOfGameCondition;
@property (nonatomic, strong) FirstTurn *            isFirstTurnCondition;
@property (nonatomic, strong) NSArray *              globalConditions;

/**
 * Updates the conditions.
 **/
- (void) update;

@end
