
#import <Foundation/Foundation.h>


@class Unit;

@interface LineOfSightData : NSObject

@property (nonatomic, readonly) unsigned int count;
@property (nonatomic, readonly) unsigned int seenCount;
@property (nonatomic, readonly) unsigned int oldSeenCount;
@property (nonatomic, assign)   BOOL         didSpotNewEnemies;

- (instancetype) initWithUnits:( NSMutableArray * )units;

- (void) clearSeen;

- (void) setSeen:(Unit *)unit;

- (BOOL) seesUnit:(Unit *) unit;

- (Unit *) getSeenUnit:(unsigned int)index;

- (Unit *) getPreviouslySeenUnit:(unsigned int)index;

- (BOOL) wasUnitPreviouslySeen:(Unit *)unit;

@end
