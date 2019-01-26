
#import "CombatMission.h"
#import "RotateMission.h"
#import "RetreatMission.h"
#import "Unit.h"
#import "Globals.h"
#import "MapLayer.h"
#import "TerrainModifiers.h"
#import "AttackVisualization.h"
#import "AttackResult.h"
#import "Engine.h"
#import "UdpNetworkHandler.h"

@implementation CombatMission

- (void) fireAtTarget:(CGPoint)target withUnit:(Unit *)attacker targetSeen:(BOOL)seen {
    NSAssert( attacker, @"null attacker" );

    CCLOG( @"***** %@ fires at %.1f %.1f", attacker, target.x, target.y );

    Weapon * weapon = attacker.weapon;
    float distanceToTarget = ccpDistance( attacker.position, target );

    // base modifier starts always as the number of weapons firing. this is a base strength for how much
    // firepower theoretically exits the muzzles
    float baseFirepower = attacker.weaponCount * weapon.firepower;
    
    CCLOG( @"weapon type: %@", weapon.name );
    CCLOG( @"base strength: %.1f", baseFirepower );

    // modify for range
    float rangeModifier = [weapon getFirepowerModifierForRange:distanceToTarget];
    CCLOG( @"range modifier: %.1f", rangeModifier );

    // FUTURE: leader bonus
    float leaderModifier = 1.0f;

    // ammo modifier
    float ammoModifier = attacker.weapon.ammo <= 0 ? 0.3f : 1.0f;

    CCLOG( @"ammo: %d, modifier: %.1f", attacker.weapon.ammo, ammoModifier );

    // experience
    float experienceModifier = 1.0f;
    switch ( attacker.experience ) {
        case kGreen: experienceModifier   = 0.5f; break;
        case kRegular: experienceModifier = 0.7f; break;
        case kVeteran: experienceModifier = 0.8f; break;
        case kElite: experienceModifier   = 1.0f; break;
    }

    CCLOG( @"experience modifier: %.1f", experienceModifier );

    // morale. everything under 70 gets interpolated so that 0 -> 0.2 and 70 -> 1.0
    float moraleModifier = 1.0f;
    if ( attacker.morale < 70 ) {
        // interpolate
        moraleModifier = 0.2f + (attacker.morale / 70.0f) * 0.8f;
    }
    CCLOG( @"morale modifier: %.1f", moraleModifier );

    // fatigue. everything over 50 gets interpolated so that up to 50 no effect and then 50 -> 1.0 and 100 -> 0.5
    float fatigueModifier = 1.0f;
    if ( attacker.fatigue > 50 ) {
        // interpolate
        fatigueModifier = 1.0f - (attacker.fatigue - 50) / 100.0f;
    }

    CCLOG( @"fatigue modifier: %.1f", fatigueModifier );

    // cavalry units are weaker
    float unitTypeModifier = 1.0f;
    switch ( attacker.type ) {
        case kInfantryHeadquarter:
            unitTypeModifier = 0.9f;
            break;

        case kCavalry:
            unitTypeModifier = 0.8f;
            break;

        case kCavalryHeadquarter:
            unitTypeModifier = 0.7f;
            break;

        case kInfantry:
        case kArtillery:
            unitTypeModifier = 1.0f;
    }
    CCLOG( @"unit type modifier: %.1f", unitTypeModifier );

    CGPoint attackerPos = attacker.position;

    // attacker terrain modifier
    TerrainType attackerTerrainType = [[Globals sharedInstance].mapLayer getTerrainAt:attackerPos];
    float attackerTerrainModifier = getTerrainOffensiveModifier( attacker, attackerTerrainType );

    CCLOG( @"attacker terrain: %.1f", attackerTerrainModifier );

    // attacker mission type modifier
    float missionTypeModifier = 1.0f;
    if ( attacker.mission.type == kAssaultMission || attacker.mission.type == kAdvanceMission ) {
        missionTypeModifier = 0.7f;
    }

    CCLOG( @"mission type modifier: %.1f", missionTypeModifier );

    // some randomness: 0.8-1.0
    float randomModifier = 0.8f + CCRANDOM_0_1() * 0.2f;
    CCLOG( @"random: %.2f", randomModifier );

    // all modifiers that affect the total power that the firing unit shoots out
    float strengthModifiers = rangeModifier * leaderModifier * fatigueModifier * ammoModifier * experienceModifier * moraleModifier *
    unitTypeModifier * attackerTerrainModifier * missionTypeModifier * randomModifier;

    CCLOG( @"total modifier: %.2f", strengthModifiers );

    // the total firing strength
    float firepower = baseFirepower * strengthModifiers;

    CCLOG( @"final strength: %.1f", firepower );

    // scatter ******************************************************************************************************************************************************

    // accuracy modifier for the range. this removes most of the efficiency
    float scatterDistance = [attacker.weapon getScatterForRange:distanceToTarget];
    CCLOG( @"distance to target: %.0f m", distanceToTarget );
    CCLOG( @"scatter: %.0f m", scatterDistance );

    // does the attacker see the target? if not we're dealing with indirect fire and the accuracy is worse
    if ( ! seen ) {
        scatterDistance *= 1.5;
        CCLOG( @"indirect fire, scatter: %.0f m", scatterDistance );
    }

    // the scatter is random too, sometimes it will simply hit bullseye
    scatterDistance *= CCRANDOM_0_1();
    CCLOG( @"randomized scatter: %.2f m", scatterDistance );

    // scatter is reduced by experience
    switch ( attacker.experience ) {
        case kGreen: scatterDistance *= 1.0f; break;
        case kRegular: scatterDistance *= 0.85f; break;
        case kVeteran: scatterDistance *= 0.70f; break;
        case kElite: scatterDistance *= 0.5f; break;
    }

    CCLOG( @"experienced scatter: %.2f m", scatterDistance );

    // a final hit position scattered somewhere around the position we were aiming for
    float angle = (float)(CCRANDOM_0_1() * M_PI * 2);
    CGPoint hitPosition = ccp( target.x + cosf( angle ) * scatterDistance,
                              target.y + sinf( angle ) * scatterDistance );

    CCLOG( @"target position: %.0f, %.0f", target.x, target.y );
    CCLOG( @"hit position: %.0f, %.0f", hitPosition.x, hitPosition.y );

     NSMutableArray * allCasualties = [ NSMutableArray array];
     NSMutableArray * hitUnits = [ NSMutableArray array];

    // which units are close enough to get damaged?
    for ( Unit * possibleTarget in [Globals sharedInstance].units ) {
        // note that even own units can get damaged
        if ( possibleTarget.destroyed ) {
            continue;
        }

        // close enough to get hit?
        float distance = ccpDistance( possibleTarget.position, hitPosition );
        if ( distance < 30 ) {
            CCLOG( @"unit %@ is hit, distance: %.1f m", possibleTarget, distance );
            [hitUnits addObject:possibleTarget];
        }
    }

    // now handle all hit units that were hit
    for ( Unit * hitUnit in hitUnits ) {
        float distance = ccpDistance( hitUnit.position, hitPosition );

        // terrain under the target unit
        TerrainType targetTerrainType = [[Globals sharedInstance].mapLayer getTerrainAt:hitUnit.position];
        float targetTerrainModifier = getTerrainDefensiveModifier( targetTerrainType );
        CCLOG( @"terrain modifier: %.1f", targetTerrainModifier );

        // how far from the center point of the fire is the target?
        float distanceModifier = 1.0f - distance / 30.0f;
        CCLOG( @"distance modifier: %.1f", distanceModifier );

        // final casualties for this unit. the firepower is divided equally among all hit units
        int casualties = (int)((firepower / hitUnits.count) * distanceModifier * targetTerrainModifier);
        casualties = MIN( hitUnit.men, casualties );

        // does it rout? do this before delivering the casulaties below to get an exact percentage of killed
        float percentageLost = (float)casualties / (float)hitUnit.men * 100;

        CCLOG( @"casualties: %d of %d (%.1f%%)", casualties, hitUnit.men, percentageLost);

        // is the defender not in command?
        if ( ! hitUnit.inCommand ) {
            percentageLost *= sParameters[kParamMoraleLossNotInCommandF].floatValue;
            CCLOG( @"not in command, increasing morale loss: %.1f%%", percentageLost );
        }

        // is the defender disorganized?
        if ( [hitUnit isCurrentMission:kDisorganizedMission] ) {
            percentageLost *= sParameters[kParamMoraleLossDisorganizedF].floatValue;
            CCLOG( @"disorganized, increasing morale loss: %.1f%%", percentageLost );
        }

        // if the attacker is artillery then the morale loss is bigger
        if ( attacker.type == kArtillery ) {
            percentageLost *= sParameters[kParamMoraleLossAttackerArtilleryF].floatValue;
        }

        // is the defender outflanked?
        if ( [hitUnit isOutflankedFromPos:attacker.position] ) {
            percentageLost *= sParameters[kParamOutflankingMoraleModifierF].floatValue;
            CCLOG( @"target outflanked, increased morale loss" );
        }

        // should the unit rout?
        BOOL defenderRouts = hitUnit.morale - percentageLost < sParameters[kParamMaxMoraleRoutedF].floatValue;

        // in tutorial mode don't retreat
        if ( [Globals sharedInstance].tutorial ) {
            defenderRouts = NO;
        }

        if ( defenderRouts ) {
            CCLOG( @"percentage lost: %.1f, morale: %.1f => defender routs", percentageLost, hitUnit.morale );
        }

        RoutMission * routMission = nil;

        // handle routing
        if ( hitUnit.men > casualties && defenderRouts && hitUnit.mission.type != kRoutMission) {
            // retreat the defender
            if ( ( routMission = [CombatMission routUnit:hitUnit]) == nil ) {
                CCLOG( @"could not find a rout position!" );
            }
        }

        // create the combat visualization
        if ( casualties == hitUnit.men ) {
            // destroyed it
            [allCasualties addObject:[[AttackResult alloc] initWithMessage:kDefenderDestroyed withAttacker:attacker forTarget:hitUnit casualties:casualties routMission:routMission
                                                        targetMoraleChange:percentageLost attackerMoraleChange:sParameters[kParamMoraleBoostDestroyEnemyF].floatValue]];
            CCLOG( @"%@ has been destroyed!", hitUnit.name );
        }
        else if ( casualties > 0 ) {
            if ( defenderRouts ) {
                // lost men but still alive and routing
                [allCasualties addObject:[[AttackResult alloc] initWithMessage:kDefenderLostMen | kDefenderRouted withAttacker:attacker forTarget:hitUnit casualties:casualties
                                                                   routMission:routMission targetMoraleChange:percentageLost attackerMoraleChange:sParameters[kParamMoraleBoostRoutEnemyF].floatValue]];
                CCLOG( @"%@ lost %d men and routing", hitUnit.name, casualties );
            }
            else {
                // lost men but still alive and not routing
                [allCasualties addObject:[[AttackResult alloc] initWithMessage:kDefenderLostMen withAttacker:attacker forTarget:hitUnit casualties:casualties
                                                                   routMission:routMission targetMoraleChange:percentageLost attackerMoraleChange:sParameters[kParamMoraleBoostDamageEnemyF].floatValue]];
                CCLOG( @"%@ lost %d men", hitUnit.name, casualties );
            }
        }
    }

    CCLOG( @"created %lu attack results", (unsigned long)allCasualties.count );

    // finally set up the attack visualization
    [self createAttackVisualizationForAttacker:attacker casualties:allCasualties hitPosition:hitPosition];

    // record when the last attack was
    attacker.lastFired = [Globals sharedInstance].clock.currentTime;

    // one less ammo
    attacker.weapon.ammo -= 1;
}


