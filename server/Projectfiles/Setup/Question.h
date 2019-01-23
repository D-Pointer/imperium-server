
#import "cocos2d.h"
#import "Definitions.h"
#import "QuestionDelegate.h"

@interface Question : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCMenu *          buttonMenu;
@property (nonatomic, strong) CCMenuItemImage * okButton;
@property (nonatomic, strong) CCMenuItemImage * cancelButton;
@property (nonatomic, strong) CCLabelBMFont *   titleLabel;
@property (nonatomic, strong) CCLabelBMFont *   questionLabel;

+ (Question *) nodeWithQuestion:(NSString *)question titleText:(NSString *)title okText:(NSString *)okText cancelText:(NSString *)cancelText delegate:(id<QuestionDelegate>)delegate;

@end
