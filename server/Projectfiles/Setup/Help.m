
#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "Help.h"
#import "Globals.h"
#import "Engine.h"

@interface Help ()

@property (nonatomic, strong) UIWebView * webView;

@end


@implementation Help

@synthesize helpPaper;
@synthesize topicsPaper;
@synthesize topicsMenu;
@synthesize backButton;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"Help.ccb"];
}


+ (CCScene *) inGameNode {
    Help * help = (Help *)[CCBReader nodeGraphFromFile:@"Help.ccb"];
    help.inGameHelp = YES;

    // embed in a scene
    CCScene * scene = [CCScene new];
    [scene addChild:help];
    return scene;
}


- (id) init {
    self = [super init];
    if (self) {
        // by default not in the game
        self.inGameHelp = NO;
    }
    return self;
}


- (void) didLoadFromCCB {
    // create the web view and have it fill most of the screen
    self.webView = [[UIWebView alloc] init];
    self.webView.frame = CGRectMake( 320, 230, 560, 475 );
    self.webView.transform = CGAffineTransformRotate([self.webView transform], CC_DEGREES_TO_RADIANS( 3 ) );
    [[Globals sharedInstance].appDelegate.navController.view addSubview:self.webView];

    // make it transparent
    [self.webView setBackgroundColor:[UIColor clearColor]];
    [self.webView setOpaque:NO];
    self.webView.hidden = YES;

    // no bouncing past the top
    self.webView.scrollView.bounces = NO;
    [self showPage:@"index.html"];

    NSArray * titles = @[ @"Overview", @"Game Modes", @"Map", @"Units", @"Missions", @"Combat", @"Tactics", @"World History" ];

    int y = 230;
    for ( unsigned int index = 0; index < titles.count; ++index ) {
        // the visual label
        CCLabelBMFont * label = [CCLabelBMFont labelWithString:titles[index] fntFile:@"SetupFont.fnt"];

        // a menu item to hold the label
        CCMenuItemLabel * menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(showTopic:)];
        menuLabel.position = ccp( 25, y );
        menuLabel.anchorPoint = ccp( 0, 0.5 );
        menuLabel.tag = index;

        y -= 28;
        
        [self.topicsMenu addChild:menuLabel];
    }

    // position all nodes outside
    self.topicsPaper.position = ccp( -300, 300 );
    self.topicsPaper.rotation = 20;
    self.topicsPaper.scale = 2.0f;

    self.helpPaper.position = ccp( 1800, 200 );
    self.helpPaper.rotation = -20;
    self.helpPaper.scale = 1.8f;

    // animate in them all
    [self moveNode:self.topicsPaper toPos:ccp(150, 400) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.topicsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.topicsPaper toAngle:-4 inTime:0.5f atRate:2.0f];

    [self moveNode:self.helpPaper toPos:ccp(600, 300) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.helpPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.helpPaper toAngle:3.0f inTime:0.5f atRate:2.0f];

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];

    // in 1s the scene is done, call the given selector
    [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector(showFirstPage) forTarget:self interval:2.0f repeat:0 delay:0 paused:NO];

    // these can be animated
    [self addAnimatableNode:self.topicsPaper];
    [self addAnimatableNode:self.helpPaper];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) close {
    // get rid of the web view
    self.webView.hidden = YES;
    [self.webView removeFromSuperview];
    self.webView = nil;

    // disable back button
    [self disableBackButton:self.backButton];

    // resume the engine if we're in a game
    if ( self.inGameHelp ) {
        [[Globals sharedInstance].engine resume];
    }
    
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) animationsDone {
    // back was pressed, just pop this off
    [[CCDirector sharedDirector] popScene];
}


- (void) showTopic:(id)sender {
    NSString * page = nil;

    switch ( ((CCMenuItemLabel *)sender).tag ) {
        case 0:
            page = @"index.html";
            break;

        case 1:
            page = @"game-modes.html";
            break;

        case 2:
            page = @"map.html";
            break;

        case 3:
            page = @"units.html";
            break;

        case 4:
            page = @"movement.html";
            break;

        case 5:
            page = @"combat.html";
            break;

        case 6:
            page = @"tips-tricks.html";
            break;

        case 7:
            page = @"history.html";
            break;
    }

    NSAssert( page, @"invalid page requested!" );

    [self showPage:page];
}


- (void) showFirstPage {
    self.webView.hidden = NO;
}


- (void) showPage:(NSString *)filename {
    // load the HTML
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * helpDir = [[paths objectAtIndex:0] stringByAppendingString:@"/Help/"];
    NSString * html = [NSString stringWithContentsOfFile:[helpDir stringByAppendingString:filename]
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];

    // is this a retina enabled device?
    if ( fabs( CC_CONTENT_SCALE_FACTOR() - 2 ) < 0.1 ) {
        // retina
        html = [html stringByReplacingOccurrencesOfString:@".png" withString:@"-hd.png"];
    }

    // assign the HTML and thus show the page
    NSURL * baseUrl = [NSURL URLWithString:helpDir];
    [self.webView loadHTMLString:html baseURL:baseUrl];

    [Answers logContentViewWithName:@"Show help"
                        contentType:@"Manual"
                          contentId:filename
                   customAttributes:nil];
}

@end