- (float) getMeleeStrengthFor:(Unit *)attacker {
    CCLOG( @"attacker: %@", attacker.name);

    float modeModifier = [self getModeModifierFor:attacker];
    CCLOG( @"mode modifier: %f", modeModifier );

    // is the defender outflanked?
    float outflankingModifier = 1.0f;
    if ( [self.targetUnit isOutflankedFromPos:attacker.position] ) {
        outflankingModifier = 1.5;
    }
    CCLOG( @"outflanking modifier: %.1f", outflankingModifier );

    // cavalry has a melee bonus
    float unitTypeModifier = 1.0f;
    if ( attacker.type == kCavalry && attacker.mode == kFormation ) {
        unitTypeModifier = 1.5f;
    }
    CCLOG( @"unit type modifier: %.1f", unitTypeModifier );


    // experience
    float experienceModifier;
    switch ( attacker.experience ) {
        case kGreen: experienceModifier   = 0.5f; break;
        case kRegular: experienceModifier = 0.7f; break;
        case kVeteran: experienceModifier = 0.8f; break;
        case kElite: experienceModifier   = 1.0f; break;
    }

    CCLOG( @"experience modifier: %.1f", experienceModifier );

    // morale. everything under 70 gets interpolated so that 0 -> 0.5 and 70 -> 1.0
    float moraleModifier = 1.0f;
    if ( attacker.morale < 70 ) {
        // interpolate
        moraleModifier = 0.5f + (attacker.morale / 70.0) * 0.5f;
    }
    CCLOG( @"morale modifier: %.1f", moraleModifier );

    // fatigue. everything over 50 gets interpolated so that up to 50 no effect and then 50 -> 1.0 and 100 -> 0.5
    float fatigueModifier = 1.0f;
    if ( attacker.fatigue > 50 ) {
        // interpolate
        fatigueModifier = 1.0f - (attacker.fatigue - 50) / 100.0f;
    }

    CCLOG( @"fatigue modifier: %.1f", fatigueModifier );

    // FUTURE: leader bonus
    float leaderModifier = 1.0f;

    // final combat strength modifiers
    float modifiers = modeModifier * outflankingModifier * unitTypeModifier * leaderModifier * fatigueModifier * experienceModifier;

    CCLOG( @"total modifiers: %f", modifiers );

    // clamp the values to be 0.2 .. 2.0
    modifiers = clampf( modifiers, 0.2, 2.0 );

    CCLOG( @"clamped modifiers: %f", modifiers );

    // base modifier starts always as the number of men
    float baseFirepower = attacker.men;
    float finalStrength = baseFirepower * modifiers;

    CCLOG( @"base strength: %f", baseFirepower );
    CCLOG( @"final strength: %f", finalStrength );

    return finalStrength;
}


