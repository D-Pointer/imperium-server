
#import "RuleSystemAI.h"
#import "UnitContext.h"
#import "Globals.h"
#import "Scenario.h"
#import "Organization.h"
#import "PotentialField.h"
#import "GameLayer.h"

// state data
#import "Clock.h"
#import "RallyableUnitsState.h"
#import "EnemiesState.h"

// rules
#import "AreAllObjectivesHeld.h"
#import "AttackScenario.h"
#import "BeginningOfGame.h"
#import "DefendScenario.h"
#import "FirstTurn.h"
#import "MeetingScenario.h"
#import "IsHeadquarterAlive.h"
#import "ShouldAdvance.h"
#import "ShouldHold.h"
#import "ShouldTakeObjective.h"

// strategic planners
#import "OffensiveStrategicPlanner.h"
#import "DefensiveStrategicPlanner.h"
#import "MeetingStrategicPlanner.h"

@interface RuleSystemAI ()

@property (nonatomic, strong) PotentialField *        potentialField;
@property (nonatomic, strong) StrategicPlanner *      strategicPlanner;

@property (nonatomic, assign) int updatePotentialFieldInterval;
@property (nonatomic, assign) int updateStrategicPlannerInterval;
@property (nonatomic, assign) int updateCount;

// contexts for all AI units
@property (nonatomic, strong) NSMutableDictionary * unitContexts;

// all state instances, one for each type
@property (nonatomic, strong) NSArray * states;

@property (nonatomic, strong) GKRuleSystem * ruleSystem;

@end


@implementation RuleSystemAI

- (id) init {
    self = [super init];

    if (self) {
        // first update
        self.updateCount = 0;

        // update everything now
        self.updatePotentialFieldInterval   = sParameters[kParamUpdatePotentialFieldIntervalI].intValue;
        self.updateStrategicPlannerInterval = sParameters[kParamUpdateStrategicPlannerIntervalI].intValue;

        // potential field
        self.potentialField = [PotentialField new];

        switch( [Globals sharedInstance].scenario.aiHint ) {
            case kPlayer2Attacks:
                // we're attacking
                self.strategicPlanner = [OffensiveStrategicPlanner new];
                break;

            case kMeetingEngagement:
                // meeting engagement
                self.strategicPlanner = [MeetingStrategicPlanner new];
                break;

            case kPlayer1Attacks:
                // defensive
                self.strategicPlanner = [DefensiveStrategicPlanner new];
        }

        // space for unit contexts
        self.unitContexts = [[NSMutableDictionary alloc] initWithCapacity:[Globals sharedInstance].unitsPlayer2.count];

        // create the rule system
        self.ruleSystem = [[GKRuleSystem alloc] init];

        self.states = @[ [RallyableUnitsState new],
                         [EnemiesState new],
                         ];

        // create all rules
        [self.ruleSystem addRulesFromArray:@[
                                             // global
                                             [AreAllObjectivesHeld new],
                                             [DefendScenario new],
                                             [AttackScenario new],
                                             [FirstTurn new],
                                             [BeginningOfGame new],
                                             [MeetingScenario new],

                                             // organizational
                                             [IsHeadquarterAlive new],
                                             [ShouldAdvance new],
                                             [ShouldHold new],
                                             [ShouldTakeObjective new]
                                             ]];
    }

    return self;
}


