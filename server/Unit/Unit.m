#import "Unit.h"
#import "Definitions.h"
#import "Globals.h"
#import "Scenario.h"
#import "Organization.h"
#import "FireMission.h"
#import "RotateMission.h"
#import "MeleeMission.h"
#import "IdleMission.h"


@implementation Unit

- (instancetype) init {
    self = [super init];
    if (self) {
        self.headquarter = nil;
        self.attackResult = nil;

        // by default auto fire is on
        self.autoFireEnabled = YES;
    }

    return self;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[Unit %d, %@ men: %d, pos: %d,%d]", self.unitId, self.name, self.men, (int) self.position.x, (int) self.position.y];
}


- (BOOL) isHeadquarter {
    return self.type == kInfantryHeadquarter || self.type == kCavalryHeadquarter;
}


- (BOOL) isSupport {
    WeaponType weaponType = self.weapon.type;
    return weaponType == kMachineGun || weaponType == kMortar || weaponType == kSniperRifle || weaponType == kFlamethrower;
}


- (void) setMen:(int)men {
    _men = men;

    NSAssert( _men < 100, @"too many men, flipped to negative?" );
    
    // has it been destroyed?
    if (men <= 0) {
        // no mission anymore
        self.mission = nil;

        // every other unit in the possible organization takes a morale hit
        if (self.organization) {
            for (Unit *unit in self.organization.units) {
                if (unit != self) {
                    unit.morale *= (sParameters[kParamMoraleLossUnitDestroyedF].floatValue / 100.0f);
                }
            }
        }

        // remove from any organization
        /*if ( self.organization ) {
         NSLog( @"unit destroyed, it's a member of %@", self.organization );

         // are we the hq for the organization?
         if ( self.organization.headquarter == self ) {
         NSLog( @"unit %@ is hq for organization %@, removing organization", self, self.organization );

         // yes, the entire organization is now destroyed. First remove the organization itself
         [[Globals sharedInstance].organizations removeObject:self.organization];

         // make sure no unit knows of it anymore
         for ( Unit * unit in self.organization.unitDefinitions ) {
         unit.organization = nil;
         }
         }
         else {
         // we're just a member of it
         NSLog( @"removing unit %@ from organization %@", self, self.organization );
         [self.organization.unitDefinitions removeObject:self];
         self.organization = nil;
         }
         }*/
    }
    else {
        // do we have enough men to operate the weapons? if we have no guns left then the men take up rifles
        if (self.weaponCount == 0) {
            self.weapon = [[Weapon alloc] initWithType:kRifle];
        }
    }
}


- (void) setMorale:(float)morale {
    // keep the morale [0..100]
    _morale = clampf( morale, 0, 100 );
}


- (void) setFatigue:(float)fatigue {
    // keep the fatigue [0..100]
    _fatigue = clampf( fatigue, 0, 100 );
}


- (void) setRotation:(float)rotation {
    if (rotation < 0) {
        rotation += 360.0f;
    }

    _rotation = rotation;
}


/**
 * This method is overridden because CCRotateTo does not set the rotation directly so that the above method would be
 * called, instead it sets rotationX and rotationY and the markers and visualizers never get to update while the unit
 * turns. This method is called every frame when rotating. Note that we use Y and not X, as both need to be set
 * before the markers can update, otherwise there's an internal consistency assertion.
 **/
//- (void) setRotationY:(float)rotationY {
//    [super setRotationY:rotationY];
//}


//- (void) setVisible:(BOOL)visible {
//    [super setVisible:visible];
//}


- (NSString *) modeName {
    switch (self.type) {
        case kInfantryHeadquarter:
        case kInfantry:
        case kCavalry:
        case kCavalryHeadquarter:
            return self.mode == kFormation ? @"Formation" : @"Column";
            break;

        case kArtillery:
            return self.mode == kFormation ? @"Unlimbered" : @"Limbered";
            break;
    }
}


