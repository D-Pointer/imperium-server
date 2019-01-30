
#import "MeleeMission.h"
#import "RotateMission.h"
#import "DisorganizedMission.h"
#import "Unit.h"
#import "Globals.h"
#import "Map.h"


@implementation MeleeMission


- (id) init {
    self = [super init];
    if (self) {
        self.type = kMeleeMission;
        self.name = @"Meleeing";
        self.preparingName = @"Preparing to melee";
        self.targetUnit = nil;
        self.rotation = nil;

        // this can not be cancelled by the player
        self.canBeCancelled = NO;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamMeleeFatigueEffectF].floatValue;
    }
    
    return self;
}


- (id) initWithTarget:(Unit *)target {
    self = [super init];
    if (self) {
        self.type       = kMeleeMission;
        self.name       = @"Meleeing";
        self.preparingName = @"Preparing to melee";
        self.endPoint   = target.position;
        self.targetUnit = target;

        // this can not be cancelled by the player
        self.canBeCancelled = NO;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamMeleeFatigueEffectF].floatValue;
    }
    
    return self;
}


- (float) commandDelay {
    // this never has any delay
    return -1;
}


- (MissionState) execute {
    // has the target died? it can have been killed by another unit
    if ( self.targetUnit == nil || self.targetUnit.destroyed ) {
        return kCompleted;
    }

    NSLog( @"melee %@ -> %@", self.unit.name, self.targetUnit.name );

    // is the target too far away?
    if ( ccpDistance( self.unit.position, self.targetUnit.position ) > sParameters[kParamMeleeMaxDistanceF].floatValue ) {
        // we're done
        NSLog( @"target too far away, melee done");
        return kCompleted;        
    }

    // do the melee
    [self melee:self.unit defender:self.targetUnit];

    // did the target die or retreat?
    if ( self.targetUnit.destroyed || [self.targetUnit isCurrentMission:kRetreatMission] ) {
        // the attacker is now disorganized too
        NSLog( @"target destroyed, attacker not retreating, setting to disorganized" );
        self.unit.mission = [DisorganizedMission new];

        // note that we return "in progress" here, otherwise the engine thinks the new disorganized mission is the
        // one that completed and removes it instead
        return kInProgress;
    }

    // still going
    return kInProgress;
}


- (void) melee:(Unit *)attacker defender:(Unit *)defender {
    float attackerStrength = [self getMeleeStrengthFor:attacker];
    float defenderStrength = [self getMeleeStrengthFor:defender];

    NSLog( @"attacker strength: %.1f", attackerStrength );
    NSLog( @"defender strength: %.1f", defenderStrength );

    // deliver casualties
    int defenderStartMen = defender.men;
    int defenderCasualties;
    int defenderMaxCasualties;
    float defenderRetreatProbability;
    BOOL defenderRouts;
    float percentageLost;

    // check for weak defender and avoid division by 0
    if ( defenderStrength < 0.01 ) {
        // defender is too weak and will be destroyed
        defenderCasualties = defenderStartMen;
        defenderRouts = NO;

        // lost all men
        percentageLost = 100;
    }
    else {
        // calculate a ratio of strength
        // 0.1 -> 1.0 = defender stronger
        // 1.0 -> 10.0 = attacker stronger
        float ratio = attackerStrength / defenderStrength;

        // keep within the boundaries
        ratio = clampf( ratio, 0.1, 10.0 );

        // calculate the max casualties and retreat probability for the defender
        [self calculateDefenderLossesForRatio:ratio maxCasualties:&defenderMaxCasualties retreatProbability:&defenderRetreatProbability];

        // real casualties
        defenderCasualties = arc4random_uniform( defenderMaxCasualties + 1 );

        // keep the casualties less than the max number of men
        defenderCasualties = MIN( defenderCasualties, defenderStartMen );

        percentageLost = (float)defenderCasualties / (float)defenderStartMen * 100;

        // is the defender not in command?
        if ( ! defender.inCommand ) {
            percentageLost *= sParameters[kParamMoraleLossNotInCommandF].floatValue;
            NSLog( @"not in command, increasing morale loss: %.1f%%", percentageLost );
        }

        // is the defender disorganized or retreating?
        if ( [defender isCurrentMission:kDisorganizedMission] || [defender isCurrentMission:kRetreatMission] || [defender isCurrentMission:kRoutMission] ) {
            percentageLost *= sParameters[kParamMoraleLossDisorganizedF].floatValue;
            NSLog( @"disorganized, increasing morale loss: %.1f%%", percentageLost );
        }

        // should the unit retreat?
        defenderRouts = defender.morale < sParameters[kParamMaxMoraleRoutedF].floatValue;
    }

    NSLog( @"casualties: %d, routs: %@", defenderCasualties, (defenderRouts ? @"yes" : @"no" ) );

    // record when the last attack was. this means that when a unit retreats then the attacker can not immediately fire upon it
    attacker.lastFired = [Globals sharedInstance].clock.currentTime;

    // handle retreats
    RoutMission * routMission = nil;
    if ( defender.men > 0 && defenderRouts ) {
        // retreat the defender
        if ( ( routMission = [CombatMission routUnit:defender]) == nil ) {
            NSLog( @"could not find a retreat position!" );
        }
    }

    if ( defender.men <= defenderCasualties ) {
        // destroyed
        [self createMeleeVisualizationForAttacker:attacker defender:defender menLost:defenderCasualties percentageLost:percentageLost destroyed:YES routMission:routMission];
    }
    else if ( defenderRouts ) {
        // lost men and retreats
        [self createMeleeVisualizationForAttacker:attacker defender:defender menLost:defenderCasualties percentageLost:percentageLost destroyed:NO routMission:routMission];
    }
    else {
        // lost men
        [self createMeleeVisualizationForAttacker:attacker defender:defender menLost:defenderCasualties percentageLost:percentageLost destroyed:NO routMission:routMission];
    }
}


