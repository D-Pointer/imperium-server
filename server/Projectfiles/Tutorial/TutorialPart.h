
#import <Foundation/Foundation.h>

#import "Tutorial.h"

@interface TutorialPart : NSObject

@property (nonatomic, assign) BOOL blocks;
@property (nonatomic, assign) BOOL claimTouch;

- (void) showPartInTutorial:(Tutorial *)tutorial;

- (BOOL) canProceed;

- (BOOL) canProceed:(CGPoint)clickedPos;

- (void) cleanup;

@end