- (float) movementSpeed {
    // speed is m/s

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 1.1;
            break;
        case kElite:
            experienceModifier = 1.2;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            return (80.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kInfantry:
            return (70.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            return (120.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kArtillery:
            return (40.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;
    }
}


- (float) fastMovementSpeed {
    // speed is m/s

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 1.1;
            break;
        case kElite:
            experienceModifier = 1.2;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            return (125.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kInfantry:
            return (100.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            return (180.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kArtillery:
            return (80.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;
    }
}


- (float) scoutingSpeed {
    // speed is m/s

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 1.1;
            break;
        case kElite:
            experienceModifier = 1.2;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            return (60.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kInfantry:
            return (50.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            return (90.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kArtillery:
            return (30.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;
    }
}


- (float) retreatSpeed {
    // speed is m/s

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 1.1;
            break;
        case kElite:
            experienceModifier = 1.2;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            return (60.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kInfantry:
            return (50.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            return (100.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kArtillery:
            return (20.0f / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;
    }
}


- (float) advanceSpeed {
    // speed is m/s

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 1.1;
            break;
        case kElite:
            experienceModifier = 1.2;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            return (80 / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kInfantry:
            return (70 / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            return (120 / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kArtillery:
            // artillery can not advance
            return -1.0f;
            break;
    }
}


- (float) assaultSpeed {
    // speed is m/s

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90f;
            break;
        case kRegular:
            experienceModifier = 1.0f;
            break;
        case kVeteran:
            experienceModifier = 1.1f;
            break;
        case kElite:
            experienceModifier = 1.2f;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            return (150 / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kInfantry:
            return (130 / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kCavalry:
        case kCavalryHeadquarter:
            return (220 / 60.0f) * experienceModifier * fatigueModifier * self.weapon.movementSpeedModifier;
            break;

        case kArtillery:
            // artillery can not assault
            return -1.0f;
            break;
    }
}


- (float) rotationSpeed {
    // speed is degrees/s

    // experience modifier
    float experienceModifier;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 0.90;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 1.1;
            break;
        case kElite:
            experienceModifier = 1.2;
            break;
    }

    // a speed modifier for the fatigue. 0..50 no penalty, 100 == 0.5
    float fatigueModifier = self.fatigue < 50 ? 1.0f : 1.0f - (self.fatigue - 50.0f) / 100.0f;

    // if routed the speed is faster
    float routModifier = 1.0f;
    if (self.morale < sParameters[kParamMaxMoraleRoutedF].floatValue) {
        routModifier = 2.0f;
    }

    float speed = 1.0f;

    switch (self.type) {
        case kInfantryHeadquarter:
            speed = self.mode == kFormation ? 8.0f : 14.0f;
            break;

        case kInfantry:
            speed = self.mode == kFormation ? 5.0f : 10.0f;
            break;

        case kCavalry:
            speed = self.mode == kFormation ? 6.0f : 12.0f;
            break;

        case kCavalryHeadquarter:
            speed = self.mode == kFormation ? 8.0f : 16.0f;
            break;

        case kArtillery:
            if (self.weaponCount > 0) {
                speed = self.mode == kFormation ? 1.0f : 2.0f;
            }
            else {
                speed = self.mode == kFormation ? 2.0f : 4.0f;
            }
            break;
    }

    return speed * experienceModifier * fatigueModifier * routModifier * self.weapon.movementSpeedModifier;
}


- (float) advanceRange {
    // in meters
    switch (self.type) {
        case kInfantryHeadquarter:
            return sParameters[ kParamAdvanceRangeInfantryHeadquarterF].floatValue;

        case kInfantry:
            return sParameters[ kParamAdvanceRangeInfantryF].floatValue;

        case kCavalry:
            return sParameters[ kParamAdvanceRangeCavalryF].floatValue;

        case kCavalryHeadquarter:
            return sParameters[ kParamAdvanceRangeCavalryHeadquarterF].floatValue;

        case kArtillery:
            // artillery can not advance
            return sParameters[ kParamAdvanceRangeArtilleryF].floatValue;
    }
}


- (float) assaultRange {
    // in meters
    switch (self.type) {
        case kInfantryHeadquarter:
            return sParameters[ kParamAssaultRangeInfantryHeadquarterF].floatValue;

        case kInfantry:
            return sParameters[ kParamAssaultRangeInfantryF].floatValue;

        case kCavalry:
            return sParameters[ kParamAssaultRangeCavalryF].floatValue;

        case kCavalryHeadquarter:
            return sParameters[ kParamAssaultRangeCavalryHeadquarterF].floatValue;

        case kArtillery:
            // artillery can not assault
            return sParameters[ kParamAssaultRangeArtilleryF].floatValue;
    }
}


- (float) visibilityRange {
    // if it's idle then it sees the max distance
    if ([self isIdle]) {
        return sParameters[ kParamMaxTotalVisibilityF ].floatValue;
    }

    // it's doing something, less visibility range
    return sParameters[ kParamMaxActiveVisibilityF ].floatValue;
}


- (float) changeModeTime {
    // in seconds

    // are we in command?
    float inCommandFactor = self.inCommand ? 1.0f : 1.4f;

    // experience modifier
    float experienceModifier = 1.0;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 1.2;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 0.9;
            break;
        case kElite:
            experienceModifier = 0.75;
            break;
    }

    switch (self.type) {
        case kInfantryHeadquarter:
            return (80.0f + CCRANDOM_0_1() * 20.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kInfantry:
            return (110.0f + CCRANDOM_0_1() * 20.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kCavalry:
            return (130.0f + CCRANDOM_0_1() * 20.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kCavalryHeadquarter:
            return (110.0f + CCRANDOM_0_1() * 20.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kArtillery:
            return (200.0f + CCRANDOM_0_1() * 40.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;
    }
}


- (float) commandRange {
    switch (self.experience) {
        case kGreen:
            return sParameters[ kParamCommandRangeGreenF ].floatValue;

        case kRegular:
            return sParameters[ kParamCommandRangeRegularF ].floatValue;

        case kVeteran:
            return sParameters[ kParamCommandRangeVeteranF ].floatValue;

        case kElite:
            return sParameters[ kParamCommandRangeEliteF ].floatValue;
    }
}


- (float) commandDelay {
    if (self.inCommand) {
        return sParameters[ kParamCommandDelayInCommandF ].floatValue;
    }

    return sParameters[ kParamCommandDelayNotInCommandF ].floatValue;
}


- (float) organizingTime {
    // in seconds

    // are we in command?
    float inCommandFactor = self.inCommand ? 1.0f : 1.5f;

    // experience modifier
    float experienceModifier = 1.0f;
    switch (self.experience) {
        case kGreen:
            experienceModifier = 1.2;
            break;
        case kRegular:
            experienceModifier = 1.0;
            break;
        case kVeteran:
            experienceModifier = 0.9;
            break;
        case kElite:
            experienceModifier = 0.75;
            break;
    }

    switch (self.type) {
        case kInfantryHeadquarter:
            return (40 + CCRANDOM_0_1() * 40.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kInfantry:
            return (60 + CCRANDOM_0_1() * 40.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kCavalry:
            return (80 + CCRANDOM_0_1() * 40.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kCavalryHeadquarter:
            return (60 + CCRANDOM_0_1() * 40.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;

        case kArtillery:
            return (120 + CCRANDOM_0_1() * 50.0f) * inCommandFactor * experienceModifier * self.weapon.movementSpeedModifier;
    }
}


- (BOOL) destroyed {
    return self.men <= 0;
}


- (int) weaponCount {
    //NSLog(@"men: %d, required: %d, count: %d", self.men, self.weapon.menRequired, self.men / self.weapon.menRequired );
    return self.men / self.weapon.menRequired;
}


- (void) setMission:(Mission *)mission {
    // any old mission?
    if (_mission) {
        // make sure it forgets the unit
        _mission.unit = nil;
    }

    // never set a nil mission
    if (mission == nil) {
        NSLog( @"nil mission, setting to idle" );
        mission = [IdleMission new];
    }

    // any old mission?
    if (_mission && _mission.type == mission.type) {
        // setting the same type of mission again so we don't have any command delay for that. set it to the previous's mission's delay
        // to make sure it's not the magical "no delay set yet" value. this also makes cheats with setting a new same mission while the
        // command delay is ticking down impossible
        mission.commandDelay = _mission.commandDelay;
        //NSLog( @"setting mission without command delay: %@ for %@", mission, self );
    }

    _mission = mission;
    NSLog( @"setting mission: %@ for %@", mission, self );

    // make sure the mission knows us too
    _mission.unit = self;
}


- (void) setAutoFireEnabled:(BOOL)autoFireEnabled {
    _autoFireEnabled = autoFireEnabled;

    // does the unit currently fire? if so it should stop firing immediately
    if ( autoFireEnabled && ([self isCurrentMission:kFireMission] || [self isCurrentMission:kAreaFireMission] || [self isCurrentMission:kSmokeMission] ) ) {
        self.mission = nil;
    }
}


- (BOOL) isCurrentMission:(MissionType)type {
    return self.mission && self.mission.type == type;
}


- (BOOL) canFire {
    return [self canBeGivenMissions] && self.mode == kFormation && self.men > 0;
}


- (BOOL) canBeGivenMissions {
    // first the "doh" condition
    if (self.destroyed) {
        return NO;
    }

    // is the morale high enough and fatigue low enough?
    if (self.morale < sParameters[ kParamMinMoraleForMissionsF].floatValue || self.fatigue > sParameters[ kParamMaxFatigueForMissionsF].floatValue) {
        // too low morale or too high fatigue
        return NO;
    }

    if (self.mission == nil || self.mission.type == kIdleMission) {
        // no missions, all is ok
        return YES;
    }

    // can the current mission be cancelled?
    if (self.mission.canBeCancelled) {
        return YES;
    }

    // can't be cancelled, so it must run until finished, no missions can be given
    return NO;
}


- (BOOL) isIdle {
    if (self.mission == nil || self.mission.type == kIdleMission) {
        return YES;
    }

    // doing something
    return NO;
}

//
//- (void) smoothMoveTo:(CGPoint)position {
//    [self runAction:[CCMoveTo actionWithDuration:sParameters[kParamEngineUpdateIntervalF].floatValue - 0.05f position:position]];
//
//    // send to the other player too if this is a multiplayer game and the unit is local
//    if ([Globals sharedInstance].gameType == kMultiplayerGame && self.owner == [Globals sharedInstance].localPlayer.playerId) {
//        // create data with the unit id and target position
//        int unitId = self.unitId;
//        NSMutableData *data = [NSMutableData dataWithBytes:&unitId length:sizeof( unitId )];
//        [data appendData:[NSMutableData dataWithBytes:&position.x length:sizeof( CGFloat )]];
//        [data appendData:[NSMutableData dataWithBytes:&position.y length:sizeof( CGFloat )]];
//    }
//}
//
//
//- (void) smoothTurnTo:(float)facing {
//    [self runAction:[CCRotateTo actionWithDuration:sParameters[kParamEngineUpdateIntervalF].floatValue - 0.05f angle:facing]];
//
//    // send to the other player too if this is a multiplayer game and the unit is local. don't send for remote unitDefinitions
//    if ([Globals sharedInstance].gameType == kMultiplayerGame && self.owner == [Globals sharedInstance].localPlayer.playerId) {
//        // create data with the unit id and target facing
//        int unitId = self.unitId;
//        NSMutableData *data = [NSMutableData dataWithBytes:&unitId length:sizeof( unitId )];
//        [data appendData:[NSMutableData dataWithBytes:&facing length:sizeof( facing )]];
//    }
//}
//

//- (BOOL) isHit:(CGPoint)pos {
//    // find out the largest dimension of the sprite
//    float radius = MAX( self.boundingBox.size.width, self.boundingBox.size.height ) / 2.0f;

// but never go below a certain minimum
//    radius = MAX( radius, 20 );

//    return ccpDistance( self.position, pos ) < radius;

// see: http://www.visibone.com/inpoly/
/*
 // destroyed or not inside our bounding rect?
 if ( self.destroyed || ! CGRectContainsPoint( self.boundingBox, pos ) ) {
 // not inside
 return NO;
 }

 CGPoint unit_pos = self.position;

 float xt = pos.x;
 float yt = pos.y;
 float xnew,ynew;
 float xold,yold;
 float x1,y1;
 float x2,y2;
 BOOL inside= NO;

 float width  = self.boundingBox.size.width;
 float height = self.boundingBox.size.height;

 CGPoint corners[] = {
 ccp( -width / 2.0f, -height / 2.0f ),
 ccp( -width / 2.0f,  height / 2.0f ),
 ccp(  width / 2.0f,  height / 2.0f ),
 ccp(  width / 2.0f, -height / 2.0f )
 };

 // rotate the corners
 for ( int index = 0; index < 4; ++index ) {
 corners[ index ] = ccpRotateByAngle( corners[ index ], ccp( 0, 0 ), -CC_DEGREES_TO_RADIANS( self.rotation ) );
 }

 xold = unit_pos.x + corners[3].x;
 yold = unit_pos.y + corners[3].y;

 for ( unsigned int i = 0 ; i < 4 ; i++) {
 xnew = unit_pos.x + corners[i].x;
 ynew = unit_pos.y + corners[i].y;

 if (xnew > xold) {
 x1 = xold;
 x2 = xnew;
 y1 = yold;
 y2 = ynew;
 }
 else {
 x1 = xnew;
 x2 = xold;
 y1 = ynew;
 y2 = yold;
 }

 if ( (xnew < xt) == (xt <= xold)          // edge "open" at one end
 && (yt - y1) * (x2-x1) < (y2 - y1) * (xt-x1)) {
 inside = !inside;
 }

 xold = xnew;
 yold = ynew;
 }

 return inside;
 */
//}


- (BOOL) isInsideFiringArc:(CGPoint)pos checkDistance:(BOOL)checkDistance {
    // first check the range
    if (checkDistance && ccpDistance( self.position, pos ) > self.weapon.firingRange) {
        // too far out
        return NO;
    }

    // the angle to rotate towards. 0 is up so the angle must be relative to that and negative for ccw
    float angle_to_target = CC_RADIANS_TO_DEGREES( ccpAngleSigned( ccpSub( pos, self.position ), ccp( 0, 1 ) ) );

    float current_facing = self.rotation;
    float halfArc = self.weapon.firingAngle / 2.0f;

    // is it inside then?
    if ((current_facing - halfArc < angle_to_target && angle_to_target < current_facing + halfArc) ||
            (current_facing - halfArc < angle_to_target + 360 && angle_to_target + 360 < current_facing + halfArc)) {
        return YES;
    }

    return NO;
}


- (BOOL) isOutflankedFromPos:(CGPoint)pos {
    // first the distance to the position
    float distance = ccpDistance( pos, self.position );

    if (distance < sParameters[kParamMinOutflankingDistanceF].floatValue) {
        // too close, can't outflank at point blank
        return NO;
    }

    // outflanked means that the pos is not inside our firing arc
    return ![self isInsideFiringArc:pos checkDistance:NO];
}


+ (Unit *) createUnitType:(UnitType)type forOwner:(PlayerId)player mode:(UnitMode)mode men:(int)men morale:(float)morale fatigue:(float)fatigue
                   weapon:(WeaponType)weapon experience:(ExperienceType)experience ammo:(int)ammo {
    Unit *unit = [Unit new];

    unit.type = type;
    unit.experience = experience;
    unit.owner = player;

    // make sure to set the wepon before the men to avoid divide by zero
    unit.weapon = [[Weapon alloc] initWithType:weapon];
    unit.weapon.ammo = ammo;
    unit.men = men;
    unit.originalMen = men;
    unit.mode = mode;
    unit.morale = morale;
    unit.fatigue = fatigue;

    // assume we last fired when the game started
    unit.lastFired = [Globals sharedInstance].scenario.startTime;

    // no mission yet
    unit.mission = nil;

    return unit;
}

@end
