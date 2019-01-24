
#import "cocos2d.h"

@class Unit;

@interface Engine : NSObject

// attack visualizations
@property (nonatomic, strong)   NSMutableArray * messages;
@property (nonatomic, readonly) BOOL      isPaused;

- (void) start;
- (void) stop;

/**
 *
 **/
- (Unit *) findTarget:(Unit *)attacker onlyInsideArc:(BOOL)onlyInsideArc;

@end
