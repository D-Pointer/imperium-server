
#import "UnitToggleAutoFire.h"
#import "Globals.h"
#import "Utils.h"

@interface UnitToggleAutoFire ()

@property (nonatomic, strong) CCMenuItemSprite * fireButton;
@property (nonatomic, strong) CCMenu *           menu;

@end


@implementation UnitToggleAutoFire

- (id)init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:NotificationSelectionChanged object:nil];


        // fire/hold fire button
        self.fireButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall3.png"]
                                                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall3Pressed.png"]
                                                          target:self
                                                        selector:@selector(toggleAutoFire)];
        self.fireButton.position = ccp( 0, 0 );
        [Utils createImage:@"Buttons/AutoFireOn.png" withYOffset:0 forButton:self.fireButton];

        // create an empty menu
        self.menu = [CCMenu menuWithItems:self.fireButton, nil];
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


- (void) toggleAutoFire {
    CCLOG(@"in");

    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    Globals * globals = [Globals sharedInstance];

    [globals.audio playSound:kActionClicked];

    Unit * selectedUnit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selectedUnit != nil && selectedUnit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );

    if ( selectedUnit.autoFireEnabled ) {
        // disable it
        selectedUnit.autoFireEnabled = NO;
        [Utils createImage:@"Buttons/AutoFireOff.png" withYOffset:0 forButton:self.fireButton];
    }
    else {
        // enable
        selectedUnit.autoFireEnabled = YES;
        [Utils createImage:@"Buttons/AutoFireOn.png" withYOffset:0 forButton:self.fireButton];
    }
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // any current unit or enemy?
    if ( selectedUnit == nil || selectedUnit.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // no unit, missions or enemy
        [self fadeOut];
        return;
    }

    // set up the auto fire button
    NSString * iconName = selectedUnit.autoFireEnabled ? @"Buttons/AutoFireOn.png" : @"Buttons/AutoFireOff.png";
    [Utils createImage:iconName withYOffset:0 forButton:self.fireButton];

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
