
#import "DisorganizedMission.h"
#import "Unit.h"
#import "Globals.h"

@interface DisorganizedMission ()

@property (nonatomic, assign) int organizedTimed;

@end

@implementation DisorganizedMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kDisorganizedMission;
        self.name = @"Reorganizing";
        self.preparingName = @"Preparing to reorganize";

        // this can not be cancelled by the player
        self.canBeCancelled = NO;
        
        // default invalid end time
        self.organizedTimed = -1;

        // by default normal organization time
        self.fastReorganizing = NO;
        self.fatigueEffect = sParameters[kParamDisorganizedFatigueEffectF].floatValue;
    }

    return self;
}


- (float) commandDelay {
    // this never has any delay
    return -1;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[%@]", self.class];
}


- (MissionState) execute {
    // has the target died? it can have been killed by another unit
    if ( self.unit == nil || self.unit.destroyed ) {
        return kCompleted;
    }

    // are we now disorganized and waiting for the unit to be battle ready again?
    if ( self.organizedTimed != -1 ) {
        // have we completed?
        if ( [Globals sharedInstance].clock.currentTime > self.organizedTimed ) {
            // we're now done
            NSLog( @"unit %@ is no longer disorganized", self.unit.name );
            return kCompleted;
        }

        // still organizing it
        return kInProgress;
    }

    // the reorganization time for the unit. it's halved if fast reorganization is needed
    int organizingTime = self.fastReorganizing ? (int)self.unit.organizingTime * 0.5f : (int)self.unit.organizingTime;

    self.organizedTimed = [Globals sharedInstance].clock.currentTime + organizingTime;
    NSLog( @"unit %@ is now disorganized until: %d (%d seconds)", self.unit.name, self.organizedTimed, (int)self.unit.organizingTime );

    // still going
    return kInProgress;
}


- (NSString *) save {
    // target x, y, path
    return [NSString stringWithFormat:@"m %d %d %d %.1f %.1f\n",
            self.type,
            self.canBeCancelled ? 1 : 0,
            self.organizedTimed,
            self.endPoint.x,
            self.endPoint.y ];
}


- (BOOL) loadFromData:(NSArray *)parts {
    // can we be cancelled?
    if ( [parts[0] intValue] == 1 ) {
        self.canBeCancelled = YES;
    }
    else {
        self.canBeCancelled = NO;
    }

    self.organizedTimed = [parts[1] intValue];
    self.endPoint = CGPointMake( [parts[2] floatValue], [parts[3] floatValue] );

    // all is ok
    return YES;
}

@end
