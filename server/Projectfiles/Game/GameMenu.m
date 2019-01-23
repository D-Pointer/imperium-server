
#import "GameMenu.h"
#import "Globals.h"
#import "Unit.h"
#import "GameSerializer.h"
#import "Help.h"
#import "GameLayer.h"
#import "Utils.h"

@interface GameMenu ()

@property (nonatomic, strong) CCMenuItemSprite * menuButton;

@end


@implementation GameMenu

- (id)init {
    self = [super init];
    if (self) {
        // in game menu button
        CCSprite * normal = [CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1.png"];
        CCSprite * pressed = [CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1Pressed.png"];
        self.menuButton = [CCMenuItemSprite itemWithNormalSprite:normal selectedSprite:pressed target:self selector:@selector(menuPressed)];
        self.menuButton.position = ccp( 0, 0 );

        // set up the text
        [Utils createImage:@"Buttons/Menu.png" withYOffset:0 forButton:self.menuButton];

        CCMenu * menu = [CCMenu menuWithItems:self.menuButton, nil];        
        menu.position = ccp( 0, 0 );
        [self addChild:menu];        
    }
    
    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
}


- (void) menuPressed {
    CCLOG( @"in" );
    [[Globals sharedInstance].gameLayer showGameMenuPopup];

    // hide the actions popup if it is visible
    if ( [Globals sharedInstance].actionsMenu.visible ) {
        [[Globals sharedInstance].actionsMenu hide];
    }

    // play a sound
    [[Globals sharedInstance].audio playSound:kInGameMenuClicked];
}


@end
