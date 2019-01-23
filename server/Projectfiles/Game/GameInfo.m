
#import "CCBReader.h"

#import "GameInfo.h"
#import "Globals.h"
#import "GameLayer.h"
#import "Scenario.h"
#import "Audio.h"
#import "Engine.h"
#import "ArmyStatus.h"
#import "Utils.h"
#import "TimeCondition.h"

@implementation GameInfo

@synthesize titleLabel;
@synthesize lengthLabel;
@synthesize descriptionLabel;
@synthesize detailedButton;
@synthesize menu;

+ (GameInfo *) node {
    GameInfo * node = (GameInfo *)[CCBReader nodeGraphFromFile:@"GameInfo.ccb"];
    return node;
}


- (void) didLoadFromCCB {
    Globals * globals   = [Globals sharedInstance];
    Scenario * scenario = globals.scenario;
    //PlayerId player     = globals.localPlayer.playerId;
    
    // use the scenario as the title
    [self.titleLabel setString:scenario.title];

    BOOL timeConditionFound = NO;

    // do we have a time limit victory condition?
    for ( VictoryCondition * victoryCondition in scenario.victoryConditions ) {
        if ( [victoryCondition isKindOfClass:[TimeCondition class]] ) {
            // found one, extract the hours, minutes and seconds
            TimeCondition * timeCondition = (TimeCondition *)victoryCondition;

            int hours   = timeCondition.length / 3600;
            int minutes = ( timeCondition.length - hours * 3600 ) / 60;

            // how much time is left?
            int secondsLeft = timeCondition.length - globals.clock.elapsedTime;
            int hoursLeft   = secondsLeft / 3600;
            int minutesLeft = ( secondsLeft - hoursLeft * 3600 ) / 60;


            if ( hours > 0 ) {
                if ( secondsLeft <= 0 ) {
                    [self.lengthLabel setString:[NSString stringWithFormat:@"%d hours, %d minutes (no time left!)", hours, minutes]];
                }
                else {
                    // still time left
                    [self.lengthLabel setString:[NSString stringWithFormat:@"%d hours, %d minutes (%d:%02d left)", hours, minutes, hoursLeft, minutesLeft]];
                }
            }
            else {
                if ( secondsLeft <= 0 ) {
                    [self.lengthLabel setString:[NSString stringWithFormat:@"%d minutes (no time left!)", minutes]];
                }
                else {
                    [self.lengthLabel setString:[NSString stringWithFormat:@"%d minutes (%d:%02d left)", minutes, hoursLeft, minutesLeft]];

                }
            }

            timeConditionFound = YES;
        }
    }

    // no time condition found?
    if ( ! timeConditionFound ) {
        [self.lengthLabel setString:@"No time limit"];
    }

    [Utils createText:@"Units" forButton:self.detailedButton];

    // for the description we need to add word by word
    NSArray * words = [scenario.information componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * line = @"";
    NSMutableArray * lines = [NSMutableArray new];

    // add words to the line until the length overflows
    for ( NSString * word in words ) {
        NSString * tmp = [line stringByAppendingString:word];
        [self.descriptionLabel setString:tmp];

        // too long?
        int length = self.descriptionLabel.boundingBox.size.width;
        if ( length > 520 ) {
            // start a new line
            [lines addObject:line];
            line = [word stringByAppendingString:@" "];
        }
        else {
            // not too long yet
            line = [tmp stringByAppendingString:@" "];
        }
    }

    // add in the last half line too
    [lines addObject:line];

    // join the lines and use as the label
    [self.descriptionLabel setString:[lines componentsJoinedByString:@"\n"]];

    // set the menu to have the highest priority
    self.menu.touchPriority = kCCMenuHandlerPriority - 2;

    // we handle touches now, make sure we get *before* all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1 swallowsTouches:YES];
}


- (void) dealloc {
    CCLOG( @"in" );
    
    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CCLOG( @"in" );
    
    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        return YES;
    }

    // resume the engine
    [[Globals sharedInstance].engine resume];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // kill ourselves
    [self removeFromParentAndCleanup:YES];

    return YES;
}


- (void) showDetails {
    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // kill ourselves
    [self removeFromParentAndCleanup:YES];

    // show the army status
    CCNode * armyStatus = [ArmyStatus node];
    [[Globals sharedInstance].gameLayer addChild:armyStatus z:kArmyStatus];
}

@end
