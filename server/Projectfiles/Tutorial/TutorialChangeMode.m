#import "TutorialChangeMode.h"
#import "Globals.h"
#import "MapLayer.h"

@interface TutorialChangeMode ()

@property (nonatomic, assign)   int     unitId;
@property (nonatomic, weak)   Unit *     unit;
@property (nonatomic, assign) UnitMode      mode;

@end


@implementation TutorialChangeMode

- (id) initWithUnitId:(int)unitId toMode:(UnitMode)mode {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.unitId = unitId;
        self.mode = mode;
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
    return self.unit.mode == self.mode;
}

@end
