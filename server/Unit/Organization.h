

#import "Unit.h"
#import "Objective.h"

@interface Organization : NSObject

@property (nonatomic, weak)   Unit *    headquarter;
@property (nonatomic, strong)  NSMutableArray * units;
@property (nonatomic, assign) PlayerId  owner;

// extra AI data for an organization
@property (nonatomic, assign) CGPoint                          centerOfMass;
@property (nonatomic, assign) BOOL                             engaged;
@property (nonatomic, assign) AIOrganizationOrder              order;
@property (nonatomic, weak)   Objective *                      objective;

- (id) initWithHeadquarter:(Unit *)hq;

- (BOOL) containsUnit:(Unit *)unit;

/**
 * Clears all missions for all units in the organization.
 **/
- (void) clearMissions;

/**
 * Calculates the center of mass of the organization based on all units
 * and the amounts of men in them.
 **/
- (void) updateCenterOfMass;

/**
 * Checks the unit to see if it is currently engaged with nearby enemies. If it
 * is then it is not available for advancing tasks.
 **/
- (void) updateEngagementState;

@end
