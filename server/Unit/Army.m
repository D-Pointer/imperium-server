#import "Army.h"
#import "Definitions.h"
#import "Globals.h"
#import "UnitDefinition.h"
#import "Map.h"
#import "MissionVisualizer.h"
#import "Scenario.h"


@implementation Army

- (instancetype) init {
    self = [super init];
    if (self) {
        self.unitDefinitions = [NSMutableArray new];
    }

    return self;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[Army %lu units]", (unsigned long)self.unitDefinitions.count];
}


+ (void) loadArmies {
    NSLog( @"loading armies" );

    Globals *globals = [Globals sharedInstance];

    // clear the armies
    globals.armies = @[
            [Army new],
            [Army new],
            [Army new]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    for (NSUInteger armyIndex = 0; armyIndex < 3; ++armyIndex) {
        // load as many units as we can
        for (NSUInteger unitIndex = 0; ; ++unitIndex) {
            NSString *typeKey = [NSString stringWithFormat:@"army-%lu-%lu", (unsigned long)armyIndex, (unsigned long)unitIndex];
            NSString *typeData = [defaults objectForKey:typeKey];

            if (typeData == nil) {
                // no more units for this army
                NSLog( @"army %lu has %lu units", (unsigned long)armyIndex, (unsigned long)unitIndex );
                break;
            }

            UnitDefinitionType type = (UnitDefinitionType) [typeData intValue];

            // create a unit definition
            [[globals.armies[armyIndex] unitDefinitions] addObject:[[UnitDefinition alloc] initWithType:type]];
        }
    }

    // make the first army current
    globals.currentArmy = globals.armies[0];
}


+ (void) saveArmies {
    Globals *globals = [Globals sharedInstance];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // save all armies
    for (unsigned int armyIndex = 0; armyIndex < 3; ++armyIndex) {
        Army *army = globals.armies[armyIndex];

        // save all the units in the army
        unsigned int unitIndex = 0;
        for (UnitDefinition *unitDef in army.unitDefinitions) {
            NSString *typeKey = [NSString stringWithFormat:@"army-%d-%d", armyIndex, unitIndex];
            [defaults setInteger:unitDef.type forKey:typeKey];
            unitIndex++;
        }
    }

    [defaults synchronize];
}


- (void) createUnitsForPlayer:(PlayerId)player {
    Globals *globals = [Globals sharedInstance];

    // copy the starting positions
     NSMutableArray *startPositions = [ NSMutableArray arrayWithArray:globals.scenario.startingPositions];

    // unique unit id:s for both players
    int unitId = player == kPlayer1 ? 0 : 100;

    int hqIndex = 1;

    for (UnitDefinition *organizationUnitDef in self.unitDefinitions) {
        Unit *hq = nil;
        int unitIndex = 1;

        // loop the real units that this unit def contains, can be 1..4
        for (NSNumber *type in organizationUnitDef.units) {
            UnitDefinitionType unitDefType = (UnitDefinitionType) [type intValue];
            UnitType unitType = kInfantry;
            int men = 0;
            int * index = NULL;
            WeaponType weaponType = kRifle;
            int ammo = 45 + arc4random_uniform( 10 );

            switch (unitDefType) {
                case kInfantryHeadquarterDef:
                    unitType = kInfantryHeadquarter;
                    weaponType = kRifle;
                    men = 10 + arc4random_uniform( 5 );
                    index = &hqIndex;
                    break;

                case kInfantryCompanyDef:
                    unitType = kInfantry;
                    weaponType = kRifle;
                    men = 45 + arc4random_uniform( 8 );
                    index = &unitIndex;
                    break;

                case kAssaultInfantryCompanyDef:
                    unitType = kInfantry;
                    weaponType = kSubmachineGun;
                    men = 45 + arc4random_uniform( 8 );
                    index = &unitIndex;
                    break;

                case kCavalryHeadquarterDef:
                    unitType = kCavalryHeadquarter;
                    weaponType = kRifle;
                    men = 10 + arc4random_uniform( 5 );
                    index = &hqIndex;
                    break;

                case kCavalryCompanyDef:
                    unitType = kCavalry;
                    weaponType = kRifle;
                    men = 45 + arc4random_uniform( 8 );
                    index = &unitIndex;
                    break;

                case kLightArtilleryBatteryDef:
                    unitType = kArtillery;
                    weaponType = kLightCannon;
                    men = 25 + arc4random_uniform( 8 );
                    index = &unitIndex;
                    break;

                case kHeavyArtilleryBatteryDef:
                    unitType = kArtillery;
                    weaponType = kHeavyCannon;
                    men = 25 + arc4random_uniform( 8 );
                    index = &unitIndex;
                    break;

                case kHowitzerArtilleryBatteryDef:
                    unitType = kArtillery;
                    weaponType = kHowitzer;
                    men = 25 + arc4random_uniform( 8 );
                    index = &unitIndex;
                    break;

                case kMachineGunTeamDef:
                    unitType = kInfantry;
                    weaponType = kMachineGun;
                    men = 4;
                    index = &unitIndex;
                    break;

                case kSniperTeamDef:
                    unitType = kInfantry;
                    weaponType = kSniperRifle;
                    men = 3;
                    index = &unitIndex;
                    break;

                case kMortarTeamDef:
                    unitType = kInfantry;
                    weaponType = kMortar;
                    men = 6;
                    index = &unitIndex;
                    break;

                case kFlamethrowerTeamDef:
                    unitType = kInfantry;
                    weaponType = kFlamethrower;
                    men = 4;
                    index = &unitIndex;
                    break;

                default:
                    NSLog( @"invalid unit type: %d", unitDefType );
                    NSAssert( NO, @"invalid unit type" );
            }

            // create theu unit
            Unit *unit = [Unit createUnitType:unitType forOwner:player mode:kFormation men:men morale:100 fatigue:0 weapon:weaponType experience:kRegular ammo:ammo];
            unit.unitId = unitId++;
            unit.name = [self name:unitDefType unitIndex:index];

            // is this a headquarter for other units?
            if (unitType == kInfantryHeadquarter || unitType == kCavalryHeadquarter) {
                hq = unit;
            }
            else if (hq != nil) {
                unit.headquarter = hq;
            }

            // add mission visualizers
            unit.missionVisualizer = [[MissionVisualizer alloc] initWithUnit:unit];
            [[Globals sharedInstance].map addChild:unit.missionVisualizer z:kMissionVisualizerZ];

            // set the position and facing
            [self findStartingPositionFor:unit fromPositions:startPositions];

            // set up the icon
            [unit updateIcon];

            // add to map
            [globals.map addChild:unit z:kUnitZ];
            if (unit.unitTypeIcon) {
                [[Globals sharedInstance].map addChild:unit.unitTypeIcon z:kUnitTypeIconZ];
            }

            // and save for later
            [[Globals sharedInstance].units addObject:unit];

            // add to the right container too
            if (player == kPlayer1) {
                [globals.unitsPlayer1 addObject:unit];
            }
            else {
                [globals.unitsPlayer2 addObject:unit];
            }

            NSLog( @"created unit %@", unit );
        }
    }
}

- (void) findStartingPositionFor:(Unit *)unit fromPositions:( NSMutableArray *)startPositions {
    Globals *globals = [Globals sharedInstance];

    // does this unit have a headquarter?
    Unit *hq = unit.headquarter;
    if (hq == nil) {
        // no hq, just take a random position
        unsigned int index = arc4random_uniform( (uint32_t)startPositions.count );
        unit.position = [[startPositions objectAtIndex:index] CGPointValue];
        [startPositions removeObjectAtIndex:index];
    }

    else {
        CGPoint hqPos = hq.position;

        // find the closest position to the hq position
        float closestDistance = 100000;
        unsigned int closestIndex = 100000;
        for (unsigned int index = 0; index < startPositions.count; ++index) {
            float distance = ccpDistance( hqPos, [[startPositions objectAtIndex:index] CGPointValue] );
            if (distance < closestDistance) {
                closestIndex = index;
                closestDistance = distance;
            }
        }

        NSAssert( closestIndex != 100000, @"no start pos found" );

        // use the found position
        unit.position = [[startPositions objectAtIndex:closestIndex] CGPointValue];
        [startPositions removeObjectAtIndex:closestIndex];
    }

    // face the map center
    CGPoint mapCenter = ccp( globals.map.mapWidth / 2, globals.map.mapHeight / 2 );
    unit.rotation = CC_RADIANS_TO_DEGREES( ccpAngleSigned( ccpSub( mapCenter, unit.position ), ccp( 0, 1 ) ) );
}


- (NSString *) name:(UnitDefinitionType)type unitIndex:(int *)unitIndex {
    NSString * baseName;

    switch (type) {
        case kInfantryBattalionDef:
        case kAssaultInfantryBattalionDef:
        case kCavalryBattalionDef:
        case kLightArtilleryBattalionDef:
        case kHeavyArtilleryBattalionDef:
        case kHowitzerArtilleryBattalionDef:
        case kSupportCompanyDef:
            NSAssert( NO, @"invalid unit definition" );
            break;

        case kInfantryCompanyDef:
            baseName =  @"Infantry company";
            break;

        case kAssaultInfantryCompanyDef:
            baseName =  @"Assault infantry company";
            break;

        case kCavalryCompanyDef:
            baseName =  @"Cavalry company";
            break;

        case kInfantryHeadquarterDef:
            baseName = @"Infantry HQ";
            break;

        case kCavalryHeadquarterDef:
            baseName = @"Cavalry HQ";
            break;

        case kLightArtilleryBatteryDef:
            baseName =  @"Light artillery battery";
            break;

        case kHeavyArtilleryBatteryDef:
            baseName =  @"Heavy artillery battery";
            break;

        case kHowitzerArtilleryBatteryDef:
            baseName =  @"Howitzer artillery battery";
            break;

        case kMachineGunTeamDef:
            baseName =  @"Machine gun team";
            break;

        case kSniperTeamDef:
            baseName =  @"Sniper team";
            break;

        case kMortarTeamDef:
            baseName =  @"Mortar team";
            break;

        case kFlamethrowerTeamDef:
            baseName =  @"Flamethrower team";
            break;

        default:
            NSAssert( NO, @"unknown unit definition" );
    }

    // set up the headquarter name
    NSString * order;
    switch ( *unitIndex ) {
        case 1:
            order = @"1st ";
            break;

        case 2:
            order = @"2nd ";
            break;

        case 3:
            order = @"3rd ";
            break;

        default:
            order = [NSString stringWithFormat:@"%dth ", *unitIndex];
    }

    (*unitIndex)++;

    return [order stringByAppendingString:baseName];
}

@end
