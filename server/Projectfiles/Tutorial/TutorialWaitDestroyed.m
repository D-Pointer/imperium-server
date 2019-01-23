#import "TutorialWaitDestroyed.h"
#import "Globals.h"

@interface TutorialWaitDestroyed ()

@property (nonatomic, assign)   int     unitId;
@property (nonatomic, weak)   Unit *     unit;

@end


@implementation TutorialWaitDestroyed

- (id) initWithUnitId:(int)unitId {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.unitId = unitId;
    }

    return self;
}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    // find the unit
    for ( Unit * unit in [Globals sharedInstance].units ) {
        if ( unit.unitId == self.unitId ) {
            self.unit = unit;
        }
    }

    NSAssert( self.unit, @"unit not found!" );
}


- (BOOL) canProceed {
    // destroyed yet?
    return self.unit.destroyed;
}

@end
