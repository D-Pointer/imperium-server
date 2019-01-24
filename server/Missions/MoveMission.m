
#import "MoveMission.h"
#import "Unit.h"
#import "Globals.h"
#import "RotateMission.h"

@implementation MoveMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kMoveMission;
        self.name = @"Moving";
        self.preparingName = @"Preparing to move";
        self.color = sMoveLineColor;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamMoveFatigueEffectF].floatValue;
    }
    
    return self;
}


- (id) initWithPath:(Path *)path {
    self = [super init];
    if (self) {
        self.path = path;
        self.type = kMoveMission;
        self.name = @"Moving";
        self.preparingName = @"Preparing to move";
        self.endPoint = path.lastPosition;
        self.color = sMoveLineColor;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamMoveFatigueEffectF].floatValue;
    }

    return self;
}


- (MissionState) execute {
    return [self moveUnit:self.unit alongPath:self.path withSpeed:self.unit.movementSpeed];
}


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
        self.rotation = [[RotateMission alloc] initFacingTarget:CGPointMake( [parts[1] floatValue], [parts[2] floatValue] )];

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
