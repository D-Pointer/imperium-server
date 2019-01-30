#import "RotateMission.h"
#import "Unit.h"
#import "Definitions.h"

@interface RotateMission () {
    float maxDeviation;
}

@end


@implementation RotateMission

@synthesize target;

- (id)init {
    self = [super init];
    if (self) {
        self.type = kRotateMission;
        self.name = @"Turning";

        // max deviation from the target angle
        maxDeviation = sParameters[kParamMaxTurnDeviationF].floatValue;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamRotateFatigueEffectF].floatValue;
    }

    return self;
}


- (id)initFacingTarget:(CGPoint)pos {
    self = [super init];
    if (self) {
        self.type = kRotateMission;
        self.name = @"Turning";
        self.preparingName = @"Preparing to turn";
        self.target = pos;
        self.endPoint = pos;

        // max deviation from the target angle
        maxDeviation = sParameters[kParamMaxTurnDeviationF].floatValue;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamRotateFatigueEffectF].floatValue;
    }

    return self;
}


- (id)initFacingTarget:(CGPoint)pos maxDeviation:(float)deviation {
    self = [super init];
    if (self) {
        self.name = @"Turning";
        self.preparingName = @"Preparing to turn";
        self.target = pos;
        self.endPoint = pos;

        // max deviation from the target angle
        maxDeviation = deviation;
    }

    return self;
}


- (MissionState) execute {
    return [self turnUnit:self.unit toFace:self.target withMaxDeviation:maxDeviation];
}


- (NSString *)save {
    // target x, y
    return [NSString stringWithFormat:@"m %d %.1f %.1f\n",
                                      self.type,
                                      self.target.x,
                                      self.target.y];
}


- (BOOL)loadFromData:(NSArray *)parts {
    // targetX targetY
    self.target = CGPointMake( [parts[0] floatValue], [parts[1] floatValue] );
    self.endPoint = self.target;

    // all is ok
    return YES;
}


- (unsigned char *)serialize:(unsigned short *)length {
    // allocate a buffer for: unitid, type, x, y
    *length = sizeof( unsigned short ) + 1 + sizeof( float ) * 2;
    unsigned char *buffer = malloc( *length );

    unsigned short offset = 0;

    unsigned short unitId = self.unit.unitId;
    float x = self.target.x;
    float y = self.target.y;

    // type
    buffer[offset++] = (unsigned char) self.type;

    // unit id
    memcpy( buffer + offset, &unitId, sizeof( unsigned short ) );
    offset += sizeof( unsigned short );

    // target x, y
    memcpy( buffer + offset, &x, sizeof( float ) );
    offset += sizeof( float );
    memcpy( buffer + offset, &y, sizeof( float ) );

    return buffer;
}


@end
