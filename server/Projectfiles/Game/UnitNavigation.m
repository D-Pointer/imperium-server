
#import "UnitNavigation.h"
#import "GameLayer.h"
#import "Globals.h"
#import "Unit.h"
#import "ChangeModeMission.h"
#import "Utils.h"

@interface UnitNavigation ()

@property (nonatomic, strong) CCMenuItemSprite * nextButton;
@property (nonatomic, strong) CCMenuItemSprite * previousButton;
@property (nonatomic, strong) CCMenuItemSprite * hqButton;
@property (nonatomic, strong) CCMenuItemSprite * findButton;
@property (nonatomic, strong) CCMenu *           menu;

@end


@implementation UnitNavigation

@synthesize nextButton;
@synthesize previousButton;
@synthesize hqButton;

- (id)init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:NotificationSelectionChanged object:nil];

        // find unit button
        self.findButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1.png"]
                                                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1Pressed.png"]
                                                          target:self
                                                        selector:@selector(findUnit)];
        self.findButton.position = ccp( 0, 105 );
        [Utils createImage:@"Buttons/Find.png" withYOffset:0 forButton:self.findButton];

        // next unit button
        self.nextButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2.png"]
                                                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2Pressed.png"]
                                                          target:self 
                                                        selector:@selector(nextUnit)];
        self.nextButton.position = ccp( 0, 35 );
        [Utils createImage:@"Buttons/Next.png" withYOffset:0 forButton:self.nextButton];

        // previous unit button
        self.previousButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall3.png"]
                                                      selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall3Pressed.png"]
                                                              target:self 
                                                            selector:@selector(previousUnit)];
        self.previousButton.position = ccp( 0, -35 );
        [Utils createImage:@"Buttons/Previous.png" withYOffset:0 forButton:self.previousButton];

        // hq unit button
        self.hqButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1.png"]
                                                selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1Pressed.png"]
                                                        target:self
                                                      selector:@selector(activateHq)];
        self.hqButton.position = ccp( 0, -105 );
        [Utils createImage:@"Buttons/HQ.png" withYOffset:0 forButton:self.hqButton];

        self.menu = [CCMenu menuWithItems:self.findButton, self.nextButton, self.previousButton, self.hqButton, nil];
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


- (void) selectedUnitChanged:(NSNotification *) notification {
    Player * player = [Globals sharedInstance].localPlayer;
    
    Unit * selected_unit = [Globals sharedInstance].selection.selectedUnit;
        
    // any current unit or enemy?
    if ( selected_unit == nil || selected_unit.owner != player.playerId ) {
        // no unit or enemy
        [self fadeOut];
        return;
    }
    
    // does it have a headquarter?
    self.hqButton.visible = selected_unit.headquarter != nil;

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
    self.menu.visible = NO;
}


- (void) nextUnit {
    CCLOG( @"in" );
    Globals * globals = [Globals sharedInstance];

    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selected_unit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selected_unit != nil && selected_unit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );

    // the own units
    CCArray * own = selected_unit.owner == kPlayer1 ? globals.unitsPlayer1 : globals.unitsPlayer2;

    // index of the selected unit
    NSUInteger index = [own indexOfObject:selected_unit];
    Unit * found = nil;

    while ( found == nil ) {
        if ( ++index == own.count ) {
            index = 0;
        }

        Unit * check = [own objectAtIndex:index];

        // did we loop around and got to our start unit?
        if ( check == selected_unit ) {
            break;
        }

        // destroyed?
        if ( check.destroyed ) {
            continue;
        }

        found = check;
    }
    
    if ( found != nil ) {
        // set a new selected unit
        globals.selection.selectedUnit = found;

        // center the map on it
        [globals.gameLayer centerMapOn:globals.selection.selectedUnit];
    }
}


- (void) previousUnit {
    CCLOG( @"in" );

    Globals * globals = [Globals sharedInstance];

    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selected_unit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;
    
    NSAssert( selected_unit != nil && selected_unit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );
    
    // the own units
    CCArray * own = selected_unit.owner == kPlayer1 ? globals.unitsPlayer1 : globals.unitsPlayer2;

    // index of the selected unit
    NSUInteger index = [own indexOfObject:selected_unit];
    Unit * found = nil;

    while ( found == nil ) {
        if ( index == 0 ) {
            index = own.count - 1;
        }
        else {
            index--;
        }

        Unit * check = [own objectAtIndex:index];

        // did we loop around and got to our start unit?
        if ( check == selected_unit ) {
            break;
        }

        // destroyed?
        if ( check.destroyed ) {
            continue;
        }
        
        found = check;
    }

    if ( found != nil ) {
        // set a new selected unit
        globals.selection.selectedUnit = found;

        // center the map on it
        [globals.gameLayer centerMapOn:globals.selection.selectedUnit];
    }
}


- (void) activateHq {
    CCLOG( @"in" );

    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selected_unit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;
    
    NSAssert( selected_unit != nil && selected_unit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );
    
    // does it have a hq?
    Unit * hq = selected_unit.headquarter;
    if ( hq ) {
        globals.selection.selectedUnit = hq;

        // center the map on it
        [globals.gameLayer centerMapOn:hq];
    }
}


- (void) findUnit {
    CCLOG( @"in" );

    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selectedUnit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selectedUnit != nil && selectedUnit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );
    
    // center the map on it
    [globals.gameLayer centerMapOn:selectedUnit];
}

@end
