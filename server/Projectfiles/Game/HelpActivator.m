
#import "HelpActivator.h"
#import "GameLayer.h"
#import "Globals.h"
#import "Utils.h"
#import "HelpOverlay.h"

@interface HelpActivator ()

@property (nonatomic, strong) CCMenuItemSprite * button;
@property (nonatomic, strong) CCMenu *           menu;
@end


@implementation HelpActivator

- (id) init {
    self = [super init];
    if (self) {
        self.button = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2.png"]
                                              selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2Pressed.png"]
                                                      target:self
                                                    selector:@selector(showHelpOverlay)];

        [Utils createImage:@"Buttons/Help.png" withYOffset:0 forButton:self.button];


        self.menu = [CCMenu menuWithItems:self.button, nil];
        self.menu.position = ccp( 0, 0 );
        [self addChild:self.menu];
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) showHelpOverlay {
    CCLOG( @"in" );

    HelpOverlay * popup = [HelpOverlay node];
    [[Globals sharedInstance].gameLayer addChild:popup z:kHelpOverlayZ];
}

@end
