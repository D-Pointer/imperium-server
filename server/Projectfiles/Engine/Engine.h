
#import "cocos2d.h"

@class Unit;

@interface Engine : NSObject

// attack visualizations
@property (nonatomic, strong)   CCArray * messages;
@property (nonatomic, readonly) BOOL      isPaused;

- (void) start;
- (void) pause;
- (void) resume;
- (void) stop;

/**
 *
 **/
- (Unit *) findTarget:(Unit *)attacker onlyInsideArc:(BOOL)onlyInsideArc;

@end
