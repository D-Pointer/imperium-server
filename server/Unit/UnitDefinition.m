#import "UnitDefinition.h"

@interface UnitDefinition ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *desc;
@property (nonatomic, strong, readwrite) NSArray *units;
@property (nonatomic, assign, readwrite) int cost;

@end


@implementation UnitDefinition

- (instancetype) initWithType:(UnitDefinitionType)type {
    self = [super init];
    if (self) {
        self.type = type;

        switch (self.type) {
            case kInfantryBattalionDef:
                self.name = @"Infantry battalion";
                self.desc = @"HQ, 3 x infantry";
                self.units = @[@(kInfantryHeadquarterDef), @(kInfantryCompanyDef), @(kInfantryCompanyDef), @(kInfantryCompanyDef)];
                self.cost = 200;
                break;
            case kAssaultInfantryBattalionDef:
                self.name = @"Assault infantry battalion";
                self.desc = @"HQ, 3 x assault infantry";
                self.units = @[@(kInfantryHeadquarterDef), @(kAssaultInfantryCompanyDef), @(kAssaultInfantryCompanyDef), @(kAssaultInfantryCompanyDef)];
                self.cost = 250;
                break;
            case kCavalryBattalionDef:
                self.name = @"Cavalry battalion";
                self.desc = @"HQ, 3 x cavalry";
                self.units = @[@(kCavalryHeadquarterDef), @(kCavalryCompanyDef), @(kCavalryCompanyDef), @(kCavalryCompanyDef)];
                self.cost = 250;
                break;
            case kInfantryCompanyDef:
                self.name = @"Infantry company";
                self.desc = @"";
                self.units = @[@(kInfantryCompanyDef)];
                self.cost = 80;
                break;
            case kAssaultInfantryCompanyDef:
                self.name = @"Assault infantry company";
                self.desc = @"";
                self.units = @[@(kAssaultInfantryCompanyDef)];
                self.cost = 100;
                break;
            case kCavalryCompanyDef:
                self.name = @"Cavalry company";
                self.desc = @"";
                self.units = @[@(kCavalryCompanyDef)];
                self.cost = 100;
                break;
            case kLightArtilleryBattalionDef:
                self.name = @"Light artillery battalion";
                self.desc = @"HQ, 3 x light artilery";
                self.units = @[@(kInfantryHeadquarterDef), @(kLightArtilleryBatteryDef), @(kLightArtilleryBatteryDef), @(kLightArtilleryBatteryDef)];
                self.cost = 250;
                break;
            case kHeavyArtilleryBattalionDef:
                self.name = @"Heavy artillery battalion";
                self.desc = @"HQ, 2 x heavy artilery";
                self.units = @[@(kInfantryHeadquarterDef), @(kHeavyArtilleryBatteryDef), @(kHeavyArtilleryBatteryDef)];
                self.cost = 300;
                break;
            case kHowitzerArtilleryBattalionDef:
                self.name = @"Howitzer artillery battalion";
                self.desc = @"HQ, 2 x howitzer";
                self.units = @[@(kInfantryHeadquarterDef), @(kHowitzerArtilleryBatteryDef), @(kHowitzerArtilleryBatteryDef)];
                self.cost = 300;
                break;

            case kInfantryHeadquarterDef:
            case kCavalryHeadquarterDef:
                NSAssert( NO, @"invalid unit definition" );
                break;

            case kLightArtilleryBatteryDef:
                self.name = @"Light artillery battery";
                self.desc = @"";
                self.units = @[@(kLightArtilleryBatteryDef)];
                self.cost = 100;
                break;
            case kHeavyArtilleryBatteryDef:
                self.name = @"Heavy artillery battery";
                self.desc = @"";
                self.units = @[@(kHeavyArtilleryBatteryDef)];
                self.cost = 150;
                break;
            case kHowitzerArtilleryBatteryDef:
                self.name = @"Howitzer artillery battery";
                self.desc = @"";
                self.units = @[@(kHowitzerArtilleryBatteryDef)];
                self.cost = 150;
                break;
            case kSupportCompanyDef:
                self.name = @"Support company";
                self.desc = @"HQ, 2 x MG, mortar";
                self.units = @[@(kInfantryHeadquarterDef), @(kMachineGunTeamDef), @(kMachineGunTeamDef), @(kMortarTeamDef)];
                self.cost = 150;
                break;
            case kMachineGunTeamDef:
                self.name = @"Machine gun team";
                self.desc = @"";
                self.units = @[@(kMachineGunTeamDef)];
                self.cost = 60;
                break;
            case kSniperTeamDef:
                self.name = @"Sniper team";
                self.desc = @"";
                self.units = @[@(kSniperTeamDef)];
                self.cost = 50;
                break;
            case kMortarTeamDef:
                self.name = @"Mortar team";
                self.desc = @"";
                self.units = @[@(kMortarTeamDef)];
                self.cost = 50;
                break;
            case kFlamethrowerTeamDef:
                self.name = @"Flamethrower team";
                self.desc = @"";
                self.units = @[@(kFlamethrowerTeamDef)];
                self.cost = 50;
                break;
        }
    }

    return self;
}


+ (NSString *) name:(UnitDefinitionType)type {
    switch (type) {
        case kInfantryBattalionDef:
            return @"Infantry battalion";

        case kAssaultInfantryBattalionDef:
            return @"Assault infantry battalion";

        case kCavalryBattalionDef:
            return @"Cavalry battalion";

        case kInfantryCompanyDef:
            return @"Infantry company";

        case kAssaultInfantryCompanyDef:
            return @"Assault infantry company";

        case kCavalryCompanyDef:
            return @"Cavalry company";

        case kInfantryHeadquarterDef:
            return @"Infantry HQ";

        case kCavalryHeadquarterDef:
            return @"Cavalry HQ";

        case kLightArtilleryBattalionDef:
            return @"Light artillery battalion";

        case kHeavyArtilleryBattalionDef:
            return @"Heavy artillery battalion";

        case kHowitzerArtilleryBattalionDef:
            return @"Howitzer artillery battalion";

        case kLightArtilleryBatteryDef:
            return @"Light artillery battery";

        case kHeavyArtilleryBatteryDef:
            return @"Heavy artillery battery";

        case kHowitzerArtilleryBatteryDef:
            return @"Howitzer artillery battery";

        case kSupportCompanyDef:
            return @"Support company";

        case kMachineGunTeamDef:
            return @"Machine gun team";

        case kSniperTeamDef:
            return @"Sniper team";

        case kMortarTeamDef:
            return @"Mortar team";

        case kFlamethrowerTeamDef:
            return @"Flamethrower team";

        default:
            NSAssert( NO, @"unknown unit definition" );
    }
}

@end