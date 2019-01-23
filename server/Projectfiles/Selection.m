
#import "Selection.h"
#import "Unit.h"

@implementation Selection

- (id)init {
    self = [super init];
    if (self) {
        self.selectedUnit = nil;
    }
    
    return self;
}


- (void) setSelectedUnit:(Unit *)unit {
    // don't select the same unit twice
    if ( unit == _selectedUnit ) {
        return;
    }

    Unit * oldSelected = _selectedUnit;

    _selectedUnit = unit;

    // any old selected unit?
    if ( oldSelected != nil ) {
        oldSelected.selected = NO;
    }

    if ( unit ) {
        unit.selected = YES;
        CCLOG( @"selecting: %@", unit );
    }
    else {
        CCLOG( @"clearing selection" );
    }
    
    // notify the world
    [[NSNotificationCenter defaultCenter] postNotificationName:sNotificationSelectionChanged object:nil ];
}


- (void) reset {
    self.selectedUnit = nil;
}

@end
