
#import "AttackResult.h"
#import "Globals.h"


@implementation AttackResult

- (id) initWithMessage:(AttackMessageType)message
          withAttacker:(Unit *)attacker
             forTarget:(Unit *)target
            casualties:(int)casualties
    targetMoraleChange:(float)targetMoraleChange
  attackerMoraleChange:(float)attackerMoraleChange {
    self = [super init];
    if (self) {
        self.attacker = attacker;
        self.target = target;
        self.casualties = casualties;
        self.messageType = message;
        self.targetMoraleChange = targetMoraleChange;
        self.attackerMoraleChange = attackerMoraleChange;
    }

    return self;
}


- (void) execute {
    // first deliver casualties
    if ( self.target.men < self.casualties ) {
        self.target.men = 0;
    }
    else {
        self.target.men -= self.casualties;
    }
    
    NSLog( @"%@ lost %d men, now %d left, destroyed: %@", self.target, self.casualties, self.target.men, (self.messageType & kDefenderDestroyed ? @"yes" : @"no") );

    // deliver morale changes
    self.target.morale   -= self.targetMoraleChange;
    self.attacker.morale += self.attackerMoraleChange;

    // does the target already have an attack result?
    if ( self.target.attackResult ) {
        AttackResult * old = self.target.attackResult;

        // yes, old result exists, add the old result to our data
        self.casualties += old.casualties;
        self.messageType |= old.messageType;

        // get rid of the old result
        self.target.attackResult = nil;
    }
}



@end