- (float) getModeModifierFor:(Unit *)attacker {
    // in formation there is no modifier
    if ( attacker.mode == kFormation ) {
        return 1;
    }

    switch ( attacker.type ) {
        case kInfantryHeadquarter:
        case kInfantry:
            // infantry has some efficiency loss
            return 0.5f;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            // less for cavalry
            return 0.6f;
            break;

        case kArtillery:
            // artillery is basically infantry
            return 0.2f;
            break;
    }
}


+ (RoutMission *) routUnit:(Unit *)router {
    // is it already retreating?
    if ( router.mission.type == kRoutMission ) {
        CCLOG( @"%@ is already retreating, not adding same mission", router.name );
        return nil;
    }

    CCLOG( @"routing %@", router.name );

    // these angles are added to the rotation backwards to try to find a suitable place to move to
    int angles[] = { 0, 10, -10, 20, -20, 30, -30, 40, -40, 50, -50, 60, -60, 70, -70 };

    int startDistance = 200 + arc4random_uniform( 100 );

    for ( int retreat_distance = startDistance; retreat_distance > 50; retreat_distance -= 40 ) {
        for ( int angleIndex = 0; angleIndex < 15; ++angleIndex ) {
            int angle = angles[ angleIndex ];
            // a vector that's some distance straight behind the retreater
            CGPoint direction = ccpNeg( ccpMult( ccpForAngle( CC_DEGREES_TO_RADIANS( 90 - router.rotation + angle)), retreat_distance ) );
            CGPoint routPos = ccpAdd( router.position, direction );

            // is the position still inside the map?
            if ( [[Globals sharedInstance].mapLayer isInsideMap:routPos] ) {
                // still inside, so retreat there
                Path * path = [Path new];
                [path addPosition:routPos];
                RoutMission * rout = [[RoutMission alloc] initWithPath:path];

                // TODO: use path finder to find a path instead of having just one position

                CCLOG( @"from: %.1f, %.1f", router.position.x, router.position.y );
                CCLOG( @"to:   %.1f, %.1f", routPos.x, routPos.y );
                CCLOG( @"dir:  %.1f, %.1f", direction.x, direction.y );

                // and we're done
                return rout;
            }
        }
    }

    CCLOG( @"no routing position found for %@", router.name );
    return nil;
}


