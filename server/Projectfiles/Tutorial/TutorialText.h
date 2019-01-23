
#import <Foundation/Foundation.h>

#import "TutorialPart.h"

@interface TutorialText : TutorialPart

- (id) initWithText:(NSString *)text_ atPos:(CGPoint)pos_;

- (id) initBlockingWithText:(NSString *)text_ atPos:(CGPoint)pos_;


@end
