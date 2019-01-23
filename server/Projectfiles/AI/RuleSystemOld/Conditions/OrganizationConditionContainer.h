
#import "Globals.h"

@class Organization;

#import "ShouldAdvance.h"
#import "ShouldHold.h"
#import "ShouldTakeObjective.h"
#import "IsHeadquarterAlive.h"

@interface OrganizationConditionContainer : NSObject

// the organization we operate on
@property (nonatomic, weak)   Organization *          organization;

// organization specific conditions
@property (nonatomic, strong) ShouldAdvance *         shouldAdvance;
@property (nonatomic, strong) ShouldHold *            shouldHold;
@property (nonatomic, strong) ShouldTakeObjective *   shouldTakeObjective;
@property (nonatomic, strong) IsHeadquarterAlive *    isHeadquarterAlive;
@property (nonatomic, strong) NSArray *               organizationConditions;

- (instancetype) initWithOrganization:(Organization *)organization;

/**
 * Updates the conditions.
 **/
- (void) update;

@end
