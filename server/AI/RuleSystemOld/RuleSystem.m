
#import "RuleSystem.h"
#import "UnitConditionContainer.h"
#import "Organization.h"
#import "GlobalConditionContainer.h"

// all rules
#import "TakeObjective.h"
#import "Fire.h"
#import "Hold.h"
#import "ChangeMode.h"
#import "MoveForward.h"
#import "FallBack.h"
#import "FaceNearestEnemy.h"
#import "Assault.h"
#import "Bombard.h"
#import "Rally.h"

@implementation RuleSystem

- (instancetype) init {
    self = [super init];
    if (self) {
        // global conditions
        self.globalConditions = [GlobalConditionContainer new];

        CCArray * ownUnits = [Globals sharedInstance].unitsPlayer2;

        // set up the unit specific conditions
        self.unitConditions = [NSMutableDictionary dictionaryWithCapacity:ownUnits.count];
        for ( Unit * unit in ownUnits ) {
            self.unitConditions[ [NSNumber numberWithInt:unit.unitId] ] = [[UnitConditionContainer alloc] initWithUnit:unit];
        }

        CCLOG( @"set up %lu unit condition containers", (unsigned long)self.unitConditions.count );

        // create the rules
        self.rules = @[ [[FallBack alloc] initWithPriority:250],
                        [[Assault alloc] initWithPriority:210],
                        [[MoveForward alloc] initWithPriority:200],
                        [[TakeObjective alloc] initWithPriority:100],
                        [[Fire alloc] initWithPriority:90],
                        [[Bombard alloc] initWithPriority:85],
                        [[ChangeMode alloc] initWithPriority:80],
                        [[Rally alloc] initWithPriority:70],
                        [[FaceNearestEnemy alloc] initWithPriority:60],
                        [[Hold alloc] initWithPriority:10]
                        ];
    }

    return self;
}


- (void) updateGlobalConditions {
    // update all global conditions
    CCLOG( @"updating global conditions" );
    [self.globalConditions update];
}


- (void) updateOrganizationalConditions:(CCArray *)organizations {
    // updating all organization conditions
    CCLOG( @"updating organization specific conditions for %lu organizations", (unsigned long)organizations.count );
    for ( Organization * organization in organizations ) {
        [organization.conditions update];
    }
}


- (UnitConditionContainer *) updateConditionsForUnit:(Unit *)unit {
    // updating all unit conditions
    CCLOG( @"updating conditions for %@", unit );
    UnitConditionContainer * container = self.unitConditions[ [NSNumber numberWithInt:unit.unitId] ];
    [container update];

    // FUTURE: perform some reprioritization of all rules based on conditions?

    // sort all rules
//    self.rules = [self.rules sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        // just compare the priorities
//        return ((Rule *)obj1).priority > ((Rule *)obj2).priority ? NSOrderedAscending : NSOrderedDescending;
//    }];

    return container;
}

@end
