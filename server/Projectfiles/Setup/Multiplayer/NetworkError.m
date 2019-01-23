
#import "CCBReader.h"

#import "NetworkError.h"
#import "Globals.h"
#import "Engine.h"
#import "Utils.h"
#import "UdpNetworkHandler.h"

@interface NetworkError ()

@property (nonatomic, strong) CCScene * backScene;
@end


@implementation NetworkError

@synthesize errorLabel;
@synthesize backButton;
@synthesize errorPaper;

+ (id) nodeWithMessage:(NSString *)message backScene:(CCScene *)backScene {
    NetworkError * node = (NetworkError *)[CCBReader nodeGraphFromFile:@"NetworkError.ccb"];
    [node.errorLabel setString:message];

    node.backScene = backScene;

    // nicely wrap the text
    [Utils showString:message onLabel:node.errorLabel withMaxLength:260];

    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    Globals * globals = [Globals sharedInstance];

    // stop the engine
    [globals.engine stop];

    // shut down the UDP connection
    if ( globals.udpConnection ) {
        [globals.udpConnection disconnect];
        globals.udpConnection = nil;
    }

    // shut down
//    if ( globals.tcpConnection) {
//        [globals.tcpConnection disconnect];
//        globals.tcpConnection = nil;
//    }
    
    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];

    // position all nodes outside
    self.errorPaper.position = ccp( 700, -200 );
    self.errorPaper.rotation = 50;
    self.errorPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.errorPaper toPos:ccp(512, 400) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.errorPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.errorPaper toAngle:2 inTime:0.5f atRate:0.5f];

    // the paper is animated out
    [self addAnimatableNode:self.errorPaper];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    // play setup music again
    [[Globals sharedInstance].audio stopMusic];
    [[Globals sharedInstance].audio playMusic:kMenuMusic];


    // we're done
    [self animateNodesAwayAndShowScene:self.backScene];
}


@end
