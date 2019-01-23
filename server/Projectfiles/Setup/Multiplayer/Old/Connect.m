
#import "CCBReader.h"

#import "Connect.h"
#import "Globals.h"
#import "BonjourParameters.h"
#import "Connection.h"

@interface Connect ()

@property (nonatomic, strong) NSMutableArray * games;
@property (nonatomic, strong) NSMutableArray * labels;
@property (nonatomic, strong) BonjourClient *  bonjourClient;
@property (nonatomic, strong) CCMenu *         clientMenu;
@property (nonatomic, strong) GCDAsyncSocket * socket;

@end


@implementation Connect

@synthesize menu;
@synthesize gamesPaper;
@synthesize backButton;

+ (id) node {
    Connect * node = (Connect *)[CCBReader nodeGraphFromFile:@"Connect.ccb"];

    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    self.games = [NSMutableArray new];
    self.labels = [NSMutableArray new];
    
    // create the bonjour client
    self.bonjourClient = [[BonjourClient alloc] initWithDomain:BONJOUR_DOMAIN type:BONJOUR_TYPE];
    self.bonjourClient.delegate = self;

    // no socket yet
    self.socket = nil;

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [[CCDirector sharedDirector] popScene];     
}


- (void) gameSelected:(id)sender {
    int index = ((CCMenuItemLabel *)sender).tag;

    // find the game
    if ( index >= (int)self.games.count ) {
        // oops?
        CCLOG( @"bad index, got %d, only have %d items", index, self.games.count );
        [self createLabels];
        return;
    }

    NSNetService * selected = self.games[ index ];

    CCLOG( @"selected: %@", selected.hostName );

    // try to connect to the game
    self.socket = [self.bonjourClient connectToService:selected withDelegate:self];
}


- (void) createLabels {
    // nuke any old menu
    if ( self.clientMenu ) {
        [self.clientMenu removeFromParentAndCleanup:YES];
    }

    [self.labels removeAllObjects];

    int y = 200;
    int index = 0;

    // create new labels
    for ( NSNetService * game in self.games ) {
        // the visual label
        CCLabelBMFont * label = [CCLabelBMFont labelWithString:game.name fntFile:@"SetupFont.fnt"];

        // a menu item to hold the label
        CCMenuItemLabel * menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(gameSelected:)];
        menuLabel.position = ccp( 150, y );
        menuLabel.tag = index++;
        
        [self.labels addObject:menuLabel];
        y -= 45;
    }

    // create a new menu with all the labels
    self.clientMenu = [CCMenu menuWithArray:self.labels];
    self.clientMenu.position = ccp( 0, 0 );
    [self.gamesPaper addChild:self.clientMenu];
}


// ------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Bonjour Client Delegate

- (void) serviceFound:(NSNetService *)service {
    CCLOG( @"found: %@, %@, %@", service.type, service.domain, service.hostName );

    // save for later and update the labels
    [self.games addObject:service];
    [self createLabels];
}


- (void) serviceRemoved:(NSNetService *)service {
    NSNetService * toRemove = nil;

    // do we have such an old service at all?
    for ( NSNetService * old in self.games ) {
        if ( [old.hostName isEqualToString:service.hostName] ) {
            toRemove = old;
        }
    }

    // if we found it then remove and recreate labels
    if ( toRemove != nil ) {
        [self.games removeObject:toRemove];
        [self createLabels];
    }
}


// ------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - GCD Async Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    CCLOG( @"connected to: %@, port: %d", host, port );
    
    // create the global socket connection
    [Globals sharedInstance].connection = [[Connection alloc] initWithSocket:self.socket];

    // stop searching
    [self.bonjourClient stop];
    self.bonjourClient = nil;
}


@end