- (void) createAttackVisualizationForAttacker:(Unit *)attacker casualties:( NSMutableArray *)casualties hitPosition:(CGPoint)hitPosition {
    // create and show immediately
    AttackVisualization * visualization = [[AttackVisualization alloc] initWithAttacker:attacker casualties:casualties hitPosition:hitPosition];
    [visualization execute];

    // for a multiplayer game send the result to the other player
    if ([Globals sharedInstance].gameType == kMultiplayerGame) {
        [[Globals sharedInstance].udpConnection sendFireWithAttacker:attacker casualties:casualties hitPosition:hitPosition];
    }
}


- (void) createSmokeVisualizationForAttacker:(Unit *)attacker hitPosition:(CGPoint)hitPosition {
    // create and show immediately
    AttackVisualization * visualization = [[AttackVisualization alloc] initWithAttacker:attacker smokePosition:hitPosition];
    [visualization execute];

    // for a multiplayer game send the result to the other player
    if ([Globals sharedInstance].gameType == kMultiplayerGame) {
        // send to the other player. Send no casualties as that marks it as a smoke packet
        [[Globals sharedInstance].udpConnection sendFireWithAttacker:attacker casualties:nil hitPosition:hitPosition];
    }
}


- (void) createMeleeVisualizationForAttacker:(Unit *)attacker defender:(Unit *)defender menLost:(int)menLost percentageLost:(float)percentageLost destroyed:(BOOL)destroyed
                                 routMission:(RoutMission *)routMission {
    AttackResult *result = nil;

    // destroyed outright?
    if (destroyed) {
        CCLOG( @"defender destroyed" );
        result = [[AttackResult alloc] initWithMessage:kMeleeAttack | kDefenderDestroyed withAttacker:attacker forTarget:defender casualties:menLost routMission:routMission
                                    targetMoraleChange:percentageLost attackerMoraleChange:sParameters[kParamMoraleBoostDestroyEnemyF].floatValue];
    }
    else if (menLost > 0) {
        // rout?
        if (routMission) {
            CCLOG( @"defender retreats" );
            result = [[AttackResult alloc] initWithMessage:kMeleeAttack | kDefenderLostMen | kDefenderRouted withAttacker:attacker forTarget:defender casualties:menLost routMission:routMission
                                        targetMoraleChange:percentageLost attackerMoraleChange:sParameters[kParamMoraleBoostRoutEnemyF].floatValue];
        }
        else {
            // only lost some men, does not retreat
            CCLOG( @"defender lost men" );
            result = [[AttackResult alloc] initWithMessage:kMeleeAttack | kDefenderLostMen withAttacker:attacker forTarget:defender casualties:menLost routMission:routMission
                                        targetMoraleChange:percentageLost attackerMoraleChange:sParameters[kParamMoraleBoostDamageEnemyF].floatValue];
        }
    }

    if (result == nil) {
        // nothing to do
        CCLOG( @"no melee visualization created" );
        return;
    }

    [result execute];

    // for a multiplayer game send the result to the other player
    if ([Globals sharedInstance].gameType == kMultiplayerGame) {
        [[Globals sharedInstance].udpConnection sendMeleeWithAttacker:result.attacker
                                                               target:result.target
                                                              message:result.messageType
                                                           casualties:menLost
                                                   targetMoraleChange:result.targetMoraleChange];
    }
}


