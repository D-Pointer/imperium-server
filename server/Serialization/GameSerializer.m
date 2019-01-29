
#import "GameSerializer.h"
#import "Definitions.h"
#import "Unit.h"
#import "Globals.h"
#import "Scenario.h"
#import "MapReader.h"
#import "LineOfSight.h"

#import "FireMission.h"
#import "RotateMission.h"
#import "AdvanceMission.h"
#import "AssaultMission.h"
#import "ChangeModeMission.h"
#import "MeleeMission.h"
#import "MoveMission.h"
#import "MoveFastMission.h"
#import "RetreatMission.h"
#import "ScoutMission.h"
#import "IdleMission.h"
#import "DisorganizedMission.h"
#import "RallyMission.h"
#import "AreaFireMission.h"
#import "SmokeMission.h"

@implementation GameSerializer

+ (unsigned int) getVersion {
    // version of the game
    float tmp_version = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] floatValue];
    
    // convert the float to a version number, such as: 1.23 -> 1000230
    return 100000 * ( (int)(tmp_version * 10) / 10 ) +  ((int)(tmp_version * 1000) % 1000);    
}


//+ (NSString *) createFileName:(NSString *)name {
//    NSArray  * appDocumentPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
//    NSString * docsDirectory    = [appDocumentPaths objectAtIndex: 0];
//    return [docsDirectory stringByAppendingPathComponent:name];
//}


+ (NSString *) createGameData {
    Globals * globals = [Globals sharedInstance];
 
    // the destination string
    NSMutableString * data = [NSMutableString new];

    // meta data
    [data appendFormat:@"d %d ", [GameSerializer getVersion]];
    [data appendFormat:@"%d ",  globals.scenario.scenarioId];
    [data appendFormat:@"%d ",  globals.player1.type];
    [data appendFormat:@"%d ",  globals.player2.type];
    [data appendFormat:@"%d ",  globals.localPlayer.playerId];
    [data appendFormat:@"%.2f\n", globals.clock.elapsedTime];

    // save all units
    for ( Unit * unit in globals.units ) {
        [data appendString:[unit save]];
    }

    NSLog( @"game data: %@", data );
    NSLog( @"string size: %lu", (unsigned long)data.length );

    return data;
}


+ (BOOL) parseMetaDataFrom:(NSArray *)parts {
    int scenarioId;
    float elapsedTime;
    PlayerType playerType1, playerType2, localPlayerId;

    // meta data
    NSAssert( parts.count == 7, @"Invalid meta data" );

    // our game version and loaded version
    unsigned int ourVersion  = [GameSerializer getVersion];
    unsigned int fileVersion = [parts[1] unsignedIntValue];

    // precautions, we don't load if the version is higher than our
    if ( fileVersion > ourVersion ) {
        NSLog( @"loaded data has higher version! %u vs %u", fileVersion, ourVersion );
        return NO;
    }

    // extract all data
    scenarioId    = [parts[2] intValue];
    playerType1   = (PlayerType)[parts[3] intValue];
    playerType2   = (PlayerType)[parts[4] intValue];
    localPlayerId = (PlayerType)[parts[5] intValue];
    elapsedTime   = [parts[6] floatValue];

    Globals * globals = [Globals sharedInstance];

    // flip the player types if we have a network game
    if ( playerType1 == kNetworkPlayer || playerType2 == kNetworkPlayer ) {
        PlayerType tmp = playerType1;
        playerType1 = playerType2;
        playerType2 = tmp;
    }

    // this is now our current scenario, try to find it from the global set of scenarios. as the id:s do not form
    // a sequential list without gaps, we must iterate
    for ( Scenario * scenario in globals.scenarios ) {
        if ( scenario.scenarioId == scenarioId ) {
            globals.scenario = scenario;
        }
    }

    NSAssert( globals.scenario != nil, @"No scenario found" );

    // the players must be set before the game layer is set up and the scenario parsed
    globals.player1 = [[Player alloc] initWithId:kPlayer1 type:playerType1];
    globals.player2 = [[Player alloc] initWithId:kPlayer2 type:playerType2];

    //globals.localPlayer = localPlayerId == kPlayer1 ? globals.player1 : globals.player2;

    // *******************************************************************
    // create the real game scene
    //[[CCDirector sharedDirector] replaceScene:[GameLayer node]];

    // load the rest of the map
    [[MapReader new] completeScenario:globals.scenario];

    // set the elapsed time, update the clock in the game layer with the current time and turn
    globals.clock.elapsedTime = elapsedTime;
    [globals.clock update];

    // all ok
    return YES;
}