- (void) calculateDefenderLossesForRatio:(float)ratio maxCasualties:(int *)maxCasualties retreatProbability:(float *)retreatProbability {
    // defender stronger
    if ( ratio < 0.2f ) {
        *maxCasualties = 0;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.3f ) {
        *maxCasualties = 1;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.4f ) {
        *maxCasualties = 1;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.5f ) {
        *maxCasualties = 2;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.6f ) {
        *maxCasualties = 2;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.7f ) {
        *maxCasualties = 3;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.8f ) {
        *maxCasualties = 3;
        *retreatProbability = 0.0f;
    }
    else if ( ratio < 0.9f ) {
        *maxCasualties = 4;
        *retreatProbability = 0.05f;
    }

    else if ( ratio < 0.98f ) {
        *maxCasualties = 4;
        *retreatProbability = 0.05f;
    }

    // 0.98 -> 1.1 == even strength
    else if ( ratio < 1.1f ) {
        *maxCasualties = 5;
        *retreatProbability = 0.05f;
    }

    // attacker stronger
    else if ( ratio < 2.0f ) {
        *maxCasualties = 6;
        *retreatProbability = 0.1f;
    }
    else if ( ratio < 3.0f ) {
        *maxCasualties = 6;
        *retreatProbability = 0.1f;
    }
    else if ( ratio < 4.0f ) {
        *maxCasualties = 6;
        *retreatProbability = 0.1f;
    }
    else if ( ratio < 5.0f ) {
        *maxCasualties = 7;
        *retreatProbability = 0.15f;
    }
    else if ( ratio < 6.0f ) {
        *maxCasualties = 7;
        *retreatProbability = 0.15f;
    }
    else if ( ratio < 7.0f ) {
        *maxCasualties = 7;
        *retreatProbability = 0.2f;
    }
    else if ( ratio < 8.0f ) {
        *maxCasualties = 8;
        *retreatProbability = 0.25f;
    }
    else if ( ratio < 9.0f ) {
        *maxCasualties = 8;
        *retreatProbability = 0.25f;
    }
    else {
        *maxCasualties = 8;
        *retreatProbability = 0.3f;
    }

    NSLog( @"ratio: %.2f -> %d max casualties, %.2f retreat probability", ratio, *maxCasualties, *retreatProbability );
}

@end
