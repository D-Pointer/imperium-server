
#import "Mission.h"
#import "Globals.h"
#import "TerrainModifiers.h"
#import "Map.h"
#import "MeleeMission.h"
#import "Message.h"
#import "Engine.h"
#import "RotateMission.h"
#import "LineOfSight.h"

@interface Mission ()

@property (nonatomic, assign) int stackingRetries;

@end

@implementation Mission

- (id) init {
    self = [super init];
    if (self) {
        self.unit = nil;

        // never any path initially
        self.path = nil;
        
        // all missions can be cancelled by default
        self.canBeCancelled = YES;

        // no rotation yet
        self.rotation = nil;

        // no stacking errors yet
        self.stackingRetries = 0;

        // set up the command delay to a magical value that will never be reached
        self.commandDelay = -100000;
    }

    return self;
}


- (float) commandDelay {
    if ( _commandDelay == -100000 ) {
        // it has not yet been set at all, use the initial delay from the unit
        self.commandDelay = self.unit.commandDelay;
    }

    return _commandDelay;
}


- (void) setRotation:(RotateMission *)rotation {
    // this makes sure that internal rotation missions get a unit to operate on, otherwise they end up with
    // a nil unit and never complete
    _rotation = rotation;
    _rotation.unit = self.unit;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[%@ %.0f %.0f]", self.class, self.endPoint.x, self.endPoint.y];
}


- (void) setUnit:(Unit *)unit {
    _unit = unit;

    // make sure the rotation mission also gets the unit. when deserializing the unit is not yet set and
    // the rotation mission will otherwise not have a unit. This unit is set later when loading
    if ( self.rotation ) {
        self.rotation.unit = unit;
    }
}


- (MissionState) execute {
    // do nothing
    NSAssert( NO, @"Must be overridden" );
    return kInProgress;
}


- (NSString *) save {
    NSAssert( NO, @"Must be overridden" );
    return nil;
}


- (BOOL) loadFromData:(NSArray *)parts {
    NSAssert( NO, @"Must be overridden" );
    return NO;
}


