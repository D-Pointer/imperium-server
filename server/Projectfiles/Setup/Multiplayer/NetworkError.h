
#import "Layer.h"

@interface NetworkError : Layer

@property (nonatomic, strong) CCLabelBMFont *   errorLabel;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCNode *          errorPaper;

+ (id) nodeWithMessage:(NSString *)message backScene:(CCScene *)backScene;

@end