- (void) execute {
    CCLOG( @"starting AI update %d", self.updateCount );

    // should we update all potential fields?
    if ( self.updateCount % self.updatePotentialFieldInterval == 0 ) {
        CCLOG( @"updating potential fields" );
        [self.potentialField updateField];

        // DEBUG
        if ( sPotentialFieldDebugging ) {
            CCLOG( @"debugging potential fields" );
            [self.potentialField performSelectorOnMainThread:@selector(showDebugInfo) withObject:nil waitUntilDone:YES];
            CCLOG( @"debugging potential fields done" );
        }
    }

    // should we update the strategic planner?
    if ( self.updateCount % self.updateStrategicPlannerInterval == 0 ) {
        CCLOG( @"performing strategic planning" );
        [self.strategicPlanner executeWithPotentialField:self.potentialField];
    }

    // one more update done
    self.updateCount++;

    Globals * globals = [Globals sharedInstance];

    // number of units updated
    int updatedUnitsCount = 0;

    // match rules for all our units
    for ( Unit * unit in globals.unitsPlayer2 ) {
        // only handle alive units
        if ( unit.destroyed ) {
            continue;
        }

        // only update units every n:th time
        if ( unit.aiUpdateCounter > 0 ) {
            unit.aiUpdateCounter--;
            continue;
        }

        CCLOG( @"update %d, %@", self.updateCount, unit );

        // reset the interval
        unit.aiUpdateCounter = sParameters[kParamAiExecutionIntervalI].intValue;

        // clear the rule system
        [self.ruleSystem reset];

        // set up state
        [self updateState:unit];

        [self.ruleSystem evaluate];

        for (NSString * fact in self.ruleSystem.facts ) {
            CCLOG( @"fact: %@ = %.2f", fact, [self.ruleSystem gradeForFact:fact] );
        }

        [self determineAction];

        if ( sAIDebugging ) {
            dispatch_async( dispatch_get_main_queue(), ^(void) {
                if ( unit.aiDebugging ) {
                    [unit.aiDebugging setString:@"Action" ];
                }
                else {
                    unit.aiDebugging = [CCLabelBMFont labelWithString:@"Action"
                                                              fntFile:@"DebugFont.fnt"];
                    unit.aiDebugging.position = ccpAdd( unit.position, ccp( 0, -20) );
                    [[Globals sharedInstance].mapLayer addChild:unit.aiDebugging z:kAIDebugZ];
                }
            } );
        }

        // updated for one more unit
        updatedUnitsCount++;
    }

    //CCLOG( @"updated rules for %d units of %lu", updatedUnitsCount, (unsigned long)globals.unitsPlayer2.count );
}


- (void) updateState:(Unit *)unit {
    UnitContext * context = self.unitContexts[ @(unit.unitId) ];

    // no blackboard yet?
    if ( context == nil ) {
        context = [UnitContext new];
        context.unit = unit;
        self.unitContexts[ @(unit.unitId) ] = context;
    }

    // set up all state from the strategic planner. This is the same for all units
    for ( NSString * stateName in self.strategicPlanner.ruleSystemState ) {
        self.ruleSystem.state[ stateName ] = self.strategicPlanner.ruleSystemState[stateName];
    }

    // global data
    self.ruleSystem.state[ @"scenarioType" ] = @([Globals sharedInstance].scenario.aiHint);
    self.ruleSystem.state[ @"battleSize" ]   = @([Globals sharedInstance].scenario.battleSize);
    self.ruleSystem.state[ @"time" ]         = @([Globals sharedInstance].clock.elapsedTime);

    // organizational data
    self.ruleSystem.state[ @"organization" ] = context.unit.organization;
    self.ruleSystem.state[ @"unit" ]         = context.unit;

    // all advanced state
    for ( State * state in self.states ) {
        [state update:context forRuleSystem:self.ruleSystem];
    }

//    context.ruleSystem.state[ OrgOrder ]         = @(context.unit.organization.order);
//    context.ruleSystem.state[ OrgHq ]            = context.unit.organization.headquarter;
//    context.ruleSystem.state[ OrgObjective ]     = context.unit.organization.objective;
//    context.ruleSystem.state[ OrgEngaged ]       = @(context.unit.organization.engaged);

    // update all data
    //[self updateEnemies:context.unit];
    //[self updateRallyableUnits:context.unit];

    CCLOG( @"state: %@", self.ruleSystem.state );
}


- (void) determineAction {

}

//    [GKRule ruleWithPredicate:[NSPredicate predicateWithFormat:@"$scenarioType == 0"] assertingFact:@"hold" grade:0.5]];
//    [self.ruleSystem addRule:[GKRule ruleWithPredicate:[NSPredicate predicateWithFormat:@"($scenarioType == 1) OR ($scenarioType == 2)"] assertingFact:@"attack" grade:0.5]];

    // vulnerability of current unit
    

