#import "MapReader.h"
#import "Map.h"
#import "PolygonNode.h"
#import "Unit.h"
#import "Globals.h"
#import "Scenario.h"
#import "Organization.h"

#import "TimeCondition.h"
#import "CasualtiesCondition.h"
#import "HoldAllObjectivesCondition.h"
#import "DestroyUnitCondition.h"
#import "EscortUnitCondition.h"
#import "MultiplayerTimeCondition.h"
#import "MultiplayerCasualtiesCondition.h"

@interface MapReader ()

@property (nonatomic, strong) NSMutableArray *polygons;
@property (nonatomic, strong) Scenario *scenario;
@property (nonatomic, strong) PolygonNode *currentTerrain;
@property (nonatomic, strong) NSMutableDictionary *headquarters;

- (void) createDefaultTerrain;

@end


@implementation MapReader

- (id) init {
    if ((self = [super init])) {
        self.polygons = [ NSMutableArray new];
        self.headquarters = [NSMutableDictionary new];
    }

    return self;
}


- (void) dealloc {
    self.polygons = nil;
    self.scenario = nil;
}


- (void) parseSize:(NSArray *)parts {
    self.scenario.width = [parts[1] intValue];
    self.scenario.height = [parts[2] intValue];
}


- (void) parseId:(NSArray *)parts {
    self.scenario.scenarioId = [parts[1] intValue];
}


- (void) parseDepends:(NSArray *)parts {
    self.scenario.dependsOn = [parts[1] intValue];
}


- (void) parseTime:(NSArray *)parts {
    self.scenario.startTime = [parts[1] intValue] * 3600 + [parts[2] intValue] * 60;
}


- (void) parseBattleSize:(NSArray *)parts {
    self.scenario.battleSize = (BattleSizeType) [parts[1] intValue];
}


- (void) parseTitle:(NSArray *)parts {
    NSMutableArray *title_parts = [NSMutableArray arrayWithArray:parts];
    [title_parts removeObjectAtIndex:0];
    self.scenario.title = [title_parts componentsJoinedByString:@" "];
}


- (void) parseDescription:(NSArray *)parts {
    NSMutableArray *desc_parts = [NSMutableArray arrayWithArray:parts];
    [desc_parts removeObjectAtIndex:0];
    self.scenario.information = [[desc_parts componentsJoinedByString:@" "] stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
}


- (void) parseVictoryCondition:(NSArray *)parts {
    // victory time 60
    // victory casualty 75
    // victory hold 0 600
    // victory destroy 10
    NSString *type = parts[1];
    if ([type isEqualToString:@"time"]) {
        int length = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[TimeCondition alloc] initWithLength:length]];
    }
    else if ([type isEqualToString:@"multiplayertime"]) {
        int length = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[MultiplayerTimeCondition alloc] initWithLength:length]];
    }
    else if ([type isEqualToString:@"casualty"]) {
        int percentage = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[CasualtiesCondition alloc] initWithPercentage:percentage]];
    }
    else if ([type isEqualToString:@"multiplayercasualty"]) {
        int percentage = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[MultiplayerCasualtiesCondition alloc] initWithPercentage:percentage]];
    }
    else if ([type isEqualToString:@"hold"]) {
        PlayerId playerId = (PlayerId) [parts[2] intValue];
        int length = [parts[3] intValue];
        [self.scenario.victoryConditions addObject:[[HoldAllObjectivesCondition alloc] initWithPlayerId:playerId length:length]];
    }
    else if ([type isEqualToString:@"destroy"]) {
        int unitId = [parts[2] intValue];
        [self.scenario.victoryConditions addObject:[[DestroyUnitCondition alloc] initWithUnitId:unitId]];
    }
    else if ([type isEqualToString:@"escort"]) {
        int unitId = [parts[2] intValue];
        int objectiveId = [parts[3] intValue];
        [self.scenario.victoryConditions addObject:[[EscortUnitCondition alloc] initWithUnitId:unitId objectiveId:objectiveId]];
    }

    else if ([type isEqualToString:@"tutorial"]) {
        // ignore
    }
    else {
        NSLog( @"unknown victory condition: %@", type );
        NSAssert( NO, @"unknown victory condition" );
    }
}


