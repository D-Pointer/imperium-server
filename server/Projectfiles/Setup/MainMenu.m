
#import <Crashlytics/Answers.h>

#import "CCBReader.h"
#import "MainMenu.h"
#import "Scenario.h"
#import "About.h"
#import "EnterName.h"
#import "CampaignSelection.h"
#import "Help.h"
#import "Globals.h"
#import "MapReader.h"
#import "Quote.h"
#import "ScenarioIndexParser.h"
#import "SelectArmy.h"
#import "GameCenter.h"

@interface MainMenu ()

@property (nonatomic, strong) CCSprite * currentPhoto;
@property (nonatomic, strong) CCScene *  sceneToPush;
@property (nonatomic, strong) CCScene *  sceneToReplace;
@property (nonatomic, strong) CCSprite * soundsImage1;
@property (nonatomic, strong) CCSprite * soundsImage2;
@property (nonatomic, strong) CCSprite * musicImage1;
@property (nonatomic, strong) CCSprite * musicImage2;
@property (nonatomic, strong) Quote *    quote;
@property (nonatomic, strong) NSArray *  quoteTexts;
@property (nonatomic, assign) int        currentQuote;

@end

@implementation MainMenu

@synthesize playPaper;
@synthesize miscPaper;
@synthesize sfxButton;
@synthesize musicButton;
@synthesize singleButton;
@synthesize multiButton;
@synthesize helpButton;
@synthesize aboutButton;

+ (id) node {
    MainMenu * node = (MainMenu *)[CCBReader nodeGraphFromFile:@"MainMenu.ccb"];

    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    [self addAnimatableNode:self.playPaper];
    [self addAnimatableNode:self.miscPaper];

    // set up the buttons
    [self createText:@"Campaign" forButton:self.singleButton];
    [self createText:@"Online" forButton:self.multiButton];
    [self createText:@"Help" forButton:self.helpButton];
    [self createText:@"About" forButton:self.aboutButton];

    self.soundsImage1 = nil;
    self.soundsImage2 = nil;
    self.musicImage1 = nil;
    self.musicImage2 = nil;
    self.quote = nil;
    [self setupAudioImages];

    // all quotes
    self.quoteTexts = @[ @"''The supreme art of war is to subdue the enemy without fighting''", @"Sun Tzu",
                         @"''Quickness is the essence of the war''", @"Sun Tzu",
                         @"''Know thy self, know thy enemy. A thousand battles, a thousand victories''", @"Sun Tzu",
                         @"''If you are far from the enemy, make him believe you are near''", @"Sun Tzu",
                         @"''He who is prudent and lies in wait for an enemy who is not, will be victorious''", @"Sun Tzu",
                         @"''Thus, what is of supreme importance in war is to attack the enemy's strategy''", @"Sun Tzu",
                         @"''Let your plans be dark and impenetrable as night, and when you move, fall like a thunderbolt''", @"Sun Tzu",
                         @"''All warfare is based on deception''", @"Sun Tzu",
                         @"''In the midst of chaos, there is also opportunity''", @"Sun Tzu",
                         @"''So in war, the way is to avoid what is strong, and strike at what is weak''", @"Sun Tzu",
                         @"''Rouse him, and learn the principle of his activity or inactivity. Force him to reveal himself, so as to find out his vulnerable spots''", @"Sun Tzu",
                         @"''Victorious warriors win first and then go to war, while defeated warriors go to war first and then seek to win''", @"Sun Tzu",

                         @"''The object of war is not to die for your country but to make the other bastard die for his''", @"George S. Patton",
                         @"''A good plan violently executed now is better than a perfect plan executed next week''", @"George S. Patton",
                         @"''A leader is a man who can adapt principles to circumstances''", @"George S. Patton",
                         @"''Success demands a high level of logistical and organizational competence''", @"George S. Patton",

                         @"''Reason and calm judgment, the qualities specially belonging to a leader''", @"Tacitus",

                         @"''No one is so brave that he is not disturbed by something unexpected''", @"Julius Caesar",

                         @"''There are no secrets to success. It is the result of preparation, hard work, and learning from failure''", @"Colin Powell",
                         ];
    //    @"''''", @"",
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) onEnter {
    [super onEnter];

    self.sceneToPush = nil;
    self.sceneToReplace = nil;

    [[Globals sharedInstance] reset];

    // we want to know when we're online or not
    [[Globals sharedInstance].tcpConnection registerDelegate:self];

    // position all nodes outside
    CGPoint playPaperFinalPos = ccp( 285, 420 );
    self.playPaper.position = ccp( -200, 300 );
    self.playPaper.rotation = 20;
    self.playPaper.scale = 2.0f;

    CGPoint miscPaperFinalPos = ccp( 785, 400 );
    self.miscPaper.position = ccp( 1300, 800 );
    self.miscPaper.rotation = -30;
    self.miscPaper.scale = 2.0f;

    // animate in them all
    [self moveNode:self.playPaper toPos:playPaperFinalPos inTime:0.5f atRate:1.5f];
    [self scaleNode:self.playPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.playPaper toAngle:-6 inTime:0.5f atRate:2.0f];

    [self moveNode:self.miscPaper toPos:miscPaperFinalPos inTime:0.5f atRate:1.2f];
    [self scaleNode:self.miscPaper toScale:1.0f inTime:0.6f];
    [self rotateNode:self.miscPaper toAngle:6.5 inTime:0.6f atRate:1.0f];

    // no scene to push yet
    self.sceneToPush = nil;

    // set up the quote
    self.quote = [Quote new];
    [self addChild:self.quote];
    [self addAnimatableNode:self.quote];

    // start from some random quote
    self.currentQuote = (int)arc4random_uniform( (u_int32_t)self.quoteTexts.count / 2 );

    // start animating images
    [self addImage];

    // start animating quotes
    [self animateQuoteInOut];

    Settings * settings = [Settings sharedInstance];

    // if the online nick has not been set then we connect to GameCenter so that we can get the player's name.
    // this should be done only once per device
    if ( settings.onlineName == nil ) {
        CCLOG( @"no online name, authenticating with Game Center to get a name" );
        [Globals sharedInstance].gameCenter = [[GameCenter alloc] initWithDelegate:self];

        // DEBUG: should we disable game center?
        if ( ! sDisableGameCenter ) {
            [[Globals sharedInstance].gameCenter authenticateLocalPlayer];
        }
    }
    else {
        // enable the online button if we can play online
        CCLOG( @"online name ok" );
        self.multiButton.visible = settings.tutorialsCompleted && [Globals sharedInstance].tcpConnection.isConnected;
    }
}


