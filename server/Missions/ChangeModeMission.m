
#import "ChangeModeMission.h"
#import "Unit.h"
#import "Globals.h"

@interface ChangeModeMission ()

@property (nonatomic, assign) float startTime;
@property (nonatomic, assign) float completedTime;

@end



@implementation ChangeModeMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kChangeModeMission;
        self.name = @"Changing mode";
        self.preparingName = @"Preparing to change mode";
        
        self.startTime = -1.0f;
        self.completedTime = -1.0f;
        self.fatigueEffect = sParameters[kParamChangeModeFatigueEffectF].floatValue;
    }
    
    return self;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[%@]", self.class];
}


- (MissionState) execute {
    // has the target died? it can have been killed by another unit
    if ( self.unit == nil || self.unit.destroyed ) {
        return kCompleted;
    }

    // not yet started?
    if ( self.startTime < 0 ) {
        // now it starts
        NSLog( @"starting to change mode for %@", self.unit.name );
        self.startTime = [Globals sharedInstance].clock.currentTime;
        self.completedTime = self.startTime + self.unit.changeModeTime;
        NSLog( @"time: %.0f, start: %.0f, end: %.0f", self.completedTime - self.startTime, self.startTime, self.completedTime );

        // the mode we change into
        UnitMode changingTo = self.unit.mode == kFormation ? kColumn : kFormation;

        // set the name to be suitable
        switch ( self.unit.type ) {
            case kInfantry:
            case kInfantryHeadquarter:
            case kCavalry:
            case kCavalryHeadquarter:
                if ( changingTo == kColumn ) {
                    self.name = @"Changing to column";
                }
                else {
                    self.name = @"Changing to formation";
                }
                break;

            case kArtillery:
                if ( changingTo == kColumn ) {
                    self.name = @"Limbering";
                }
                else {
                    self.name = @"Unlimbering";
                }
                break;
        }

        return kInProgress;
    }    
    
    // have we completed?
    if ( [Globals sharedInstance].clock.currentTime > self.completedTime ) {
        // we're now done
        UnitMode mode = self.unit.mode == kFormation ? kColumn : kFormation;
        self.unit.mode = mode;

        // for a multiplayer case we need special handling.
//        if ( [Globals sharedInstance].gameType == kMultiplayerGame ) {
//            // create data with the unit id and target position
//            int unitId = self.unit.unitId;
//            NSMutableData * data = [NSMutableData dataWithBytes:&unitId length: sizeof(unitId)];
//            [data appendData:[NSMutableData dataWithBytes:&mode length: sizeof(mode)]];
//
//            // TODO: multiplayer
//            //[[Globals sharedInstance].connection sendMessage:kChangeModeMessage withData:data];
//        }
        
        NSLog( @"completed mode change for %@, now: %d", self.unit.name, mode );
        return kCompleted;
    }
    
    // still going
    return kInProgress;
}


- (NSString *) save {
    return [NSString stringWithFormat:@"m %d %.1f %.1f %.1f %.1f\n",
            self.type,
            self.startTime,
            self.completedTime,
            self.endPoint.x,
            self.endPoint.y ];
}


- (BOOL) loadFromData:(NSArray *)parts {
    // startTime completedTime endX endY
    self.startTime     = [parts[0] floatValue];
    self.completedTime = [parts[1] floatValue];
    self.endPoint      = CGPointMake( [parts[2] floatValue], [parts[3] floatValue] );

    // all is ok
    return YES;
}

@end
