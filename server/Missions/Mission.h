

#import "Definitions.h"
#import "Path.h"
#import "CGPointExtension.h"

@class Unit;
@class RotateMission;

@interface Mission : NSObject

@property (nonatomic, weak)   Unit *          unit;
@property (nonatomic, assign) MissionType     type;
@property (nonatomic, strong) NSString *      name;
@property (nonatomic, strong) NSString *      preparingName;
@property (nonatomic, assign) CGPoint         endPoint;
@property (nonatomic, assign) BOOL            canBeCancelled;
@property (nonatomic, strong) Path *          path;
@property (nonatomic, strong) RotateMission * rotation;
@property (nonatomic, assign) float           commandDelay;
@property (nonatomic, assign) float           fatigueEffect;

- (MissionState) execute;

// Saves the mission to a newline terminated string. Starts with "m X" where X is the mission type.
- (NSString *) save;

// Loads the mission from an array of parts. The "m X" parts have been removed from the array.
- (BOOL) loadFromData:(NSArray *)parts;


// private

- (MissionState) moveUnit:(Unit *)unit alongPath:(Path *)path withSpeed:(float)speed;

- (MissionState) turnUnit:(Unit *)unit toFace:(CGPoint)target withMaxDeviation:(float)deviation;

- (void) turnUnit:(Unit *)unit toFace:(CGPoint)target withMaxDeviation:(float)deviation inTime:(float)seconds;

- (void) addMessage:(MessageType)message forUnit:(Unit *)unit;

// Returns a degree angle for how much the unit must turn to face pos. The angle is <0 for ccw turning and >0 for cw.
- (float) turningAngleAndDirectionFor:(Unit *)unit toFace:(CGPoint)pos;

- (unsigned char *) serialize:(unsigned short *)length;

@end
