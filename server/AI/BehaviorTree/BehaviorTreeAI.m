
#import "BehaviorTreeAI.h"
#import "Globals.h"
#import "StrategicPlanner.h"
#import "Scenario.h"
#import "BehaviorTree.h"
#import "BehaviorTreeContext.h"
#import "Organization.h"
#import "PotentialField.h"
#import "ActionNode.h"
#import "GameLayer.h"
#import "NodeResult.h"

// strategic planners
#import "OffensiveStrategicPlanner.h"
#import "DefensiveStrategicPlanner.h"
#import "MeetingStrategicPlanner.h"


@interface BehaviorTreeAI ()

@property (nonatomic, strong) PotentialField *        potentialField;
@property (nonatomic, strong) StrategicPlanner *      strategicPlanner;
@property (nonatomic, strong) BehaviorTree *          behaviorTree;
@property (nonatomic, strong) BehaviorTreeContext *   context;

@property (nonatomic, assign) int updatePotentialFieldInterval;
@property (nonatomic, assign) int updateStrategicPlannerInterval;
@property (nonatomic, assign) int updateCount;

// blackboards for all AI units
@property (nonatomic, strong) NSMutableDictionary * blackboards;

@end


@implementation BehaviorTreeAI

- (id) init {
    self = [super init];

    if (self) {
        // first update
        self.updateCount = 0;

        // update everything now
        self.updatePotentialFieldInterval         = sParameters[kParamUpdatePotentialFieldIntervalI].intValue;
        self.updateStrategicPlannerInterval       = sParameters[kParamUpdateStrategicPlannerIntervalI].intValue;

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

        self.blackboards = [[NSMutableDictionary alloc] initWithCapacity:[Globals sharedInstance].unitsPlayer2.count];

        // set up the behavior tree
        self.behaviorTree = [BehaviorTree new];

        // context
        self.context = [BehaviorTreeContext new];
        self.context.potentialField = self.potentialField;

        // load the scenario specific file first
        if ( ! [self.behaviorTree readTree:[NSString stringWithFormat:@"%d.bt", [Globals sharedInstance].scenario.scenarioId]] ) {
            // failed to read the scenario specific file
            CCLOG( @"no scenario specific behavior tree found, trying the generic one" );
            if ( ! [self.behaviorTree readTree:@"Generic.bt"] ) {
                CCLOG( @"failed to read generic AI behavior tree" );
                NSAssert( NO, @"failed to read generic AI behavior tree");
            }
        }
    }

    return self;
}


- (void) execute {
    // should we update all potential fields?
    if ( self.updateCount == 0 || (self.updateCount % self.updatePotentialFieldInterval == 0) ) {
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
    if ( self.updateCount == 0 || (self.updateCount % self.updateStrategicPlannerInterval == 0)  ) {
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

        //CCLOG( @"update %d, %@, count: %d", self.updateCount, unit, unit.aiUpdateCounter );

        // only update units every n:th time
        if ( unit.aiUpdateCounter > 0 ) {
            unit.aiUpdateCounter--;
            continue;
        }

        // reset the interval
        unit.aiUpdateCounter = sParameters[kParamAiExecutionIntervalI].intValue;

        // update context
        self.context.unit = unit;
        self.context.elapsedTime = globals.clock.elapsedTime;

        // prepare the blackboard for the unit
        [self prepareBlackboardForUnit:self.context.unit];

        CCLOG( @"update %d, checking nodes for: %@", self.updateCount, unit );

        [self.behaviorTree executeWithContext:self.context];

        // any executed action?
        if ( self.context.blackboard.executedAction ) {
            CCLOG( @"unit %@, executed action: %@", unit, NSStringFromClass( [self.context.blackboard.executedAction class] ) );
            if ( sAIDebugging ) {
                dispatch_async( dispatch_get_main_queue(), ^(void) {
                    if ( unit.aiDebugging ) {
                        [unit.aiDebugging setString:NSStringFromClass( [self.context.blackboard.executedAction class] ) ];
                    }
                    else {
                        unit.aiDebugging = [CCLabelBMFont labelWithString:NSStringFromClass( [self.context.blackboard.executedAction class] )
                                                                  fntFile:@"DebugFont.fnt"];
                        unit.aiDebugging.position = ccpAdd( unit.position, ccp( 0, -20) );
                        [[Globals sharedInstance].mapLayer addChild:unit.aiDebugging z:kAIDebugZ];
                    }
                } );
                
            }
        }

        CCLOG( @"visited %lu nodes", (unsigned long)self.context.blackboard.trace.count );

        if ( sAIDebugging ) {
            for ( NodeResult * result in self.context.blackboard.trace ) {
                CCLOG( @"visited node: %@", result );
            }
        }

        // updated for one more unit
        updatedUnitsCount++;
    }

    //CCLOG( @"updated rules for %d units of %lu", updatedUnitsCount, (unsigned long)globals.unitsPlayer2.count );
}


- (void) prepareBlackboardForUnit:(Unit *)unit {
    Blackboard * blackboard = self.blackboards[ @(unit.unitId) ];

    // no blackboard yet?
    if ( blackboard == nil ) {
        blackboard = [Blackboard new];
        self.blackboards[ @(unit.unitId) ] = blackboard;
    }

    self.context.blackboard = blackboard;

    // update all data
    [self updateEnemies:blackboard forUnit:unit];
    [self updateRallyableUnits:blackboard forUnit:unit];
}


- (void) updateEnemies:(Blackboard *)blackboard forUnit:(Unit *)unit {
    float closestInRangeDistance = MAXFLOAT;
    float closestInFieldOfFireDistance = MAXFLOAT;

    // check all enemies that the unit sees
    for ( unsigned int index = 0; index < unit.losData.seenCount; ++index ) {
        Unit * enemy = [unit.losData getSeenUnit:index];

        // distance to the target
        float distance = ccpDistance( unit.position, enemy.position );

        // inside firing range?
        if ( distance <= unit.weapon.firingRange ) {
            [blackboard.enemiesInRange addObject:enemy];
            
            // new closest in range?
            if ( distance < closestInRangeDistance ) {
                closestInRangeDistance = distance;
                blackboard.closestEnemyInRange = enemy;
            }

            // inside field of fire?
            if ( [unit isInsideFiringArc:enemy.position checkDistance:NO] ) {
                [blackboard.enemiesInFieldOfFire addObject:enemy];

                // new closest in field of fire?
                if ( distance < closestInFieldOfFireDistance ) {
                    closestInFieldOfFireDistance = distance;
                    blackboard.closestEnemyInFieldOfFire = enemy;
                }
            }
        }
    }

    NSLog( @"units in range: %lu, units in field of fire: %lu", (unsigned long)blackboard.enemiesInRange.count, (unsigned long)blackboard.enemiesInFieldOfFire.count );
}


- (void) updateRallyableUnits:(Blackboard *)blackboard forUnit:(Unit *)unit {
    float closestDistance = MAXFLOAT;

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
        [blackboard.rallyableUnits addObject:subordinate];

        // new closest rallyable unit?
        float distance = ccpDistance( unit.position, subordinate.position );
        if ( distance < closestDistance ) {
            closestDistance = distance;
            blackboard.closestRallyableUnit = subordinate;
        }
        
        break;
    }

}

@end
