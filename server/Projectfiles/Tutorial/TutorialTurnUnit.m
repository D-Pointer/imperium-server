#import "TutorialTurnUnit.h"
#import "Globals.h"
#import "MapLayer.h"

@interface TutorialTurnUnit ()

@property (nonatomic, assign) int    unitId;
@property (nonatomic, weak)   Unit * unit;
@property (nonatomic, assign) float  deviation;
@property (nonatomic, assign) float  angle;

@end


@implementation TutorialTurnUnit

- (id) initWithUnitId:(int)unitId toAngle:(float)angle deviation:(float)deviation {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.unitId = unitId;
        self.deviation = deviation;
        self.angle = angle;
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


- (void) cleanup {
}


- (BOOL) canProceed {
    // NOTE: this does not work around angle == 0
    return fabs( self.unit.rotation - self.angle ) < self.deviation;
}

@end