- (void) parseTerrain:(NSArray *)parts {
    TerrainType terrainType = [parts[1] intValue];

    // result vertices
     NSMutableArray *vertices = [ NSMutableArray array];

    unsigned int index = 2;
    while (index < parts.count) {
        float x = [parts[index++] floatValue];
        float y = [parts[index++] floatValue];
        [vertices addObject:[NSValue valueWithCGPoint:ccp( x, y )]];
    }

    BOOL smoothing = YES;

    // create a polygon node and position it properly
    switch ( terrainType ) {
        case kScatteredTrees:
        case kWoods:
        case kRocky:
        case kField:
            smoothing = NO;
            break;

        default:
            smoothing = YES;
    }

    self.currentTerrain = [[PolygonNode alloc] initWithPolygon:vertices smoothing:smoothing];

    self.currentTerrain.terrainType = terrainType;
    self.currentTerrain.position = ccp( 0, 0 );

    // save for later too
    [[Globals sharedInstance].map.polygons addObject:self.currentTerrain];
}


- (void) parseTrees:(NSArray *)parts {
    // precautions
    NSAssert( self.currentTerrain && (self.currentTerrain.terrainType == kScatteredTrees || self.currentTerrain.terrainType == kWoods), @"invalid terrain" );

    // have the scattered trees node create the trees
    [(ScatteredTrees *) self.currentTerrain createTreesFrom:parts];
}


- (void) parseRocks:(NSArray *)parts {
    // precautions
    NSAssert( self.currentTerrain && self.currentTerrain.terrainType == kRocky, @"invalid terrain" );

    // have the scattered trees node create the trees
    [(Rocky *) self.currentTerrain createRocksFrom:parts];
}


- (void) parseUnit:(NSArray *)parts {
    // unit 0 0 0 1168 824 109 9 82 0 0 1 1st Recon
    int unit_id = [parts[1] intValue];
    PlayerId owner = (PlayerId)[parts[2] intValue];
    UnitType type = (UnitType)[parts[3] intValue];
    float x = [parts[4] floatValue];
    float y = [parts[5] floatValue];
    float rotation = [parts[6] floatValue];
    int hq_id = [parts[7] intValue];
    int men = [parts[8] intValue];
    WeaponType weapon = (WeaponType)[parts[9] intValue];
    UnitMode mode = (UnitMode)[parts[10] intValue];
    ExperienceType exp = (ExperienceType)[parts[11] intValue];
    int ammo = [parts[12] intValue];

    // default to full morale and no fatigue
    float morale = 100;
    float fatigue = 0;

    NSMutableArray *name_parts = [NSMutableArray arrayWithArray:parts];
    [name_parts removeObjectsInRange:NSMakeRange( 0, 13 )];
    NSString *name = [name_parts componentsJoinedByString:@" "];

    // create the real unit, assume
    Unit *unit = [Unit createUnitType:type forOwner:owner mode:mode men:men morale:morale fatigue:fatigue weapon:weapon experience:exp ammo:ammo];
    unit.position = ccp( x, y );
    unit.rotation = rotation;

    // misc data
    unit.unitId = unit_id;
    unit.name = name;
    unit.mode = mode;

    // set up the icon
    [unit updateIcon];

    // save the headquarter for later
    if (hq_id != -1) {
        self.headquarters[@(unit.unitId)] = @(hq_id);
    }

    // save for later
    [[Globals sharedInstance].units addObject:unit];

    // add to the right container too
    if (owner == kPlayer1) {
        [[Globals sharedInstance].unitsPlayer1 addObject:unit];
    }
    else {
        [[Globals sharedInstance].unitsPlayer2 addObject:unit];
    }
}


- (void) parseHouse:(NSArray *)parts {
    // house 0 472.5 524.5
    int type = [parts[1] intValue];
    float x = [parts[2] floatValue];
    float y = [parts[3] floatValue];
    float rotation = [parts[4] floatValue];

    // TODO: what to do with houses?
}


- (void) parseNavigationGrid:(NSArray *)parts {
    // allocate space for the navigation grid
    Byte *navGrid = (Byte *) malloc( parts.count - 1 * sizeof( Byte ) );

    // copy the data
    for (unsigned int index = 1; index < parts.count; ++index) {
        // note the different indexes!
        navGrid[index - 1] = (Byte) [parts[index] intValue];
    }

    // create the path finder, it precalculates a lot based on the map
    [Globals sharedInstance].pathFinder = [[PathFinder alloc] initWithData:navGrid];
}


