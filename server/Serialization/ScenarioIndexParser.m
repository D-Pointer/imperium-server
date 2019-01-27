
#import <Crashlytics/Answers.h>

#import "ScenarioIndexParser.h"
#import "Scenario.h"

#import "TimeCondition.h"
#import "CasualtiesCondition.h"
#import "HoldAllObjectivesCondition.h"
#import "DestroyUnitCondition.h"
#import "EscortUnitCondition.h"
#import "TutorialCondition.h"
#import "MultiplayerTimeCondition.h"
#import "MultiplayerCasualtiesCondition.h"
#import "Globals.h"
#import "ResourceHandler.h"

@interface ScenarioIndexParser ()

@property (nonatomic, strong) Scenario * scenario;

@end


@implementation ScenarioIndexParser

- (BOOL) parseScenarioIndexFile {
    NSLog( @"loading scenario index file" );

    // read everything and split into lines
    NSString * contents = [ResourceHandler loadResource:@"Scenarios/Index.txt"];
    if ( contents == nil ) {
        return NO;
    }
    
    NSArray * lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    NSLog( @"read %lu lines", (unsigned long)lines.count );

    Globals * globals = [Globals sharedInstance];
    int tutorialCount = 0, scenarioCount = 0;

    for ( NSString * line in lines ) {
        NSArray* parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString * type = parts[0];

        if ( [type isEqualToString:@"size"] ) {
            // start a new scenario
            self.scenario = [Scenario new];
            [self parseSize:parts];
        }

        else if ( [type isEqualToString:@"time"] ) {
            [self parseTime:parts];
        }

        else if ( [type isEqualToString:@"id"] ) {
            self.scenario.scenarioId = [parts[1] intValue];
        }

        else if ( [type isEqualToString:@"depend"] ) {
            [self parseDepends:parts];
        }

        else if ( [type isEqualToString:@"title"] ) {
            [self parseTitle:parts];
        }

        else if ( [type isEqualToString:@"type"] ) {
            [self parseScenarioType:parts];

            // now set up the filename
            if ( self.scenario.scenarioType == kMultiplayer ) {
                self.scenario.filename = [NSString stringWithFormat:@"Scenarios/Multiplayer/%d.map", self.scenario.scenarioId];
            }
            else {
                self.scenario.filename = [NSString stringWithFormat:@"Scenarios/Singleplayer/%d.map", self.scenario.scenarioId];
            }
        }

        else if ( [type isEqualToString:@"aihint"] ) {
            [self parseAIHint:parts];
        }

        else if ( [type isEqualToString:@"battlesize"] ) {
            [self parseBattleSize:parts];
        }

        else if ( [type isEqualToString:@"desc"] ) {
            [self parseDescription:parts];
        }

        else if ( [type isEqualToString:@"victory"] ) {
            [self parseVictoryCondition:parts];
        }

        else if ( [type isEqualToString:@""] && self.scenario ) {
            // empty line, we're done with this scenario
            if ( self.scenario.scenarioType == kTutorial ) {
                [globals.scenarios insertObject:self.scenario atIndex:0];
                NSLog( @"parsed tutorial: %@", self.scenario );
                tutorialCount++;
            }
            else {
                [globals.scenarios addObject:self.scenario];
                NSLog( @"parsed scenario: %@", self.scenario );
                scenarioCount++;
            }

            self.scenario = nil;
        }

        else {
            // unknown line
            NSLog( @"invalid line in scenario index file: '%@'", line );

            // nothing we want, we're done
            break;
        }
    }

    NSLog( @"parsed %d scenarios and %d tutorials", scenarioCount, tutorialCount );

    // parsed ok
    return YES;
}


- (void) parseSize:(NSArray *)parts {
    self.scenario.width  = [parts[1] intValue];
    self.scenario.height = [parts[2] intValue];
}


- (void) parseDepends:(NSArray *)parts {
    self.scenario.dependsOn = [parts[1] intValue];
}


- (void) parseTime:(NSArray *)parts {
    self.scenario.startTime = [parts[1] intValue] * 3600 + [parts[2] intValue] * 60;
}


- (void) parseScenarioType:(NSArray *)parts {
    self.scenario.scenarioType = (ScenarioType)[parts[1] intValue];
}


- (void) parseAIHint:(NSArray *)parts {
    self.scenario.aiHint = (AIHint)[parts[1] intValue];
}


- (void) parseBattleSize:(NSArray *)parts {
    self.scenario.battleSize = (BattleSizeType)[parts[1] intValue];
}


- (void) parseTitle:(NSArray *)parts {
    NSMutableArray * title_parts = [NSMutableArray arrayWithArray:parts];
    [title_parts removeObjectAtIndex:0];
    self.scenario.title = [title_parts componentsJoinedByString:@" "];
}


- (void) parseDescription:(NSArray *)parts {
    NSMutableArray * desc_parts = [NSMutableArray arrayWithArray:parts];
    [desc_parts removeObjectAtIndex:0];
    self.scenario.information = [[desc_parts componentsJoinedByString:@" "] stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
}


- (void) parseVictoryCondition:(NSArray *)parts {
    // victory time 60
    // victory casualty 75
    // victory hold 0 600
    // victory destroy 10
    NSString * type = parts[1];
    if ( [type isEqualToString:@"time"] ) {
        int length = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[TimeCondition alloc] initWithLength:length]];
    }
    else if ( [type isEqualToString:@"multiplayertime"] ) {
        int length = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[MultiplayerTimeCondition alloc] initWithLength:length]];
    }
    else if ( [type isEqualToString:@"casualty"] ) {
        int percentage = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[CasualtiesCondition alloc] initWithPercentage:percentage]];
    }
    else if ( [type isEqualToString:@"multiplayercasualty"] ) {
        int percentage = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[MultiplayerCasualtiesCondition alloc] initWithPercentage:percentage]];
    }
    else if ( [type isEqualToString:@"hold"] ) {
        PlayerId playerId = (PlayerId)[parts[2] intValue];
        int length = [parts[3] intValue];
        [self.scenario.victoryConditions addObject:[[HoldAllObjectivesCondition alloc] initWithPlayerId:playerId length:length]];
    }
    else if ( [type isEqualToString:@"destroy"] ) {
        int unitId = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[DestroyUnitCondition alloc] initWithUnitId:unitId]];
    }
    else if ( [type isEqualToString:@"escort"] ) {
        int unitId = [parts[2] intValue];
        int objectiveId = [parts[3] intValue];
        [self.scenario.victoryConditions addObject:[[EscortUnitCondition alloc] initWithUnitId:unitId objectiveId:objectiveId]];
    }
    else if ( [type isEqualToString:@"tutorial"] ) {
        [self.scenario.victoryConditions addObject:[TutorialCondition new]];
    }
    else {
        NSLog( @"unknown victory condition: %@", type );
        NSAssert( NO, @"unknown victory condition" );
    }
}


@end
