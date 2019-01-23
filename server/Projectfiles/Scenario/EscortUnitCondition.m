
#import "EscortUnitCondition.h"
#import "Globals.h"
#import "Scenario.h"

@interface EscortUnitCondition ()

@property (nonatomic, assign) int         unitId;
@property (nonatomic, assign) int         objectiveId;
@property (nonatomic, weak)   Unit *      unit;
@property (nonatomic, weak)   Objective * objective;

@end

@implementation EscortUnitCondition

- (instancetype) initWithUnitId:(int)unitId objectiveId:(int)objectiveId {
    self = [super init];
    if (self) {
        self.unitId = unitId;
        self.unit = nil;
        self.objectiveId = objectiveId;
    }

    return self;
}


- (void) setup {
    // do we need to find the unit?
    for ( Unit * tmp in [Globals sharedInstance].units ) {
        if ( tmp.unitId == self.unitId ) {
            self.unit = tmp;
            break;
        }
    }

    // do we need to find the objective?
    for ( Objective * tmp in [Globals sharedInstance].objectives ) {
        if ( tmp.objectiveId == self.objectiveId ) {
            self.objective = tmp;
            break;
        }
    }

    NSAssert( self.unit != nil, @"did not find unit" );
    NSAssert( self.objective != nil, @"did not find objective" );
}


- (ScenarioState) check {
    if ( self.unit.destroyed ) {
        self.winner = kPlayer2;
        self.text = [NSString stringWithFormat:@"Scenario failed... The escorted unit %@ has been destroyed before it reached the destination.", self.unit.name];
        return kGameFinished;
    }

    // has it reached the destination
    if ( ccpDistance( self.unit.position, self.objective.position ) < sParameters[kParamEscortTargetRadiusF].floatValue ) {
        self.winner = kPlayer1;
        self.text = [NSString stringWithFormat:@"Scenario completed! The escorted unit %@ has reached the destination!", self.unit.name];
        return kGameFinished;
    }

    // not yet destroyed nor arrived
    return kGameInProgress;
}

@end
