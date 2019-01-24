
#import "DestroyUnitCondition.h"
#import "Globals.h"
#import "Scenario.h"

@interface DestroyUnitCondition ()

@property (nonatomic, weak) Unit * unit;

@end

@implementation DestroyUnitCondition

- (instancetype) initWithUnitId:(int)unitId {
    self = [super init];
    if (self) {
        self.unitId = unitId;
        self.unit = nil;
    }

    return self;
}


- (void) setup {
    for ( Unit * tmp in [Globals sharedInstance].units ) {
        if ( tmp.unitId == self.unitId ) {
            self.unit = tmp;
            break;
        }
    }

    NSAssert( self.unit != nil, @"did not find unit" );
}


- (ScenarioState) check {
    if ( self.unit.destroyed ) {
        self.winner = kPlayer1;
        self.text = [NSString stringWithFormat:@"Scenario completed! The target unit %@ has been destroyed.", self.unit.name];
        return kGameFinished;
    }

    // not yet destroyed
    return kGameInProgress;
}

@end
