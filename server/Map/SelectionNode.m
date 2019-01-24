
#import "SelectionNode.h"
#import "Globals.h"
#import "Unit.h"

@implementation SelectionNode

- (id)init {
    self = [super init];
    if (self) {
        // hidden by default
        self.visible = NO;
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"SelectionNode.dealloc" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    [self updatePosition];
}


- (void) updatePosition {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // any current unit?
    if ( selected == nil || ! selected.visible ) {
        // no unit or enemy or the selected unit is no longer visible
        self.visible = NO;
        [self stopAllActions];
        return;
    }

    if ( self.visible == NO ) {
        // show ourselves
        self.visible = YES;

        // animate a bit
        [self animate];
    }

    self.position = selected.position;

    // unit sprite size is used to scale this not to fit the unit marker
    float size = MAX( selected.boundingBox.size.width, selected.boundingBox.size.height );
    self.scale = size / 120.0f;
}


- (void) animate {
    [self stopAllActions];

    // scale up and down
    [self runAction:[CCRepeatForever actionWithAction:
                     [CCSequence actions:
                      [CCTintTo actionWithDuration:0.8 red:255 green:255 blue:255],
                      [CCTintTo actionWithDuration:0.8 red:180 green:180 blue:180],
                      nil]]];
}


+ (SelectionNode *) create {
    SelectionNode * node = [SelectionNode spriteWithSpriteFrameName:@"SelectedUnitHighlight.png"];

    // we want to know when the selected unit changes
    [[NSNotificationCenter defaultCenter] addObserver:node selector:@selector(selectedUnitChanged:) name:NotificationSelectionChanged object:nil];

    // hidden by default
    node.visible = NO;

    //node->mode = kFormation;
    return node;
}

@end
