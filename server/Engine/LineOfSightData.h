
#import <Foundation/Foundation.h>


@class Unit;

@interface LineOfSightData : NSObject

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSUInteger seenCount;
//@property (nonatomic, readonly) unsigned int oldSeenCount;
@property (nonatomic, assign)   BOOL         didSpotNewEnemies;

- (instancetype) initWithUnits:( NSMutableArray * )units;

- (void) clearSeen;

- (void) setSeen:(Unit *)unit;

- (BOOL) seesUnit:(Unit *) unit;

- (Unit *) getSeenUnit:(unsigned int)index;

//- (Unit *) getPreviouslySeenUnit:(unsigned int)index;
//
//- (BOOL) wasUnitPreviouslySeen:(Unit *)unit;

@end
