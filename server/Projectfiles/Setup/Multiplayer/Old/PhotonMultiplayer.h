
#import "Layer.h"

@interface PhotonMultiplayer : Layer

@property (nonatomic, strong) CCMenuItemImage * createGameButton;
@property (nonatomic, strong) CCMenuItemImage * connectButton;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCNode *          messagePaper;
@property (nonatomic, strong) CCNode *          buttonsPaper;

@end
