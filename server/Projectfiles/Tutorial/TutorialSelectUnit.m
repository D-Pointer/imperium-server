
#import "TutorialSelectUnit.h"
#import "Globals.h"
#import "MapLayer.h"
#import "Unit.h"

@interface TutorialSelectUnit ()

@property (nonatomic, assign) int unitId;

@end


@implementation TutorialSelectUnit

- (id) init {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.unitId = -1;
    }
    
    return self;    
}


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
    //[Globals sharedInstance].selection.selectedUnit = nil;
}


- (void) cleanup {
    // nothing to do
}


- (BOOL) canProceed {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    if ( selected == nil ) {
        return NO;
    }

    if ( self.unitId != -1 && self.unitId != selected.unitId ) {
        return NO;
    }

    return YES;
}

@end