- (void) onExit {
    [super onExit];
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];
}


- (void) playSingle {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // single player game
    [Globals sharedInstance].gameType = kSinglePlayerGame;

    // the player must select the campaign
    [self animateNodesAwayAndShowScene:[CampaignSelection node]];
}


- (void) playMulti {
    Globals * globals = [Globals sharedInstance];
    [globals.audio playSound:kMenuButtonClicked];

    // show the army selection screen
    [self animateNodesAwayAndShowScene:[SelectArmy node]];
}


- (void) about {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    self.sceneToPush = [About node];
    [self animateNodesAwayWithSelector:@selector(animationsOutDone)];
}


- (void) help {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    self.sceneToPush = [Help node];
    [self animateNodesAwayWithSelector:@selector(animationsOutDone)];
}


- (void) animationsOutDone {
    // push a scene?
    if ( self.sceneToPush ) {
        [[CCDirector sharedDirector] pushScene:self.sceneToPush];
    }

    // replace?
    else if ( self.sceneToReplace ) {
        [[CCDirector sharedDirector] replaceScene:self.sceneToReplace];
    }
    else {
        NSAssert( NO, @"invalid scene" );
    }
}


- (void) toggleMusic {
    Audio * audio = [Globals sharedInstance].audio;

    // play a sound
    [audio playSound:kButtonClicked];

    if ( audio.musicEnabled ) {
        audio.musicEnabled = NO;
    }
    else {
        audio.musicEnabled = YES;
        [audio playMusic:kMenuMusic];
    }

    [self setupAudioImages];
}


- (void) toggleSfx {
    Audio * audio = [Globals sharedInstance].audio;

    // play a sound
    [audio playSound:kButtonClicked];

    // toggle sound effects
    if ( audio.soundsEnabled ) {
        audio.soundsEnabled = NO;
    }
    else {
        audio.soundsEnabled = YES;
    }

    [self setupAudioImages];
}


- (void) setupAudioImages {
    Audio * audio = [Globals sharedInstance].audio;

    // remove any old images first
    if ( self.soundsImage1 ) {
        [self.soundsImage1 removeFromParentAndCleanup:YES];
    }
    if ( self.soundsImage2 ) {
        [self.soundsImage2 removeFromParentAndCleanup:YES];
    }
    if ( self.musicImage1 ) {
        [self.musicImage1 removeFromParentAndCleanup:YES];
    }
    if ( self.musicImage2 ) {
        [self.musicImage2 removeFromParentAndCleanup:YES];
    }

    NSString * soundsFrame = audio.soundsEnabled ? @"Buttons/SoundsOn.png" : @"Buttons/SoundsOff.png";
    NSString * musicFrame  = audio.musicEnabled  ? @"Buttons/MusicOn.png" : @"Buttons/MusicOff.png";;

    // assign the buttons
    [self createImage:soundsFrame forButton:self.sfxButton];
    [self createImage:musicFrame forButton:self.musicButton];
}


