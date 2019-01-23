
#import "CCBReader.h"

#import "WaitDeployment.h"
#import "Globals.h"

@implementation WaitDeployment

@synthesize messagePaper;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"WaitDeployment.ccb"];
}


- (void) didLoadFromCCB {

}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.messagePaper.position = ccp( -300, 100 );
    self.messagePaper.rotation = -50;
    self.messagePaper.scale = 2.0f;

    // animate in
    [self moveNode:self.messagePaper toPos:ccp(505, 400) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.messagePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.messagePaper toAngle:3 inTime:0.5f atRate:0.5f];

    // these can be animated
    [self addAnimatableNode:self.messagePaper];

    // after 1s start checking the opponent
    [self scheduleOnce:@selector(startChecking) delay:1];
}


- (void) startChecking {
    // send a probe at regular short intervals
    [self schedule:@selector(checkIfGameCanStart) interval:0.2];
}


- (void) checkIfGameCanStart {
    // tell the other player we're ready
    [[Globals sharedInstance].connection sendMessage:kDeploymentReady];

    // is the other player already done?
    if ( [Globals sharedInstance].connection.otherPlayerReady ) {
        // the other player is ready and waiting for us

        // send a few pings
        for ( int index = 0; index < 5; ++index ) {
            [[Globals sharedInstance].connection sendMessage:kPingMessage withInt:index];
        }

        CCLOG( @"other player is ready, we can start the game" );
        [Globals sharedInstance].connection.onlineState = kPlaying;
    }
}

@end
