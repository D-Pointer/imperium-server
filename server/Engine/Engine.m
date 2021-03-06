#import "Engine.h"
#import "Definitions.h"
#import "Globals.h"
#import "Unit.h"
#import "Scenario.h"
#import "FireMission.h"
#import "LineOfSight.h"
#import "Message.h"
#import "Smoke.h"

#import "MeleeMission.h"
#import "RetreatMission.h"
#import "IdleMission.h"
#import "AssaultMission.h"
#import "AdvanceMission.h"
#import "UdpNetworkHandler.h"

@interface Engine () {
    dispatch_queue_t aiQueue;
}

@property (nonatomic, assign) float lastObjectiveUpdate;
@property (nonatomic, assign) int gameEndLingerUpdates;
@property (nonatomic, assign) unsigned int updateCounter;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation Engine

- (id) init {
    self = [super init];

    if (self) {
        self.timer = nil;
        self.lastObjectiveUpdate = -1;
        self.updateCounter = 0;

        // no lingering game and updates yet
        self.gameEndLingerUpdates = -1;

        self.messages = [ NSMutableArray new];
    }

    return self;
}


- (void) start {
    Globals *globals = [Globals sharedInstance];

    // we should run the engine normally
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:sParameters[kParamEngineUpdateIntervalF].floatValue
                                                      target:self
                                                    selector:@selector(simulate)
                                                    userInfo:nil
                                                     repeats:YES];
        NSLog( @"started timer" );

        // also start the time clock
        [globals.clock start];
    }
}


- (void) stop {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;

        NSLog( @"stopped simulation timer" );
    }
}


- (void) runLineOfSight {
    Globals *globals = [Globals sharedInstance];
    //NSLog( @"running line of sight" );

    dispatch_async( dispatch_get_main_queue(), ^(void) {
        //        dispatch_async( losQueue, ^(void) {
        // run the LOS update
        [globals.lineOfSight update];
    } );
}


- (void) simulate {
    Globals *globals = [Globals sharedInstance];

    // clear all old messages and attacks
    [self.messages removeAllObjects];

    // advance the time
    float elapsedTime = [globals.clock advanceTime];
    self.updateCounter++;

    clock_t startTime = clock();

    NSLog( @"-----------------------------------------------------------------------------------------------------------------" );
    NSLog( @"simulating for time: %.1f, update: %d", elapsedTime, self.updateCounter );

    // TODO: run line of signt
    
    // always check the command status of all units
    [self checkCommandStatus];

    // check for units that are close enough to melee
    [self checkForMelee];

    // run all missions
    [self executeMissions];

    // add or remove fatigue for all missions
    [self updateFatigueAndMorale];

    // update smoke
    [self updateSmoke];

    // set the objective owners
    if (self.lastObjectiveUpdate < 0 || elapsedTime >= self.lastObjectiveUpdate + sParameters[kParamObjectiveOwnerUpdateIntervalF].floatValue) {
        [Objective updateOwnerForAllObjectives];
        self.lastObjectiveUpdate = elapsedTime;
    }

    NSLog( @"sending missions for %lu units", (unsigned long)globals.units.count );
    [globals.udpConnection sendUnitStats:globals.units];
    [globals.udpConnection sendMissions:globals.units];

    // show all normal messages that belongs to this step
    for (Message *message in self.messages) {
        [message execute];
    }

    // is the game about to end and just lingering a bit?
    if (self.gameEndLingerUpdates != -1) {
        if (--self.gameEndLingerUpdates == 0) {
            // stop triggering this simulation update
            [self stop];

            // update the final scores
            [globals.scores calculateFinalScores];

            NSLog( @"sending an end game packet" );
            [globals.tcpConnection endGame];
        }
    }
    else {
        // check for game over if 1 player game or we're player 1 and a multiplayer game
        ScenarioState state = globals.scenario.state;
	if (state != kGameInProgress) {
	    NSLog( @"****** game entered lingering state ******" );

	    // do a few more updates
	    self.gameEndLingerUpdates = sParameters[kParamGameEndLingerUpdatesI].intValue;
        }
    }

    clock_t endTime = clock();
    double duration = ((double) (endTime - startTime)) / CLOCKS_PER_SEC * 1000.0;
    NSLog( @"engine update took %.0f ms", duration );
}


