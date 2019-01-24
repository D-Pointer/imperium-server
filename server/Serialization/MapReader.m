#import "MapReader.h"
#import "MapLayer.h"
#import "DefaultPolygonNode.h"
#import "ScatteredTrees.h"
#import "Woods.h"
#import "Rocky.h"
#import "Water.h"
#import "Field.h"
#import "Unit.h"
#import "House.h"
#import "Globals.h"
#import "MissionVisualizer.h"
#import "Scenario.h"
#import "Organization.h"
#import "ScenarioScript.h"

#import "TimeCondition.h"
#import "CasualtiesCondition.h"
#import "HoldAllObjectivesCondition.h"
#import "DestroyUnitCondition.h"
#import "EscortUnitCondition.h"
#import "TutorialCondition.h"
#import "MultiplayerTimeCondition.h"
#import "MultiplayerCasualtiesCondition.h"

@interface MapReader ()

@property (nonatomic, strong) CCArray *polygons;
@property (nonatomic, strong) CCArray *textures;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) Scenario *scenario;
@property (nonatomic, strong) PolygonNode *currentTerrain;
@property (nonatomic, strong) NSMutableDictionary *headquarters;
@property (nonatomic, assign) int aiUpdateCounter;

- (void) createDefaultTerrain;

@end


@implementation MapReader

- (id) init {
    if ((self = [super init])) {
        self.polygons = [CCArray new];
        self.textures = [CCArray new];
        self.fields = nil;
        self.headquarters = [NSMutableDictionary new];

        // a counter/sequence for the AI updates
        self.aiUpdateCounter = 0;
    }

    return self;
}


- (void) dealloc {
    self.polygons = nil;
    self.textures = nil;
    self.fields = nil;
    self.scenario = nil;
    self.currentTerrain = nil;
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


- (void) parseScenarioType:(NSArray *)parts {
    self.scenario.scenarioType = (ScenarioType) [parts[1] intValue];
}


- (void) parseAIHint:(NSArray *)parts {
    self.scenario.aiHint = (AIHint) [parts[1] intValue];
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
        [self.scenario.victoryConditions addObject:[TutorialCondition new]];
    }
    else {
        CCLOG( @"unknown victory condition: %@", type );
        NSAssert( NO, @"unknown victory condition" );
    }
}


- (void) parseTerrain:(NSArray *)parts {
    TerrainType terrain_type = [parts[1] intValue];

    // result vertices
    CCArray *vertices = [CCArray array];

    unsigned int index = 2;
    while (index < parts.count) {
        float x = [parts[index++] floatValue];
        float y = [parts[index++] floatValue];
        [vertices addObject:[NSValue valueWithCGPoint:ccp( x, y )]];
    }

    // create a polygon node and position it properly
    if (terrain_type == kScatteredTrees) {
        self.currentTerrain = [[ScatteredTrees alloc] initWithPolygon:vertices smoothing:NO];
    }
    else if (terrain_type == kWoods) {
        self.currentTerrain = [[Woods alloc] initWithPolygon:vertices smoothing:NO];
    }
    else if (terrain_type == kRocky) {
        self.currentTerrain = [[Rocky alloc] initWithPolygon:vertices smoothing:NO];
    }
    else if (terrain_type == kField) {
        Field *field = [[Field alloc] initWithPolygon:vertices smoothing:NO];
        field.texture = [self.fields objectAtIndex:random() % 2];

        // rotate and scale a bit
        [field rotateTextureBy:-45 + CCRANDOM_0_1() * 90];
        [field scaleTextureBy:1.0f + CCRANDOM_0_1()];
        self.currentTerrain = field;
    }
    else {
        DefaultPolygonNode *defaultNode;

        if (terrain_type == kRiver) {
            defaultNode = [[Water alloc] initWithPolygon:vertices smoothing:YES];
        }
        else {
            // not water
            defaultNode = [[DefaultPolygonNode alloc] initWithPolygon:vertices smoothing:YES];
        }

        defaultNode.texture = [self.textures objectAtIndex:terrain_type];
        self.currentTerrain = defaultNode;
    }

    // find a texture for the polygon
    self.currentTerrain.terrainType = terrain_type;
    self.currentTerrain.position = ccp( 0, 0 );
    [[Globals sharedInstance].mapLayer addChild:self.currentTerrain z:self.currentTerrain.mapLayerZ];

    // save for later too
    [[Globals sharedInstance].mapLayer.polygons addObject:self.currentTerrain];
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
    [[Globals sharedInstance].mapLayer addChild:unit z:kUnitZ];
    [[Globals sharedInstance].units addObject:unit];

    // add a mission visualizer for the local human player's units
    if ((owner == kPlayer1 && [Globals sharedInstance].player1.type == kLocalPlayer) || (owner == kPlayer2 && [Globals sharedInstance].player2.type == kLocalPlayer)) {
        unit.missionVisualizer = [[MissionVisualizer alloc] initWithUnit:unit];
        [[Globals sharedInstance].mapLayer addChild:unit.missionVisualizer z:kMissionVisualizerZ];
    }
    else {
        // not own, hide by default so that the first LOS update starts from all hidden enemies
        unit.visible = NO;

        // could be an AI unit, so setup the counter too
        unit.aiUpdateCounter = self.aiUpdateCounter++ % sParameters[kParamAiExecutionIntervalI].intValue;
    }

    if (unit.unitTypeIcon) {
        [[Globals sharedInstance].mapLayer addChild:unit.unitTypeIcon z:kUnitTypeIconZ];
    }

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

    CCSprite *shadow = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"Houses/HouseShadow%d.png", type + 1]];
    shadow.position = ccp( x + 2, y - 2 );
    shadow.rotation = rotation;

    House *house = [House spriteWithSpriteFrameName:[NSString stringWithFormat:@"Houses/House%d.png", type + 1]];
    house.position = ccp( x, y );
    house.rotation = rotation;

    // add the house and shadow
    [[Globals sharedInstance].mapLayer addHouse:house withShadow:shadow];
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
    CCArray *startPositions = [CCArray arrayWithCapacity:100];
    globals.scenario.startingPositions = startPositions;

    float x1, x2;
    if (globals.localPlayer.playerId == kPlayer1) {
        x1 = 0;
        x2 = globals.mapLayer.mapWidth / 2.0f;
    }
    else {
        x1 = globals.mapLayer.mapWidth / 2.0f;
        x2 = globals.mapLayer.mapWidth;
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

    CCLOG( @"parsed %lu and ignored %d starting positions", (unsigned long)startPositions.count, ignored );
}


