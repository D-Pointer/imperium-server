#import <Foundation/Foundation.h>
#import "Definitions.h"

// type of unitDefinitions
typedef enum {
    kInfantryBattalionDef,
    kAssaultInfantryBattalionDef,
    kCavalryBattalionDef,
    kInfantryCompanyDef,
    kAssaultInfantryCompanyDef,
    kCavalryCompanyDef,
    kInfantryHeadquarterDef,
    kCavalryHeadquarterDef,

    kLightArtilleryBattalionDef,
    kHeavyArtilleryBattalionDef,
    kHowitzerArtilleryBattalionDef,
    kLightArtilleryBatteryDef,
    kHeavyArtilleryBatteryDef,
    kHowitzerArtilleryBatteryDef,

    kSupportCompanyDef,
    kMachineGunTeamDef,
    kSniperTeamDef,
    kMortarTeamDef,
    kFlamethrowerTeamDef,
} UnitDefinitionType;


@interface UnitDefinition : NSObject

@property (nonatomic, assign) UnitDefinitionType type;
@property (nonatomic, strong, readonly) NSString * name;
@property (nonatomic, strong, readonly) NSString * desc;
@property (nonatomic, strong, readonly) NSArray *units;
@property (nonatomic, assign, readonly) int cost;

- (instancetype) initWithType:(UnitDefinitionType)type;

+ (NSString *) name:(UnitDefinitionType)type;

@end