- (void) executeMissions {
    Globals *globals = [Globals sharedInstance];

    // run all unit's missions
    for (Unit *unit in globals.units) {
        // destroyed?
        if (unit.destroyed) {
            continue;
        }

        // firing or idle? we try to actively find better targets for units that are firing, for instance if something is assaulting
        // the unit then that should probably be a preferred target. Skip all AI units, they set their own targets. Also skip area fire as that area
        // has been set by the player for a reason
        if ( [unit canFire] && ([unit isCurrentMission:kIdleMission] || [unit isCurrentMission:kFireMission])) {
            [self findAndSetTarget:unit];
        }

        // is the unit still waiting for the mission to start?
        if (unit.mission != nil && unit.mission.commandDelay > 0) {
            // yes, so wait more
            NSLog( @"delay for %@: %.1f", unit, unit.mission.commandDelay );
            unit.mission.commandDelay -= globals.clock.lastElapsedTime;

            // don't execute yet
            continue;
        }

        // run the mission
        if ([unit.mission execute] == kCompleted) {
            NSLog( @"completed a %@", unit.mission.name );
            unit.mission = nil;
        }
    }
}


- (void) findAndSetTarget:(Unit *)attacker {
    // first try and find a target inside the firing arc
    Unit *target = [self findTarget:attacker onlyInsideArc:YES];

    if (target) {
        // does it already fire at that unit?
        if (attacker.mission.type != kFireMission || ((FireMission *) attacker.mission).targetUnit != target) {
            NSLog( @"unit %@ firing at %@", attacker.name, target.name );
            attacker.mission = [[FireMission alloc] initWithTarget:target];
        }
    }
}


- (Unit *) findTarget:(Unit *)attacker onlyInsideArc:(BOOL)onlyInsideArc {
    //NSLog( @"finding a target for unit %@", attacker.name );

    // no auto firing enable?
    if (attacker.autoFireEnabled == NO) {
        return nil;
    }

    // units in column mode will not find targets
    if (attacker.mode == kColumn) {
        return nil;
    }

    Globals *globals = [Globals sharedInstance];

    Unit *bestTarget = nil;
    float bestDistance = 1000000;

    // does it have an old target?
    Unit *oldTarget = nil;
    if (attacker.mission.type == kFireMission) {
        oldTarget = ((FireMission *) attacker.mission).targetUnit;

        // use the distance to the old target as the base, but cut it down drastically to make the unit
        // prefer the old target unless something is really close
        bestDistance = ccpDistance( oldTarget.position, attacker.position ) * 0.33f;
    }

    // check all the units seen by the attacker
    for (unsigned int index = 0; index < attacker.losData.seenCount; ++index) {
        Unit *target = [attacker.losData getSeenUnit:index];

        // don't fire at own units or destroyed units
        if (target.destroyed || target.owner == attacker.owner) {
            continue;
        }

        // can't fire at what we don't see
//        if (target.visible == NO) {
//            continue;
//        }

        // distance to the target
        float distance = ccpDistance( attacker.position, target.position );
        if (distance > attacker.weapon.firingRange) {
            // too far
            continue;
        }

        // if the target is outside the firing arc, assume it's further away. this should make units inside
        // the firing arc prioritized higher
        if (![attacker isInsideFiringArc:target.position checkDistance:YES]) {
            // only target those inside the firing arc?
            if (onlyInsideArc) {
                continue;
            }

            // the unit is not inside, so give it some penalty
            distance *= 1.5;
        }

        // prefer units that are not retreating
        if (target.mission.type == kRetreatMission) {
            distance *= 1.5;
        }

        // if the target is advancing or assaulting us, then it's a higher priority target
        if (target.mission.type == kAssaultMission) {
            AssaultMission *assault = (AssaultMission *) target.mission;
            if (ccpDistance( assault.path.lastPosition, attacker.position ) < sParameters[kParamMaxDistanceFromAssaultEndPointF].floatValue) {
                // they are assaulting toward us
                distance *= 0.3;
                NSLog( @"bonus for assault" );
            }
        }
        else if (target.mission.type == kAdvanceMission) {
            AdvanceMission *advance = (AdvanceMission *) target.mission;
            if (advance.targetUnit == attacker) {
                // they are advancing on us
                distance *= 0.5;
                NSLog( @"bonus for advance" );
            }
        }

        // prefer artillery units
        if (target.type == kArtillery) {
            distance *= 0.75;
        }

        // better than the current best target?
        if (distance < bestDistance) {
            bestTarget = target;
            bestDistance = distance;
        }
    }

    return bestTarget;
}