- (void) parseScript:(NSArray *)parts {
    if (parts.count == 1) {
        return;
    }

    NSMutableArray *scriptParts = [NSMutableArray arrayWithArray:parts];
    [scriptParts removeObjectAtIndex:0];
    NSString *script = [[scriptParts componentsJoinedByString:@" "] stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
    CCLOG( @"script: '%@'", script );

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
    [[Globals sharedInstance].mapLayer addChild:objective z:kObjectiveZ];
    [[Globals sharedInstance].objectives addObject:objective];
}


- (NSArray *) readLines:(NSString *)name {
    // read everything from text
    NSString *contents = [NSString stringWithContentsOfFile:name encoding:NSUTF8StringEncoding error:nil];

    // separate by new line
    return [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}


- (void) createDefaultTerrain {
    // get the normal- and heightmap filenames
    //NSString * heightMapFilename = [[Globals sharedInstance].scenario.filename stringByReplacingOccurrencesOfString:@".map" withString:@".heightmap"];
    //NSString * normalMapFilename = [[Globals sharedInstance].scenario.filename stringByReplacingOccurrencesOfString:@".map" withString:@"-normalmap.png"];

    // corners of the map
    CCArray *corners = [CCArray array];
    [corners addObject:[NSValue valueWithCGPoint:ccp( 0, 0 )]];
    [corners addObject:[NSValue valueWithCGPoint:ccp( self.scenario.width, 0 )]];
    [corners addObject:[NSValue valueWithCGPoint:ccp( self.scenario.width, self.scenario.height )]];
    [corners addObject:[NSValue valueWithCGPoint:ccp( 0, self.scenario.height )]];

    // create a polygon node that spans the whole map
    DefaultPolygonNode *baseGrass = [[DefaultPolygonNode alloc] initWithPolygon:corners smoothing:NO];
    baseGrass.terrainType = kGrass;
    baseGrass.texture = [self.textures objectAtIndex:kGrass];
    baseGrass.position = ccp( 0, 0 );
    [[Globals sharedInstance].mapLayer addChild:baseGrass z:kBackgroundZ];

    // load the heightmap
    //baseGrass.normalMap = [[CCTextureCache sharedTextureCache] addImage:normalMapFilename];
    //NSAssert( baseGrass.normalMap, @"normal map is nil" );
    //CCLOG( @"loaded normal map" );

    // save for later too
    [Globals sharedInstance].mapLayer.baseGrass = baseGrass;
}


- (Scenario *) parseScenarioMetaData:(NSString *)name {
    //CCLOG( @"parsing: %@", name );

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
            [self parseAIHint:parts];
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

    CCLOG( @"parsed ok: %@", self.scenario );

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
            CCLOG( @"unit %@ has hq id: %d", unit, hqId );

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
            CCLOG( @"created %@", organization );
        }
    }

    CCLOG( @"found %lu organizations", (unsigned long) globals.organizations.count );

    // now check all non hq units that have a valid headquarter
    for (Unit *unit in [Globals sharedInstance].units) {
        if (unit.destroyed == NO && unit.headquarter != nil && unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
            // this unit belongs to its hq's organization
            unit.organization = unit.headquarter.organization;
            [unit.organization.units addObject:unit];
            CCLOG( @"added %@ to %@", unit, unit.organization );
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
    CCLOG( @"wind direction: %.0f, speed: %.1f m/s", self.scenario.windDirection, self.scenario.windStrength );
}


- (void) completeScenario:(Scenario *)scenario {
    CCLOG( @"completing: %@ from file: %@", scenario.title, scenario.filename );

    _scenario = scenario;

    // load all textures
    [self.textures addObject:nil]; // woods
    [self.textures addObject:nil]; // field
    [self.textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"Terrains/grass.jpg"]];
    [self.textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"Terrains/sand2.jpg"]];
    [self.textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"Terrains/water.jpg"]];
    [self.textures addObject:nil]; // roof
    [self.textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"Terrains/swamp.jpg"]];
    [self.textures addObject:nil]; // rocky
    [self.textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"Terrains/beach.jpg"]];
    [self.textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"Terrains/ford.png"]];
    [self.textures addObject:nil]; // scattered trees

    // build mip maps for them all
    for (CCTexture2D *texture in self.textures) {
        [texture generateMipmap];
    }

    // fields have three variations
    self.fields = @[[[CCTextureCache sharedTextureCache] addImage:@"Terrains/field1.jpg"],
            [[CCTextureCache sharedTextureCache] addImage:@"Terrains/field2.jpg"]];

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
    CCLOG( @"scenario %@ completed ok", self.scenario.title );
}

@end
