
#import "FirstTurn.h"
#import "Clock.h"

@interface FirstTurn ()

@property (nonatomic, assign) BOOL isFirstTurn;

@end

@implementation FirstTurn

- (instancetype) init {
    self = [super init];
    if (self) {
        self.isFirstTurn = YES;
    }

    return self;
}


- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    if ( self.isFirstTurn ) {
        self.isFirstTurn = NO;
        return YES;
    }

    return NO;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactAttack grade:0.6f];
    [system retractFact:FactHold grade:0.2f];
}


@end
