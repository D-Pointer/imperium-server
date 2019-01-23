
#import "UnitChangeMode.h"
#import "Globals.h"
#import "ChangeModeMission.h"
#import "Utils.h"

@interface UnitChangeMode ()

@property (nonatomic, strong) CCMenuItemSprite * changeModeButton;
@property (nonatomic, strong) CCMenu *           menu;

@end


@implementation UnitChangeMode

- (id)init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:NotificationSelectionChanged object:nil];

        // our single button
        self.changeModeButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2.png"]
                                                        selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2Pressed.png"]
                                                                target:self
                                                              selector:@selector(changeMode)];

        [Utils createImage:@"Buttons/ChangeMode.png" withYOffset:0 forButton:self.changeModeButton];

        // create an empty menu
        self.menu = [CCMenu menuWithItems:self.changeModeButton, nil];
        self.menu.position = ccp( 0, 0 );
        [self addChild:self.menu];

        // not visible by default
        self.menu.opacity = 0;
        self.menu.visible = NO;
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) changeMode {
    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    [[Globals sharedInstance].audio playSound:kActionClicked];

    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // for the deployment mode just set the mode directly
    if ( [Globals sharedInstance].deplymentMode ) {
        if ( selectedUnit.mode == kFormation ) {
            selectedUnit.mode = kColumn;
        }
        else {
            selectedUnit.mode = kFormation;
        }

        return;
    }

    // can the unit be given missions?
    if ( ! selectedUnit.canBeGivenMissions ) {
        CCLOG( @"can not be given missions" );
        return;
    }

    // check if the last mission is already a change mode. if so, we're done
    if ( selectedUnit.mission && [selectedUnit.mission isKindOfClass:[ChangeModeMission class]] ) {
        CCLOG( @"already changing mode" );
        return;
    }

    // set a new mission
    selectedUnit.mission = [[ChangeModeMission alloc] initWithUnit:selectedUnit];
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // any current unit or enemy?
    if ( selectedUnit == nil || selectedUnit.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // no unit, missions or enemy
        [self fadeOut];
        return;
    }

    if ( ! [selectedUnit canBeGivenMissions] ) {
        CCLOG( @"unit can't be given missions" );
        [self fadeOut];
        return;
    }

    // show ourselves
    [self fadeIn];
}



- (void) fadeOut {
    if ( self.menu.opacity <= 0.05f ) {
        return;
    }

    // cancel any actions running and then fade out
    [self.menu stopAllActions];
    [self.menu runAction:[CCSequence actions:
                          [CCFadeOut actionWithDuration:0.3f],
                          [CCCallFuncN actionWithTarget:self selector:@selector(hide)], nil]];
}


- (void) fadeIn {
    if ( self.menu.opacity >= 0.95f ) {
        return;
    }

    self.menu.visible = YES;
    self.menu.opacity = 0;

    // cancel any actions running and then fade out
    [self.menu stopAllActions];
    [self.menu runAction:[CCFadeIn actionWithDuration:0.4f]];
}


- (void) hide {
    CCLOG( @"in" );
    self.menu.visible = NO;
}



@end