- (void) addImage {
    // any old photo?
    if ( self.currentPhoto ) {
        [self.currentPhoto removeFromParentAndCleanup:YES];
        [self removeAnimatableNode:self.currentPhoto];
    }

    // load a new random photo
    int imageIndex = arc4random_uniform( 25 ) + 1;
    self.currentPhoto = [CCSprite spriteWithFile:[NSString stringWithFormat:@"Photos/%d.png", imageIndex]];

    [self addAnimatableNode:self.currentPhoto];

    // various positions
    CGPoint startPos = ccp( -300, 200 + CCRANDOM_0_1() * 100 );
    CGPoint mapPos = ccp( 250 + CCRANDOM_0_1() * 100, 80 + CCRANDOM_0_1() * 100 );
    CGPoint endPos = ccp( 200 + CCRANDOM_0_1() * 100, -300 );

    // all angles
    float startAngle = -150 + CCRANDOM_0_1() * 300;
    float mapAngle   = -15 + CCRANDOM_0_1() * 30;
    float endAngle   = -100 + CCRANDOM_0_1() * 200;

    // first position outside and scale it up
    self.currentPhoto.position = startPos;
    self.currentPhoto.rotation = startAngle;
    self.currentPhoto.scale = 2.0f;
    [self addChild:self.currentPhoto];

    [self.currentPhoto runAction:[CCSequence actions:
                                  // animate in
                                  [CCSpawn actions:
                                   [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.8 position:mapPos] rate:1.0],
                                   [CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:0.7 scale:1.0f] rate:1.0],
                                   [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.8 angle:mapAngle] rate:1.0], nil],

                                  // wait some time with the photo on the map
                                  [CCDelayTime actionWithDuration:4],

                                  // animate out
                                  [CCSpawn actions:
                                   [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.6 position:endPos] rate:1.5],
                                   [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.6 angle:endAngle] rate:2.0], nil],

                                  // next image
                                  [CCCallFunc actionWithTarget:self selector:@selector(addImage)],
                                  nil]];
}


- (void) animateQuoteInOut {
    // last one shown already?
    if ( self.currentQuote * 2 >= self.quoteTexts.count ) {
        self.currentQuote = 0;
    }

    NSString * text = self.quoteTexts[ self.currentQuote * 2 ];
    NSString * author = self.quoteTexts[ self.currentQuote * 2 + 1 ];

    //CCLOG( @"%d - %@ %@", self.currentQuote, text, author );

    [self.quote setText:text];
    [self.quote setAuthor:author];

    self.currentQuote++;

    // various positions
    CGPoint startPos = ccp( 900 + CCRANDOM_0_1() * 200, -300 );
    CGPoint mapPos = ccp( 850, 150 );
    CGPoint endPos = ccp( 1200, 50 + CCRANDOM_0_1() * 200 );

    // all angles
    float startAngle = -50 + CCRANDOM_0_1() * 100;
    float mapAngle   = -10 + CCRANDOM_0_1() * 20;
    float endAngle   = -50 + CCRANDOM_0_1() * 100;

    // first position outside and scale it up
    self.quote.position = startPos;
    self.quote.rotation = startAngle;
    self.quote.scale = 3.0f;
    [self.quote runAction:[CCSequence actions:
                           // animate in
                           [CCSpawn actions:
                            [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.6 position:mapPos] rate:1.0],
                            [CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:0.6 scale:1.0f] rate:1.0],
                            [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.5 angle:mapAngle] rate:1.0], nil],

                           // wait some time with the photo on the map
                           [CCDelayTime actionWithDuration:5],

                           // animate out
                           [CCSpawn actions:
                            [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.5 position:endPos] rate:1.5],
                            [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.5 angle:endAngle] rate:2.0], nil],

                           // next image
                           [CCCallFunc actionWithTarget:self selector:@selector(animateQuoteInOut)],
                           nil]];

}


//***************************************************************************************************************
#pragma mark - Game center delegate

- (void) playerAuthenticated:(NSString *)name {
    CCLOG( @"player is now authenticated: %@", name );

    Settings * settings = [Settings sharedInstance];

    // save the name immediately
    settings.onlineName = name;

    // enable the online button if we can play online
    self.multiButton.visible = settings.tutorialsCompleted && [Globals sharedInstance].tcpConnection.isConnected;

    // log login
    [Answers logLoginWithMethod:@"Game Center"
                        success:@YES
               customAttributes:@{ @"onlineName" : name } ];
}


//***************************************************************************************************************
#pragma mark - Online games delegate

- (void) connectedOk {
    CCLOG( @"connected ok" );

    // enable the online button if we can play online
    self.multiButton.visible = [Settings sharedInstance].tutorialsCompleted && [Globals sharedInstance].tcpConnection.isConnected;
}


- (void) connectionFailed {
    CCLOG( @"connection failed" );

    // enable the online button if we can play online
    self.multiButton.visible = [Settings sharedInstance].tutorialsCompleted && [Globals sharedInstance].tcpConnection.isConnected;
}


@end
