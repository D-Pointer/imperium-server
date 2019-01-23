
#import "CCBReader.h"

#import "OnlineTurnChanged.h"
#import "Globals.h"
#import "GameSerializer.h"


@implementation OnlineTurnChanged

+ (id) node {
    OnlineTurnChanged * node = (OnlineTurnChanged *)[CCBReader nodeGraphFromFile:@"OnlineTurnChanged.ccb"];
    
    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    // play setup music again
    [[Globals sharedInstance].audio stopMusic];
    [[Globals sharedInstance].audio playMusic:kMenuMusic];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // clear all data here
    [[Globals sharedInstance] reset];

    [[CCDirector sharedDirector] popScene];     
}


@end
