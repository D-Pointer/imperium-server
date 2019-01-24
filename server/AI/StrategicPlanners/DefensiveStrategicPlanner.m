
#import "DefensiveStrategicPlanner.h"
#import "Globals.h"
#import "Organization.h"

@implementation DefensiveStrategicPlanner

- (void) performStrategicPlanning {
    self.aggressiveness = kDefensive;

    // clear all old objectives and orders
    for ( Organization * organization in self.ownOrganizations ) {
        organization.order = kHold;
        organization.objective = nil;
    }
}

@end
