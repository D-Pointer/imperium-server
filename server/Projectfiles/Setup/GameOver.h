
#import "Definitions.h"
#import "Layer.h"

@interface GameOver : Layer

@property (nonatomic, strong) CCLabelBMFont * title;
@property (nonatomic, strong) CCLabelBMFont * player1Name;
@property (nonatomic, strong) CCLabelBMFont * player2Name;
@property (nonatomic, strong) CCLabelBMFont * totalMen1;
@property (nonatomic, strong) CCLabelBMFont * totalMen2;
@property (nonatomic, strong) CCLabelBMFont * lostMen1;
@property (nonatomic, strong) CCLabelBMFont * lostMen2;
@property (nonatomic, strong) CCLabelBMFont * objectives1;
@property (nonatomic, strong) CCLabelBMFont * objectives2;
@property (nonatomic, strong) CCLabelBMFont * reason;
@property (nonatomic, strong) CCNode *          paper;
@property (nonatomic, strong) CCMenuItemImage * backButton;

+ (id) singlePlayerNode;
+ (id) multiPlayerNode;

@end