- (void) parseStartingPositions:(NSArray *)parts {
    Globals *globals = [Globals sharedInstance];

    // make sure the scenario has new starting positions
     NSMutableArray *startPositions = [ NSMutableArray arrayWithCapacity:100];
    globals.scenario.startingPositions = startPositions;

    float x1, x2;
    if (globals.localPlayer.playerId == kPlayer1) {
        x1 = 0;
        x2 = globals.map.mapWidth / 2.0f;
    }
    else {
        x1 = globals.map.mapWidth / 2.0f;
        x2 = globals.map.mapWidth;
    }

    int ignored = 0;

    // copy the data
    for (unsigned int index = 1; index < parts.count; index += 2) {
        CGPoint startPos = ccp( [parts[index] floatValue], [parts[index + 1] floatValue] );

        // only save those that are on our side of the map
        if (x1 <= startPos.x && startPos.x <= x2) {
            [startPositions addObject:[NSValue valueWithCGPoint:startPos]];
        }
        else {
            ignored++;
        }
    }

    NSLog( @"parsed %lu and ignored %d starting positions", (unsigned long)startPositions.count, ignored );
}


- (void) parseScript:(NSArray *)parts {
    if (parts.count == 1) {
        return;
    }

    NSMutableArray *scriptParts = [NSMutableArray arrayWithArray:parts];
    [scriptParts removeObjectAtIndex:0];
    NSString *script = [[scriptParts componentsJoinedByString:@" "] stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
    NSLog( @"script: '%@'", script );

    // create the real script
    [Globals sharedInstance].scenarioScript = [[ScenarioScript alloc] initWithScript:script];
}


- (void) parseObjective:(NSArray *)parts {
    // objective 0 472.5 524.5 Objective 1
    int objective_id = [parts[1] intValue];
    float x = [parts[2] floatValue];
    float y = [parts[3] floatValue];

    NSMutableArray *title_parts = [NSMutableArray arrayWithArray:parts];
    [title_parts removeObjectsInRange:NSMakeRange( 0, 4 )];
    NSString *title = [title_parts componentsJoinedByString:@" "];

    Objective *objective = [Objective create];
    objective.objectiveId = objective_id;
    objective.anchorPoint = ccp( 0.5, 0.5 );
    objective.position = ccp( x, y );
    objective.title = title;

    // the ownership is later updated for all objectives at the same time

    // save for later
    [[Globals sharedInstance].objectives addObject:objective];
}


- (NSArray *) readLines:(NSString *)name {
    // read everything from text
    NSString *contents = [NSString stringWithContentsOfFile:name encoding:NSUTF8StringEncoding error:nil];

    // separate by new line
    return [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}


- (void) createDefaultTerrain {
    // corners of the map
    NSMutableArray *corners = [ NSMutableArray array];
    [corners addObject:[NSValue valueWithCGPoint:ccp( 0, 0 )]];
    [corners addObject:[NSValue valueWithCGPoint:ccp( self.scenario.width, 0 )]];
    [corners addObject:[NSValue valueWithCGPoint:ccp( self.scenario.width, self.scenario.height )]];
    [corners addObject:[NSValue valueWithCGPoint:ccp( 0, self.scenario.height )]];

    // create a polygon node that spans the whole map
    DefaultPolygonNode *baseGrass = [[DefaultPolygonNode alloc] initWithPolygon:corners smoothing:NO];
    baseGrass.terrainType = kGrass;
    baseGrass.position = ccp( 0, 0 );

    // save for later too
    [Globals sharedInstance].map.baseGrass = baseGrass;
}


- (Scenario *) parseScenarioMetaData:(NSString *)name {
    //NSLog( @"parsing: %@", name );

    self.scenario = [[Scenario alloc] init];
    self.scenario.filename = name;

    NSArray *lines = [self readLines:name];

    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *type = parts[0];

        if ([type isEqualToString:@"size"]) {
            [self parseSize:parts];
        }

        else if ([type isEqualToString:@"time"]) {
            [self parseTime:parts];
        }

        else if ([type isEqualToString:@"id"]) {
            [self parseId:parts];
        }

        else if ([type isEqualToString:@"depend"]) {
            [self parseDepends:parts];
        }

        else if ([type isEqualToString:@"title"]) {
            [self parseTitle:parts];
        }

        else if ([type isEqualToString:@"type"]) {
            [self parseScenarioType:parts];
        }

        else if ([type isEqualToString:@"aihint"]) {
            // ignore
        }

        else if ([type isEqualToString:@"battlesize"]) {
            [self parseBattleSize:parts];
        }

        else if ([type isEqualToString:@"desc"]) {
            [self parseDescription:parts];
        }

        else if ([type isEqualToString:@"victory"]) {
            [self parseVictoryCondition:parts];
        }

        else {
            // nothing we want, we're done
            break;
        }
    }

    NSLog( @"parsed ok: %@", self.scenario );

    return self.scenario;
}


- (void) setupHeadquarters {
    NSNumber *hqNumber;
    int hqId;

    // check all units
    for (Unit *unit in [Globals sharedInstance].units) {
        if ((hqNumber = self.headquarters[[NSNumber numberWithInt:unit.unitId]]) != nil) {
            // the unit has a headquarter
            hqId = [hqNumber intValue];
            NSLog( @"unit %@ has hq id: %d", unit, hqId );

            // find the hq
            for (Unit *hq in [Globals sharedInstance].units) {
                if (hq.unitId == hqId) {
                    unit.headquarter = hq;
                    break;
                }
            }

            NSAssert( unit.headquarter != nil, @"no headquarter found!" );
        }
    }
}


- (void) setupOrganizations {
    Globals *globals = [Globals sharedInstance];

    Organization *organization;

    // check all units that are headquarters
    for (Unit *unit in [Globals sharedInstance].units) {
        if (unit.destroyed == NO && (unit.type == kInfantryHeadquarter || unit.type == kCavalryHeadquarter)) {
            organization = [[Organization alloc] initWithHeadquarter:unit];
            unit.organization = organization;
            [globals.organizations addObject:organization];
            NSLog( @"created %@", organization );
        }
    }

    NSLog( @"found %lu organizations", (unsigned long) globals.organizations.count );

    // now check all non hq units that have a valid headquarter
    for (Unit *unit in [Globals sharedInstance].units) {
        if (unit.destroyed == NO && unit.headquarter != nil && unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
            // this unit belongs to its hq's organization
            unit.organization = unit.headquarter.organization;
            [unit.organization.units addObject:unit];
            NSLog( @"added %@ to %@", unit, unit.organization );
        }
    }
}


- (void) setupVictoryConditions {
    Globals *globals = [Globals sharedInstance];

    for (VictoryCondition *vc in globals.scenario.victoryConditions) {
        [vc setup];
    }
}


- (void) setupWind {
    self.scenario.windDirection = CCRANDOM_0_1() * 360.0f;

    // always at least 1 m/s wind
    self.scenario.windStrength = 1.0f + CCRANDOM_0_1() * 1.0f;
    NSLog( @"wind direction: %.0f, speed: %.1f m/s", self.scenario.windDirection, self.scenario.windStrength );
}


- (void) completeScenario:(Scenario *)scenario {
    NSLog( @"completing: %@ from file: %@", scenario.title, scenario.filename );

    _scenario = scenario;

    // setup the default background. do this before all other polygons so that the terrain comes at the bottom of
    // the stack of polygons, otherwise terrain picking will always return the grass
    [self createDefaultTerrain];

    NSArray *lines = [self readLines:scenario.filename];

    for (NSString *line in lines) {
        NSArray *parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        // precautions in case there are empty lines
        if ( parts.count == 0 ) {
            continue;
        }

        NSString *type = parts[0];

        if ([type isEqualToString:@"terrain"]) {
            [self parseTerrain:parts];
        }

        else if ([type isEqualToString:@"trees"]) {
            [self parseTrees:parts];
        }

        else if ([type isEqualToString:@"rocks"]) {
            [self parseRocks:parts];
        }

        else if ([type isEqualToString:@"unit"]) {
            [self parseUnit:parts];
        }

        else if ([type isEqualToString:@"objective"]) {
            [self parseObjective:parts];
        }

        else if ([type isEqualToString:@"house"]) {
            [self parseHouse:parts];
        }

        else if ([type isEqualToString:@"navgrid"]) {
            [self parseNavigationGrid:parts];
        }

        else if ([type isEqualToString:@"startpos"]) {
            [self parseStartingPositions:parts];
        }

        else if ([type isEqualToString:@"script"]) {
            [self parseScript:parts];
        }

        else if ([type isEqualToString:@"end"]) {
            // end of scenario, we ignore this
        }
    }

    // setup all headquarters for all units
    [self setupHeadquarters];

    // setup all organizations for all units
    [self setupOrganizations];

    // setup all victory conditions
    [self setupVictoryConditions];

    // setup wind and weather
    [self setupWind];

    // and we're done
    NSLog( @"scenario %@ completed ok", self.scenario.title );
}

@end