- (MissionState) moveUnit:(Unit *)unit alongPath:(Path *)path withSpeed:(float)speed {
    // do we have a rotation going on?
    if ( self.rotation ) {
        // if this is our final rotation then we're completed when it's done.
        if ( [self.rotation execute] == kCompleted ) {
            if ( path.count == 0 ) {
                // entire movement is done
                return kCompleted;
            }

            self.rotation = nil;
        }
        else {
            // rotation is still in progress
            return kInProgress;
        }
    }

    // initially we have all the time left for this step (which may not be true if some other mission
    // was completed this same step)
    float timeLeft = [Globals sharedInstance].clock.lastElapsedTime;

    // starting pos
    CGPoint old_pos = unit.position;

    // loop while there are path elements left and time left for this step
    while ( path.count > 0 && timeLeft > 0.01f ) {
        // we move towards the first position in the path
        CGPoint target = path.firstPosition;

        //NSLog( @"time left: %.1f, moving towards: %.1f, %.1f", timeLeft, target.x, target.y );

        // terrain under the unit
        TerrainType terrain_type = [[Globals sharedInstance].map getTerrainForUnit:unit];

        // terrain modifier
        float terrainModifier = getTerrainMovementModifier( unit, terrain_type );

        // can it even move there?
        if ( terrainModifier < 0 ) {
            // impassable, movement is now done
            NSLog( @"impassable" );
            return kCompleted;
        }

        // do we need to turn?
        if ( self.type != kRetreatMission && ! [unit isInsideFiringArc:target checkDistance:NO] ) {
            // set up a rotation mission to face the unit towards the next step
            self.rotation = [[RotateMission alloc] initFacingTarget:target];

            // start executing it, if it's done we get rid of it and continue
            if ( [self.rotation execute] == kInProgress ) {
                return kInProgress;
            }

            self.rotation = nil;
        }

        // how far is it to the waypoint?
        float distanceToWaypoint = ccpDistance( old_pos, target );

        // how far does the unit move in the time left?
        float maxDistance = speed * terrainModifier * timeLeft;


        // a normalized vector towards the target
        CGPoint heading = ccpNormalize( ccpSub( target, old_pos ) );

        // modify with how far the unit moves with the time left
        CGPoint maxMovement = ccpMult( heading, maxDistance );

        //NSLog( @"dist: %.2f, max travel: %.2f", distanceToWaypoint, maxDistance );

        CGPoint new_position;
        float timeUsed;

        // avoid overshooting the destination! if we move too far we will get an oscillating movement over the
        // endpoint that never stops
        if ( distanceToWaypoint < maxDistance ) {
            new_position = target;

            timeUsed = timeLeft * ( distanceToWaypoint / maxDistance );
            timeLeft -= timeUsed;

            // get rid of this position
            [path removeFirstPosition];

            // did we reach the end of the path now?
            if ( path.count == 0 && self.type != kRetreatMission ) {
                // set up a final rotation mission to face the unit towards the last step
                self.rotation = [[RotateMission alloc] initFacingTarget:path.finalFacingTarget];
                //NSLog( @"rotating to face final target: %.1f %.1f", path.finalFacingTarget.x, path.finalFacingTarget.y );
            }
        }
        else {
            new_position = ccpAdd( old_pos, maxMovement );

            // all time used for this
            timeUsed = timeLeft;
            timeLeft = -1;
        }

        //NSLog( @"new pos: %.1f, %.1f", new_position.x, new_position.y );

        // is there any unit nearby?
        //bool stackingOk = YES;
        for ( Unit * tmp in [Globals sharedInstance].units ) {
            // don't check against ourselves or dead units
            if ( unit == tmp || tmp.destroyed ) {
                continue;
            }

            if ( ccpDistance( new_position, tmp.position ) < sParameters[ kParamMinStackingDistanceF].floatValue ) {
                // unit would stack with the other unit, should we wait?
                if ( self.stackingRetries++ < sParameters[ kParamMaxStackingRetriesI].intValue ) {
                    // wait a bit longer
                    return kInProgress;
                }

                // we've waited long enough
                NSLog( @"%@ would stack with %@, cancelling mission", unit, tmp );

                // is the unit an own unit? don't show stacking errors for enemies
                //if ( unit.owner == [Globals sharedInstance].localPlayer.playerId ) {
                [self addMessage:kNoStackingAllowed forUnit:unit];
                //}

                return kCompleted;
            }
        }

        // rotation needed?
        [self turnUnit:unit toFace:new_position withMaxDeviation:sParameters[kParamMaxTurnDeviationF].floatValue inTime:timeUsed];

        // movement
        //CCMoveTo * movement = [CCMoveTo actionWithDuration:timeUsed / [Globals sharedInstance].clock.lastElapsedTime
        //                                          position:new_position];

        // move and rotate?
//        if ( rotation ) {
//            [result addObject:[CCSpawn actionOne:rotation two:movement]];
//        }
//        else {
//            // move to the new position
//            [result addObject:movement];
//        }

        //NSLog( @"moving to pos: %.1f, %.1f in %.1f", new_position.x, new_position.y, timeUsed );
        old_pos = new_position;
    }

    // no stacking problems
    self.stackingRetries = 0;

    // still moving
    if ( path.count == 0 && self.rotation == nil ) {
        return kCompleted;
    }

    return kInProgress;
}


