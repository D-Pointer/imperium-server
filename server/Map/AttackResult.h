


#import "Unit.h"
#import "RoutMission.h"

@interface AttackResult : CCNode

@property (nonatomic, weak)   Unit *            attacker;
@property (nonatomic, weak)   Unit *            target;
@property (nonatomic, assign) int               casualties;
@property (nonatomic, assign) AttackMessageType messageType;
@property (nonatomic, strong) RoutMission *     routMission;
@property (nonatomic, assign) float             targetMoraleChange;
@property (nonatomic, assign) float             attackerMoraleChange;

- (id) initWithMessage:(AttackMessageType)message
          withAttacker:(Unit *)attacker
             forTarget:(Unit *)target
            casualties:(int)casualties
           routMission:(RoutMission *)routMission
    targetMoraleChange:(float)targetMoraleChange
  attackerMoraleChange:(float)attackerMoraleChange;


- (void) execute;

@end
