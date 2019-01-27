
#import "ScoutMission.h"
#import "RotateMission.h"
#import "Unit.h"
#import "Globals.h"
#import "Map.h"
#import "LineOfSight.h"


@implementation ScoutMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kScoutMission;
        self.name = @"Scouting";
        self.preparingName = @"Preparing to scout";

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamScoutFatigueEffectF].floatValue;
    }
    
    return self;
}


- (id) initWithPath:(Path *)path {
    self = [super init];
    if (self) {
        self.path = path;
        self.type = kScoutMission;
        self.name = @"Scouting";
        self.preparingName = @"Preparing to scout";
        self.endPoint = path.lastPosition;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamScoutFatigueEffectF].floatValue;
    }

    return self;
}


- (MissionState) execute {

    // are we starting up now?
//    if ( self.enemiesSeenAtStart == nil ) {
//        NSMutableSet * tmpSet = [NSMutableSet setWithCapacity:self.unit.losData.seenCount];
//        for ( unsigned int index = 0; index < self.unit.losData.seenCount; ++index ) {
//            [tmpSet addObject:[self.unit.losData getSeenUnit:index]];
//        }
//
//        self.enemiesSeenAtStart = tmpSet;
//
//        NSLog( @"at start unit %@ sees %lu enemies", self.unit, (unsigned long)self.enemiesSeenAtStart.count );
//    }

    if ( [self moveUnit:self.unit alongPath:self.path withSpeed:self.unit.scoutingSpeed] == kCompleted ) {
        // we're done
        return kCompleted;
    }

    // has it seen new enemies?
    if ( self.unit.losData.didSpotNewEnemies ) {
        NSLog( @"%@ found new enemies, mission done", self.unit );
        return kCompleted;
    }

    // did we see any new enemy?
//    if ( [self checkForNewSeenEnemies:self.unit] ) {
//        // found new enemies
//        NSLog( @"found new enemies, mission done" );
//        //[self addMessage:kNewEnemySpottedStopping forUnit:self.unit];
//        return kCompleted;
//    }

    // scout on
    return kInProgress;
}


//- (BOOL) checkForNewSeenEnemies:(Unit *)mover {
//    // what enemies does it see now?
//    NSMutableSet * currentEnemies = [NSMutableSet setWithCapacity:mover.losData.seenCount];
//    for ( unsigned int index = 0; index < mover.losData.seenCount; ++index ) {
//        [currentEnemies addObject:[mover.losData getSeenUnit:index]];
//    }
//
//    //[[Globals sharedInstance].lineOfSight getEnemiesSeenBy:mover];
//
//    BOOL newFound = NO;
//
//    // do we see more enemies now?
//    if ( currentEnemies.count > self.enemiesSeenAtStart.count ) {
//        // new enemies seen
//        NSLog( @"%@ sees new enemies", mover );
//        newFound = YES;
//    }
//
//    // if the current enemies is a subset of the ones seen at start then we have no new enemies
//    if ( ! [currentEnemies isSubsetOfSet:self.enemiesSeenAtStart] ) {
//        // new enemies seen
//        NSLog( @"%@ sees new enemies", mover );
//        newFound = YES;
//    }
//
//    self.enemiesSeenAtStart = [NSSet setWithSet:currentEnemies];
//
//    return newFound;

    /*
      NSMutableArray * enemies = mover.owner == kPlayer1 ? [Globals sharedInstance].unitsPlayer2 : [Globals sharedInstance].unitsPlayer1;

     MapLayer * map = [Globals sharedInstance].map;

     LineOfSight * los = [Globals sharedInstance].lineOfSight;

     // loop all enemies
     for ( Unit * enemy_unit in enemies ) {
     // don't check destroyed units
     if ( enemy_unit.destroyed ) {
     continue;
     }

     // was it seen before we moved?
     if ( enemy_unit.visible == YES ) {
     // yeah, don't care about this unit, it's already seen
     continue;
     }

     // not visible, can we now see it?
     if ( [los canUnit:mover seeTarget:enemy_unit] ) {
     //if ( [map canSeeFrom:mover.position to:enemy_unit.position visualize:NO] ) {
     // now we see it, so that means the scout mission found it
     NSLog( @"%@ found %@", mover.name, enemy_unit.name );
     // TODO: multiplayer
     enemy_unit.visible = YES;
     return YES;
     }
     }

     // no new unit found
     return NO;
     */
//}


- (NSString *) save {
    if ( self.rotation ) {
        // target x, y path
        return [NSString stringWithFormat:@"m %d 1 %.1f %.1f %@\n",
                self.type,
                self.rotation.target.x,
                self.rotation.target.y,
                [self.path save]];
    }
    else {
        // target x, y and endpoint x, y
        return [NSString stringWithFormat:@"m %d 0 %@\n",
                self.type,
                [self.path save]];
    }
}


- (BOOL) loadFromData:(NSArray *)parts {
    // add a rotate mission too?
    if ( [parts[0] intValue] == 1 ) {
        // NOTE: the unit self.unit is not yet valid here, so the rotate mission will have a nil unit initially. it gets set
        // in Mission:setUnit when the unit is assigned

        // facingX facingY path
        self.rotation = [[RotateMission alloc]initFacingTarget:CGPointMake( [parts[1] floatValue], [parts[2] floatValue] )];

        // load the path
        self.path = [Path pathFromData:parts startIndex:3];
    }
    else {
        // only path
        self.path = [Path pathFromData:parts startIndex:1];
    }

    // all is ok
    return YES;
}


@end
