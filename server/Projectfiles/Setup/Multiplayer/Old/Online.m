
#import "CCBReader.h"

#import "Online.h"
#import "Globals.h"

@implementation Online


- (void) didLoadFromCCB {
    // nothing to do
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [[CCDirector sharedDirector] popScene];     
}


+ (id) node {
    Online * node = (Online *)[CCBReader nodeGraphFromFile:@"Online.ccb"];

    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}

@end
