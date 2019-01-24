
#import "InfluenceMapContainer.h"
#import "Globals.h"
#import "GameLayer.h"

@interface InfluenceMapContainer ()

@property (nonatomic, assign) BOOL      initialized;
@property (nonatomic, strong) NSArray * debugSprites;

@end

@implementation InfluenceMapContainer

- (id) init {
    self = [super init];
    if (self) {
        self.initialized = NO;
        self.debugSprites = nil;
    }

    return self;
}



- (void) updateMaps {
    // do this here, as if we do it in init() then we deadlock the Globals initialization
    if ( ! self.initialized ) {
        // which player is the AI player? it should get the first unit strength map
        PlayerId aiPlayer    = [Globals sharedInstance].player1.type == kAIPlayer ? kPlayer1 : kPlayer2;
        PlayerId humanPlayer = [Globals sharedInstance].player1.type == kAIPlayer ? kPlayer2 : kPlayer1;

        NSAssert( aiPlayer != humanPlayer, @"Bad player ids" );

        // create all the maps
        self.aiStrength       = [[UnitStrengthMap alloc] initForPlayer:aiPlayer withTitle:@"AI"];
        self.humanStrength    = [[UnitStrengthMap alloc] initForPlayer:humanPlayer withTitle:@"Human"];
        self.influenceMap     = [[InfluenceMap alloc] initWithAI:self.aiStrength human:self.humanStrength];
        self.frontlineMap     = [[FrontlineMap alloc] initWithInfluenceMap:self.influenceMap];
        //self.tensionMap       = [[TensionMap alloc] initWithAI:self.aiStrength human:self.humanStrength];
        //self.vulnerabilityMap = [[VulnerabilityMap alloc] initWithTension:self.tensionMap influence:self.influenceMap];
        //self.objectivesMap    = [[ObjectivesMap alloc] init];

        self.initialized = YES;
    }

    // update all the maps
    [self.aiStrength update];
    [self.humanStrength update];
    [self.influenceMap update];
    [self.frontlineMap update];
    //[self.tensionMap update];
    //[self.vulnerabilityMap update];
    //[self.objectivesMap update];
}



- (void) showDebugInfo {
    if ( ! sCreateDebugMaps ) {
        return;
    }

    if (self.debugSprites != nil ) {
        // get rid of all the old maps
        for ( CCSprite * mapDebug in self.debugSprites ) {
            [mapDebug removeFromParentAndCleanup:YES];
        }

        self.debugSprites = nil;
    }

    // create or recreate all maps
    self.debugSprites = [NSArray arrayWithObjects:
                         [self.aiStrength createSprite],
                         [self.humanStrength createSprite],
                         [self.influenceMap createSprite],
                         [self.frontlineMap createSprite],
                         //[self.maps.tensionMap createSprite],
                         //[self.maps.vulnerabilityMap createSprite],
                         //[self.maps.objectivesMap createSprite],
                         nil];

    int x = 75;
    int y = 20;
    for ( CCSprite * mapDebug in self.debugSprites ) {
        mapDebug.anchorPoint = ccp( 0, 0 );
        mapDebug.position = ccp( x, y );
        [[Globals sharedInstance].gameLayer addChild:mapDebug z:kAIDebugZ];

        y += mapDebug.boundingBox.size.height + 10;
    }
}


@end
