
#import "cocos2d.h"

#import "UnitStrengthMap.h"
#import "FrontlineMap.h"
#import "TensionMap.h"
#import "InfluenceMap.h"
#import "VulnerabilityMap.h"
#import "ObjectivesMap.h"

@interface InfluenceMapContainer : NSObject

@property (nonatomic, strong) UnitStrengthMap *  aiStrength;
@property (nonatomic, strong) UnitStrengthMap *  humanStrength;
@property (nonatomic, strong) InfluenceMap *     influenceMap;
@property (nonatomic, strong) FrontlineMap *     frontlineMap;
//@property (nonatomic, strong) TensionMap *       tensionMap;
//@property (nonatomic, strong) VulnerabilityMap * vulnerabilityMap;
//@property (nonatomic, strong) ObjectivesMap *    objectivesMap;

- (void) updateMaps;

- (void) showDebugInfo;

@end
