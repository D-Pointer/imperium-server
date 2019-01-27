

#import "Definitions.h"

@interface Objective : NSObject

@property (nonatomic, assign) int            objectiveId;
@property (nonatomic, strong) NSString *     title;
@property (nonatomic, assign) ObjectiveState state;
@property (nonatomic, assign) CGPoint        position;

// check if an objective was clicked
- (BOOL) isHit:(CGPoint)pos;

+ (void) updateOwnerForAllObjectives;

+ (Objective *) create;

@end
