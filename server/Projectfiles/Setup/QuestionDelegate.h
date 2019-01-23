
#import "cocos2d.h"

@protocol QuestionDelegate <NSObject>
@optional

- (void) questionAccepted;
- (void) questionRejected;

@end