/*
- (void) updateEnemies:(Unit *)unit {
    float closestInRangeDistance = MAXFLOAT;
    float closestInFieldOfFireDistance = MAXFLOAT;

    NSMutableArray * enemiesInRange = [NSMutableArray new];
    NSMutableArray * enemiesInFieldOfFire = [NSMutableArray new];
    Unit * closestEnemyInRange = nil;
    Unit * closestEnemyInFieldOfFire = nil;

    // check all enemies that the unit sees
    for ( unsigned int index = 0; index < unit.losData.seenCount; ++index ) {
        Unit * enemy = [unit.losData getSeenUnit:index];

        // distance to the target
        float distance = ccpDistance( unit.position, enemy.position );

        // inside firing range?
        if ( distance <= unit.weapon.firingRange ) {
            [enemiesInRange addObject:enemy];
            
            // new closest in range?
            if ( distance < closestInRangeDistance ) {
                closestInRangeDistance = distance;
                closestEnemyInRange = enemy;
            }

            // inside field of fire?
            if ( [unit isInsideFiringArc:enemy.position checkDistance:NO] ) {
                [enemiesInFieldOfFire addObject:enemy];

                // new closest in field of fire?
                if ( distance < closestInFieldOfFireDistance ) {
                    closestInFieldOfFireDistance = distance;
                    closestEnemyInFieldOfFire = enemy;
                }
            }
        }
    }

    self.ruleSystem.state[ @"enemiesInRange" ]            = enemiesInRange;
    self.ruleSystem.state[ @"enemiesInFieldOfFire" ]      = enemiesInFieldOfFire;
    self.ruleSystem.state[ @"closestEnemyInRange" ]       = closestEnemyInRange;
    self.ruleSystem.state[ @"closestEnemyInFieldOfFire" ] = closestEnemyInFieldOfFire;

    NSLog( @"units in range: %lu, units in field of fire: %lu", (unsigned long)enemiesInRange.count, (unsigned long)enemiesInFieldOfFire.count );
}


- (void) updateRallyableUnits:(Unit *)unit {
    float closestDistance = MAXFLOAT;

    // default to no units
    self.ruleSystem.state[ @"rallyableUnits" ] = nil;
    self.ruleSystem.state[ @"closestRallyableUnit" ] = nil;

    if ( unit.type != kInfantryHeadquarter && unit.type != kCavalryHeadquarter) {
        return;
    }

    // if we're already rallying then we don't rally again to avoid the target being flipped every single
    // time this is updated
    if ( unit.mission.type == kRallyMission ) {
        return;
    }

    if ( ! [unit canBeGivenMissions] ) {
        return;
    }

    // does it have an organization?
    Organization * organization = unit.organization;
    if ( organization == nil ) {
        return;
    }

    NSMutableArray * rallyableUnits = [NSMutableArray new];
    Unit * closestRallyableUnit = nil;

    // check all subordinates to find someone that needs rallying
    for ( Unit * subordinate in organization.units ) {
        if ( unit == subordinate ) {
            continue;
        }

        // is the morale of the subordinate unit low enough?
        if ( subordinate.morale >= sParameters[kParamMaxMoraleShakenF].floatValue ) {
            continue;
        }

        // is it in command?
        if ( ! subordinate.inCommand ) {
            continue;
        }

        // it also can have no mission apart from being disorganized
        if ( subordinate.mission.type != kIdleMission && subordinate.mission.type != kDisorganizedMission ) {
            continue;
        }

        // does the HQ see the unit?
        if  ( ! [unit.losData seesUnit:subordinate] ) {
            // hq does not see the unit, can't rally
            continue;
        }

        // cache the subordinate unit
        [rallyableUnits addObject:subordinate];

        // new closest rallyable unit?
        float distance = ccpDistance( unit.position, subordinate.position );
        if ( distance < closestDistance ) {
            closestDistance = distance;
            closestRallyableUnit = subordinate;
        }
        
        break;
    }

    self.ruleSystem.state[ @"rallyableUnits" ]            = rallyableUnits;
    self.ruleSystem.state[ @"closestRallyableUnit" ]      = closestRallyableUnit;

    NSLog( @"rallyable units: %lu", (unsigned long)rallyableUnits.count );
}
*/

@end
