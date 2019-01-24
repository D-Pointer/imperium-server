
#import "Input.h"
#import "Globals.h"
#import "MapLayer.h"
#import "Objective.h"
#import "Path.h"

@implementation Input

- (id) init {
    self = [super init];
    if (self) {
    }

    return self;
}


- (void) handleClickedUnit:(Unit *)clicked {
    // nothing to do
}


- (void) handleClickedObjective:(Objective *)objective {
    // if we have a unit selected then we instead see it as if the position was clicked so that movement can
    // take place normally
    Unit * selected_unit = [Globals sharedInstance].selection.selectedUnit;
    if ( selected_unit && selected_unit.owner == [Globals sharedInstance].localPlayer.playerId ) {
        [self handleClickedPos:objective.position];
        return;
    }
}


- (void) handleClickedPos:(CGPoint)pos {
    // nothing to do
}


- (void) handleDragStartForUnit:(Unit *)unit {
    // nothing to do
}


- (BOOL) handleDragForUnit:(Unit *)unit toPos:(CGPoint)pos {
    return NO;
}


- (void) handleDragEndForUnit:(Unit *)unit {
    // nothing to do
}


@end