- (MissionState) turnUnit:(Unit *)unit toFace:(CGPoint)target withMaxDeviation:(float)deviation {
    // rotation amount and direction for the unit
    float rotation = [self turningAngleAndDirectionFor:unit toFace:target];

    // close enough?
    if ( fabsf( rotation ) < deviation ) {
        return kCompleted;
    }

    // how much has the unit now rotated since the last update?
    float rotated = unit.rotationSpeed * [Globals sharedInstance].clock.lastElapsedTime;

    // has it arrived? ie. would a single rotation now take it past the target? if so we just rotate to the target
    // and then the next step we're done
    if ( fabsf( rotation ) <= rotated ) {
        // turn smoothly, but we're not yet done
        //[unit smoothTurnTo:unit.rotation + rotation];
        unit.rotation += rotation;
        return kInProgress;
    }

    // turn clockwise?
    if ( rotation > 0 ) {
        //[unit smoothTurnTo:unit.rotation + rotated];
        unit.rotation += rotated;
    }
    else {
        // turn smoothly counter clockwise
        //[unit smoothTurnTo:unit.rotation - rotated];
        unit.rotation -= rotated;
    }

    return kInProgress;
}


- (void) turnUnit:(Unit *)unit toFace:(CGPoint)target withMaxDeviation:(float)deviation inTime:(float)seconds {
    // retreat missions do not turn
    if ( self.type == kRetreatMission ) {
        return;
    }

    // rotation amount and direction for the unit
    float rotation = [self turningAngleAndDirectionFor:unit toFace:target];

    // close enough?
    if ( fabsf( rotation ) < deviation ) {
        return;
    }

    // how much has the unit now rotated since the last update?
    float rotated = unit.rotationSpeed * seconds;

    // has it arrived? ie. would a single rotation now take it past the target? if so we just rotate to the target
    // and then the next step we're done
    if ( fabsf( rotation ) <= rotated ) {
        // turn smoothly, but we're not yet done
//        return [CCRotateTo actionWithDuration:seconds / [Globals sharedInstance].clock.lastElapsedTime
//                                        angle:unit.rotation + rotation];
        unit.rotation += rotation;
    }

    // turn clockwise?
    if ( rotation > 0 ) {
//        return [CCRotateTo actionWithDuration:seconds / [Globals sharedInstance].clock.lastElapsedTime
//                                        angle:unit.rotation + rotated];
        unit.rotation += rotated;
    }

    // turn smoothly counter clockwise
//    return [CCRotateTo actionWithDuration:seconds / [Globals sharedInstance].clock.lastElapsedTime
//                                    angle:unit.rotation - rotated];
    unit.rotation -= rotated;
}


- (float) turningAngleAndDirectionFor:(Unit *)unit toFace:(CGPoint)pos {
    float angleToTarget = CC_RADIANS_TO_DEGREES( ccpAngleSigned( ccpSub(pos, unit.position), ccp(0, 1) ) );

    if ( angleToTarget < 0 ) {
        angleToTarget += 360;
    }

    // fix up a positive facing
    float facing = unit.rotation;
    if ( facing < 0 ) {
        facing += 360;
    }

    float delta = angleToTarget - facing;
    float cw, ccw;

    if ( delta <= -180 ) {
        cw = delta + 360;
        ccw = -delta;
    }
    else if ( delta < 0 ) {
        cw = delta + 360;
        ccw = -delta;
    }
    else if ( delta > 180 ) {
        cw = delta;
        ccw = 360 - delta;
    }
    else { // delta >= 0
        cw = delta;
        ccw = 360 - delta;
    }

    // which distance is shorter?
    if ( cw < ccw ) {
        // clockwise is shorter, return a positive value
        return cw;
    }

    // counter clockwise is shorter, return a negative value
    return -ccw;
}


- (unsigned char *)serialize:(unsigned short *)length {
    // the data is serialized as: unitd, mission type
    *length = sizeof( unsigned short ) + 1;
    unsigned char *buffer = malloc( *length );

    unsigned short offset = 0;

    // unit id
    unsigned short unitId = self.unit.unitId;
    memcpy( buffer + offset, &unitId, sizeof( unsigned short ) );
    offset += sizeof( unsigned short );

    // type
    buffer[offset++] = (unsigned char) self.type;

    return buffer;
}


@end

