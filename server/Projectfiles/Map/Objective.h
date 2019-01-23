
#import "cocos2d.h"
#import "Definitions.h"

@interface Objective : CCSprite

@property (nonatomic, assign) int            objectiveId;
@property (nonatomic, strong) NSString *     title;
@property (nonatomic, assign) ObjectiveState state;
@property (nonatomic, assign) float          aiValue;

// check if an objective was clicked
- (BOOL) isHit:(CGPoint)pos;

+ (void) updateOwnerForAllObjectives;

+ (Objective *) create;

@end
