
#import "StrategicPlanner.h"
#import "Globals.h"
#import "Definitions.h"
#import "Organization.h"
#import "EnemyGroup.h"
#import "Objective.h"
#import "Scenario.h"
#import "PotentialField.h"

/**
 * Compares two objectives based on their value.
 **/
static NSInteger compareObjectives (id objective1, id objective2, void * context) {
    // the map is always an influencemap
    Objective * obj1 = (Objective *)objective1;
    Objective * obj2 = (Objective *)objective2;

    CCLOG( @"comparing %@ to %@ -> %f to %f", obj1.title, obj2.title, obj1.aiValue, obj2.aiValue );

    if ( obj1.aiValue < obj2.aiValue ) {
        return NSOrderedAscending;
    }
    else if ( obj1.aiValue > obj2.aiValue ) {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}


@implementation StrategicPlanner

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ownOrganizations = [CCArray new];
        self.enemyGroups      = [CCArray new];
        self.ruleSystemState = [NSMutableDictionary new];
    }
    return self;
}


- (void) executeWithPotentialField:(PotentialField *)field {
    self.aiPlayer   = kPlayer2;
    self.ownUnits   = [Globals sharedInstance].unitsPlayer2;
    self.enemyUnits = [Globals sharedInstance].unitsPlayer1;

    // clear data
    [self.ruleSystemState removeAllObjects];

    // first find all headquarters and the units belonging to them
    [self findOwnOrganizations];
    [self findEnemyGroups];
    //[self findOwnIndependents];

    // find the objetives that we should be targeting
    self.targetObjectives = [self findTargetObjectives:field];

    // find the power ratio. this is a ratio own/enemy, so 2 means we have double the men, 0.5 we have half
    [self findPowerRatio];

    // do strategic planning and allocate organizations to objectives
    [self performStrategicPlanning];
}


- (void) dealloc {
    // clear the arrays so that we don't retain things
    self.ownUnits = nil;
    self.enemyUnits = nil;
    self.ownOrganizations = nil;
    self.enemyGroups = nil;
    self.targetObjectives = nil;
}


- (void) findOwnOrganizations {
    [self.ownOrganizations removeAllObjects];

    // find all headquarters and their subordinate units. this will use headquarters that are destroyed too
    for ( Organization * organization in [Globals sharedInstance].organizations ) {
        if ( organization.owner == kPlayer2 ) {
            CCLOG( @"updating data for own organization: %@", organization );

            // update its center of mass
            [organization updateCenterOfMass];

            // update its engagement state
            [organization updateEngagementState];

            // one more organization
            [self.ownOrganizations addObject:organization];
        }
    }

    CCLOG( @"found %lu own organizations", (unsigned long)self.ownOrganizations.count );
}


/*- (void) findOwnIndependents {
    //CCArray * independents = [CCArray new];
    int found = 0;

    // find all not destroyed units that are not headquarters and who have no headquarter
    for ( Unit * unit in self.ownUnits) {
        if ( ! unit.destroyed && ! unit.isHeadquarter && (unit.headquarter == nil || unit.headquarter.destroyed == YES) ) {
            [self.organizations addObject:[[Organization alloc] initWithIndependent:unit]];
            found++;
            //[independents addObject:unit];
        }
    }

    CCLOG( @"found %d independent units", found );
    //return independents;
}*/


- (void) findEnemyGroups {
    [self.enemyGroups removeAllObjects];

    // copy the array so that we can modify it
    CCArray * enemies = [[CCArray alloc] initWithArray:self.enemyUnits];

    CCLOG( @"enemy units: %ld", (unsigned long)enemies.count );

    // max distance a unit can be from a group in order to be considered in the group
    int distance = 100.0f;

    // loop while we have enemies not placed in a group
    while ( enemies.count > 0 ) {
        // take a unit out of the set
        Unit * enemy = [enemies lastObject];
        [enemies removeObject:enemy];

        // create a new group for it
        EnemyGroup * group = [[EnemyGroup alloc] initWithEnemy:enemy];
        [self.enemyGroups addObject:group];

        BOOL addedToGroup;

        // now loop all other enemies and try to fit them into the group until no enemy was added. as long
        // as at least one enemy was added to the group we loop again, as others may then fit in
        do {
            addedToGroup = NO;

            // now check all enemies to see if one would fit in the group
            for ( Unit * tmp in enemies ) {
                if ( [group is:tmp closerThan:distance] ) {
                    // close enough, add to the group
                    [group.enemies addObject:tmp];
                    [enemies removeObject:tmp];
                    addedToGroup = YES;
                }
            }
        } while ( addedToGroup );
    }

    // DEBUG
    for ( EnemyGroup * group in self.enemyGroups ) {
        CCLOG( @"group with %ld enemies", (unsigned long)group.enemies.count );
    }
}