- (NSString *) save {
    if ( self.rotation ) {
        // target x, y and endpoint x, y
        return [NSString stringWithFormat:@"m %d %.1f %.1f %d %d\n",
                self.type,
                self.rotation.target.x,
                self.rotation.target.y,
                self.targetUnit.unitId,
                self.canBeCancelled ? 1 : 0];
    }
    else {
        // target x, y and endpoint x, y
        return [NSString stringWithFormat:@"m %d %d %d\n",
                self.type,
                self.targetUnit.unitId,
                self.canBeCancelled ? 1 : 0];
    }
}


- (BOOL) loadFromData:(NSArray *)parts {
    int targetUnitId = -1;

    // add a rotate mission too?
    if ( parts.count == 4 ) {
        // NOTE: the unit self.unit is not yet valid here, so the rotate mission will have a nil unit initially. it gets set
        // in Mission:setUnit when the unit is assigned

        // facingX facingY targetId
        self.rotation = [[RotateMission alloc] initFacingTarget:CGPointMake( [parts[0] floatValue], [parts[1] floatValue] )];
        targetUnitId = [parts[2] intValue];
        self.canBeCancelled = [parts[2] intValue] == 1 ? YES : NO;
    }
    else {
        // targetId
        targetUnitId = [parts[0] intValue];
        self.canBeCancelled = [parts[1] intValue] == 1 ? YES : NO;
        self.rotation = nil;
    }

    self.targetUnit = nil;

    // find the target unit
    for ( Unit * tmp in [Globals sharedInstance].units ) {
        if ( tmp.unitId == targetUnitId ) {
            self.targetUnit = tmp;
            self.endPoint   = tmp.position;
            break;
        }
    }
    
    NSAssert( self.targetUnit != nil, @"did not find target unit" );
    
    // all is ok
    return YES;
}

@end
