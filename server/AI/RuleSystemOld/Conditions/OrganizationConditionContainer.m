
#import "OrganizationConditionContainer.h"
#import "OrganizationSpecificCondition.h"

@implementation OrganizationConditionContainer

- (instancetype) initWithOrganization:(Organization *)organization {
    self = [super init];
    if (self) {
        self.organization = organization;

        self.shouldAdvance       = [[ShouldAdvance alloc] initWithOrganization:organization];
        self.shouldHold          = [[ShouldHold alloc] initWithOrganization:organization];
        self.shouldTakeObjective = [[ShouldTakeObjective alloc] initWithOrganization:organization];
        self.isHeadquarterAlive  = [[IsHeadquarterAlive alloc] initWithOrganization:organization];

        // a convenient list of all conditions
        self.organizationConditions = @[ self.shouldAdvance,
                                         self.shouldHold,
                                         self.shouldTakeObjective,
                                         self.isHeadquarterAlive
                                         ];

        CCLOG( @"set up %lu organization specific conditions for %@", (unsigned long)self.organizationConditions.count, organization );
    }

    return self;
}


- (void) update {
    CCLOG( @"updating conditions for organization %@", self.organization );

    for ( OrganizationSpecificCondition * condition in self.organizationConditions ) {
        [condition update];
        CCLOG( @"condition %@ == %@", condition.name, condition.isTrue ? @"yes" : @"no" );
    }
}

@end
