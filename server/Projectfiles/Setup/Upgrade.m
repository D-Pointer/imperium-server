
#import "CCBReader.h"

#import "Upgrade.h"
#import "Globals.h"


@implementation Upgrade

@synthesize backButton;

+ (id) node {
    Upgrade * node = (Upgrade *)[CCBReader nodeGraphFromFile:@"Upgrade.ccb"];
    
    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    [[CCDirector sharedDirector] popScene];     
}


@end