- (CCArray *) findTargetObjectives:(PotentialField *)field {
    CCArray * targets = [CCArray new];

    // check each objective to see which objectives are in danger
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        switch ( objective.state ) {
            case kNeutral:
            case kContested:
                // contested are ok targets
                [targets addObject:objective];
                break;

            case kOwnerPlayer1:
                // enemy owned are also good
                [targets addObject:objective];
                break;

            case kOwnerPlayer2:
                // skip our own
                break;
        }
    }

    // TODO: can this cause oscillation? Units hold an objective, move away towards a better objective, the old one becomes
    // neutral, the units move back, repeat

    // DEBUG
    for ( Objective * objective in targets ) {
        // TODO: this is a bit bogus
        objective.aiValue = [field getValue:objective.position]; 
        CCLOG( @"potential target: %@, value: %f", objective.title, objective.aiValue );
    }

    // how much strength does the enemy have at each target? sort the array based on the strengths at the
    // positions for the objectives
    [targets sortUsingFunction:compareObjectives context:nil];

    for ( Objective * objective in targets ) {
        CCLOG( @"sorted target: %@, value: %f", objective.title, objective.aiValue );
    }

    return targets;
}


- (void) findPowerRatio {
    // simply count the men of both sides
    int ownMen = 0;
    int enemyMen = 0;
    NSUInteger ownUnitCount = self.ownUnits.count;
    NSUInteger enemyUnitCount = self.enemyUnits.count;

    for ( Unit * unit in self.ownUnits) {
        ownMen += unit.men;
    }

    for ( Unit * unit in self.enemyUnits) {
        enemyMen += unit.men;
    }

    self.ruleSystemState[ @"ownUnitCount" ]   = @(ownUnitCount);
    self.ruleSystemState[ @"enemyUnitCount" ] = @(enemyUnitCount);
    self.ruleSystemState[ @"ownMenCount" ]    = @(ownMen);
    self.ruleSystemState[ @"enemyMenCount" ]  = @(enemyMen);

    float unitRatio = 1000;
    float menRatio = 1000;

    if ( self.ownUnits.count > 0 ) {
        unitRatio = (float)enemyUnitCount / (float)ownUnitCount;
    }

    if ( ownMen > 0 ) {
       menRatio = (float)enemyMen / (float)ownMen;
    }

    self.ruleSystemState[ @"unitRatio" ] = @(unitRatio);
    self.ruleSystemState[ @"menRatio" ] = @(menRatio);

    CCLOG( @"own: %d men, %lu units. enemies: %d men, %lu units, ratio: %.2f men, %.2f units", ownMen, (unsigned long)ownUnitCount, enemyMen, (unsigned long)enemyUnitCount, menRatio, unitRatio);
}


- (void) performStrategicPlanning {
    NSAssert( NO, @"Must be overridden" );
}


- (Organization *) findClosestOrganizationTo:(Objective *)objective {
    float closestDistance = 100000.0f;
    Organization * closestOrganization = nil;

    // check the distance to all our organizations
    for ( Organization * organization in self.ownOrganizations ) {
        // does this already have an objective? we can't allocate an organization to
        // two objectives
        if ( organization.objective != nil ) {
            continue;
        }

        // is it already engaged?
        if ( organization.engaged ) {
            continue;
        }

        float distance = ccpDistance( organization.centerOfMass, objective.position );
        if ( distance < closestDistance ) {
            // new closest organization
            closestOrganization = organization;
            closestDistance = distance;
        }
    }

    return closestOrganization;
}

@end