- (void) checkCommandStatus {
    for (Unit *unit in [Globals sharedInstance].units) {
        // ignore destroyed units
        if (unit.destroyed) {
            unit.inCommand = NO;
            continue;
        }

        // is it a HQ itself? they are always in command
        if (unit.isHeadquarter) {
            unit.inCommand = YES;
        }
        else if (!unit.headquarter) {
            // no HQ assigned at all, so it's in command of itself then
            unit.inCommand = YES;
        }
        else if (unit.headquarter && !unit.headquarter.destroyed && ccpDistance( unit.position, unit.headquarter.position ) < unit.headquarter.commandRange) {
            unit.inCommand = YES;
        }
        else {
            // not in command
            unit.inCommand = NO;
        }
    }
}


- (void) updateFatigueAndMorale {
    //NSLog( @"updating fatigue and morale" );

    float elapsedTime = [Globals sharedInstance].clock.lastElapsedTime;
    float effect;

    for (Unit *unit in [Globals sharedInstance].units) {
        // ignore destroyed units
        if (unit.destroyed) {
            continue;
        }

        // morale

        // a HQ unit? they rally as if they were in command
        if (unit.isHeadquarter) {
            unit.morale += sParameters[kParamMoraleRecoveryInCommandF].floatValue;
        }

            // units in command get a higher morale recovery
        else if (unit.inCommand) {
            // does the HQ unit actively rally, i.e stand idle?
            if (unit.headquarter && unit.headquarter.mission.type == kRallyMission) {
                unit.morale += elapsedTime * sParameters[kParamMoraleRecoveryRallyingHqF].floatValue;
            }
            else {
                // HQ does something else
                unit.morale += elapsedTime * sParameters[kParamMoraleRecoveryInCommandF].floatValue;
            }
        }
        else {
            unit.morale += elapsedTime * sParameters[kParamMoraleRecoveryNotInCommandF].floatValue;
        }


        // fatigue

        // all units should always have missions, but check to make sure
        if (unit.mission) {
            effect = unit.mission.fatigueEffect / 60.0f * elapsedTime;
        }
        else {
            // no mission, it's likely idle
            effect = sParameters[kParamIdleFatigueEffectF].floatValue / 60.0f * elapsedTime;
        }

        unit.fatigue += effect;
    }
}


- (void) updateSmoke {
     NSMutableArray * removed = [ NSMutableArray new];
    Globals *globals = [Globals sharedInstance];

    float direction = globals.scenario.windDirection;
    float speed = globals.scenario.windStrength;

    // randomize the direction a bit: -10..10 degrees
    direction += -10 + CCRANDOM_0_1() * 20;

    // a delta for the angle, length based on the wind speed
    CGPoint delta = ccpMult( ccpForAngle( CC_DEGREES_TO_RADIANS( direction ) ), speed );

    // update all smoke with our delta
    for ( Smoke * smoke  in globals.smoke ) {
        //NSLog( @"updating: %@", smoke );
        if ( [smoke update:delta] ) {
	    [removed addObject:smoke];
	}
    }

    // get rid of the faded out smoke
    for ( Smoke * smoke in removed ) {
        [globals.smoke removeObject:smoke];
    }

    NSLog( @"sending data for %lu smoke", (unsigned long)globals.smoke.count );
    [globals.udpConnection sendSmoke:globals.smoke];
}


- (void) checkForMelee {
    Globals *globals = [Globals sharedInstance];

    //NSLog( @"checking for melee units" );
     NSMutableArray *units1 = globals.unitsPlayer1;
     NSMutableArray *units2 = globals.unitsPlayer2;

    for (Unit *unit1 in units1) {
        // detroyed, already meleeing or not available for melee?
        if ( unit1.destroyed || [unit1 isCurrentMission:kMeleeMission] || [unit1 isCurrentMission:kRetreatMission] ) {
            continue;
        }

        for (Unit *unit2 in units2) {
            // already meleeing or not available for melee?
            if ( unit2.destroyed || [unit2 isCurrentMission:kMeleeMission] || [unit2 isCurrentMission:kRetreatMission] ) {
                continue;
            }

            // check the distance
            if (ccpDistance( unit1.position, unit2.position ) < sParameters[kParamMeleeMaxDistanceF].floatValue) {
                // close enough for a melee
                NSLog( @"%@ meleeing with %@", unit1.name, unit2.name );
                unit1.mission = [[MeleeMission alloc] initWithTarget:unit2];
                unit2.mission = [[MeleeMission alloc] initWithTarget:unit1];

		// TODO: maybe assemble all missions for all units in one packet?
		[globals.udpConnection sendSetMission:kMeleeMission forUnit:unit1];
		[globals.udpConnection sendSetMission:kMeleeMission forUnit:unit2];
            }
        }
    }
}

@end
