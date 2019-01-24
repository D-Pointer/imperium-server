
#import "OffensiveStrategicPlanner.h"
#import "Globals.h"
#import "Organization.h"

@implementation OffensiveStrategicPlanner

- (void) performStrategicPlanning {
    self.aggressiveness = kAggressiveAttacking;

    // clear all old objectives and orders
    for ( Organization * organization in self.ownOrganizations ) {
        // default to advance
        organization.order = kAdvanceTowardsEnemy;
        organization.objective = nil;
    }

    // we need to check each objective that is not our own so that the closest
    // organization advances on it
    for ( Objective * objective in self.targetObjectives ) {
        // find whatever organization is closest to the objective
        Organization * closestOrganization = [self findClosestOrganizationTo:objective];

        // anything found?
        if ( closestOrganization ) {
            // yes, it should go get the objective
            CCLOG( @"organization %@ order is objective %@", closestOrganization, objective.title );
            closestOrganization.objective = objective;
            closestOrganization.order = kTakeObjective;
        }
        else {
            CCLOG( @"no free organization for objective %@", objective.title );
        }
    }

    // all organizations that did not get an objective should advance
    for ( Organization * organization in self.ownOrganizations ) {
        if ( organization.objective == nil ) {
            organization.order = kAdvanceTowardsEnemy;
            CCLOG( @"organization %@ got advance order", organization.headquarter );
        }
    }
}

@end