+ (Mission *) createMissionFrom:(NSArray *)parts forUnit:(Unit *)unit {
    Mission * mission = nil;
    
    // first is always the mission type
    MissionType missionType = (MissionType)[parts[1] intValue];

    switch ( missionType ) {
        case kAdvanceMission: mission      = [[AdvanceMission alloc] init]; break;
        case kAssaultMission: mission      = [[AssaultMission alloc] init]; break;
        case kFireMission: mission         = [[FireMission alloc] init]; break;
        case kSmokeMission: mission        = [[SmokeMission alloc] init]; break;
        case kAreaFireMission: mission     = [[AreaFireMission alloc] init]; break;
        case kMeleeMission: mission        = [[MeleeMission alloc] init]; break;
        case kMoveMission: mission         = [[MoveMission alloc] init]; break;
        case kMoveFastMission: mission     = [[MoveFastMission alloc] init]; break;
        case kRetreatMission: mission      = [[RetreatMission alloc] init]; break;
        case kRotateMission: mission       = [[RotateMission alloc] init]; break;
        case kScoutMission: mission        = [[ScoutMission alloc] init]; break;
        case kChangeModeMission: mission   = [[ChangeModeMission alloc] init]; break;
        case kIdleMission: mission         = [[IdleMission alloc] init]; break;
        case kDisorganizedMission: mission = [[DisorganizedMission alloc] init]; break;
        case kRoutMission: mission         = [[RoutMission alloc] init]; break;
        case kRallyMission: mission        = [[RallyMission alloc] init]; break;
    }

    // have the mission deserialize itself
    parts = [parts subarrayWithRange:NSMakeRange( 2, parts.count - 2 )];
    [mission loadFromData:parts];

    // the mission needs to know the unit
    mission.unit = unit;

    return mission;
}


+ (BOOL) parseMissionFrom:(NSArray *)parts forUnit:(Unit *)unit {
    // create and set the mission
    unit.mission = [GameSerializer createMissionFrom:parts forUnit:unit];

    NSLog( @"adding %@ to %@", unit.mission, unit );

    // all ok
    return YES;
}


+ (BOOL) parseGameData:(NSString *)data {
    Unit * currentUnit = nil;
    int unitId, lastFired, men, facing, x, y, morale,fatigue;
    UnitMode mode;

    Globals * globals = [Globals sharedInstance];

    // loop all lines
    for ( NSString * line in [data componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] ) {
        //NSLog( @"line: '%@'", line );

        NSArray* parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString * type = [parts objectAtIndex:0];

        // meta data?
        if ( [type isEqualToString:@"d"] ) {
            if ( ! [self parseMetaDataFrom:parts] ) {
                // failed to parse
                NSLog( @"failed to parse meta data" );
                return NO;
            }
        }

        // unit?
        else if ( [type isEqualToString:@"u"] ) {
            // unit, the format it:
            // u %d %d %d %d %d %d %d %d %d %d
            // unitId, lastFired, mode, men, facing, x, y, morale, fatigue];

            NSAssert( parts.count == 10, @"Invalid unit data" );

            // extract all data
            unitId    = [parts[1] intValue];
            lastFired = [parts[2] intValue];
            mode      = [parts[3] intValue];
            men       = [parts[4] intValue];
            facing    = [parts[5] intValue];
            x         = [parts[6] intValue];
            y         = [parts[7] intValue];
            morale    = [parts[8] intValue];
            fatigue   = [parts[9] intValue];

            // find the unit
            for ( Unit * tmp in globals.units) {
                currentUnit = nil;
                if ( tmp.unitId == unitId ) {
                    currentUnit = tmp;
                    break;
                }
            }

            // found it?
            if ( currentUnit == nil ) {
                NSLog( @"unit %d not found!", unitId );
                return NO;
            }

            // assign all parsed data
            currentUnit.lastFired = lastFired;
            currentUnit.mode      = mode;
            currentUnit.men       = men;
            currentUnit.rotation  = facing;
            currentUnit.position  = ccp( x, y );
            currentUnit.morale    = morale;
            currentUnit.fatigue   = fatigue;
        }

        // mission?
        else if ( [type isEqualToString:@"m"] ) {
            // mission for the current unit
            NSAssert( currentUnit != nil, @"No current unit" );
            if ( ! [self parseMissionFrom:parts forUnit:currentUnit] ) {
                // failed to parse
                NSLog( @"failed to parse mission" );
                return NO;
            }
        }
    }

    // set the objective owners
    [Objective updateOwnerForAllObjectives];

    // initial line of sight update for the current player. this must be set after all units have been read in from the save file
    // as otherwise it will perform the initial LOS check based on the positions in the original scenario file, not the real saved
    // positions
    globals.lineOfSight = [LineOfSight new];
    [globals.lineOfSight update];

    // all ok
    return YES;
}


+ (BOOL) saveGame:(NSString *)name {
    NSLog( @"saving to %@", name );
    
    // pack all the game data into a compressed buffer
    NSString * data = [self createGameData];
    return YES;
    //return [ResourceHandler saveData:data toResource:name];
//    NSString * fullPathToFile = [GameSerializer createFileName:name];
//
//    NSLog( @"save file name: %@", fullPathToFile );
//
//    // save it.
//    if ( ! [data writeToFile:fullPathToFile atomically:YES encoding:NSUTF8StringEncoding error:nil] ) {
//        // failed to save
//        NSLog( @"failed to save" );
//        return NO;
//    }
//
//    return YES;
}


+ (BOOL) loadGame:(NSString *)name {
    NSLog( @"loading from %@", name );

    // read everything from text
    NSString * data = nil; //[ResourceHandler loadResource:name];
    if ( ! data ) {
        return NO;
    }

    // parse the compressed data
    return [self parseGameData:data];
}

/*
+ (BOOL) hasSavedGame:(NSString *)name {
    return [ResourceHandler hasResource:name];
}


+ (void) deleteSavedGame:(NSString *)name {
    [ResourceHandler deleteResource:name];
}
*/

@end
