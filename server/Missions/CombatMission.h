
#import "Mission.h"
#import "RotateMission.h"
#import "RoutMission.h"
#import "AttackVisualization.h"


@interface CombatMission : Mission

// the target unit is a weak reference!
@property (nonatomic, weak)   Unit * targetUnit;

- (void) fireAtTarget:(CGPoint)target withUnit:(Unit *)attacker targetSeen:(BOOL)seen;

- (float) getMeleeStrengthFor:(Unit *)attacker;

// static routing utility
+ (RoutMission *) routUnit:(Unit *)router;

- (void) createAttackVisualizationForAttacker:(Unit *)attacker casualties:( NSMutableArray *)casualties hitPosition:(CGPoint)hitPosition;

- (void) createMeleeVisualizationForAttacker:(Unit *)attacker
                                    defender:(Unit *)defender
                                     menLost:(int)menLost
                              percentageLost:(float)percentageLost
                                   destroyed:(BOOL)destroyed
                                 routMission:(RoutMission *)routMission;

@end
