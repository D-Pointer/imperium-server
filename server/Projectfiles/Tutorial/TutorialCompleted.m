
#import "TutorialCompleted.h"
#import "Scenario.h"
#import "Globals.h"

@interface TutorialCompleted ()

@property (nonatomic, weak) Scenario * scenario;

@end


@implementation TutorialCompleted

- (id) initWithScenario:(Scenario *)scenario {
    self = [super init];

    if (self) {
        self.scenario = scenario;

        self.blocks = NO;
        self.claimTouch = NO;
    }
    
    return self;    
}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    CCLOG( @"completing scenario for all campaigns: %@", self.scenario );

    // complete for all campaigns
    for ( unsigned int campaignId = 0; campaignId < 4; ++campaignId ) {
        [self.scenario setCompletedForCampaign:campaignId];
    }

    // if this is the third tutorial then we've finished all tutorials
    if ( self.scenario.scenarioId == 2 ) {
        [Settings sharedInstance].tutorialsCompleted = YES;
    }
}


- (void) cleanup {
    // nothing to do
}


- (BOOL) canProceed:(CGPoint)clickedPos {
    return YES;
}


@end
