
#import "Layer.h"
#import "Scenario.h"
#import "TcpNetworkHandler.h"

@interface SelectArmy : Layer <OnlineGamesDelegate>

@property (nonatomic, strong) CCMenuItemImage * editButton;
@property (nonatomic, strong) CCMenuItemImage * playButton;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * army1Button;
@property (nonatomic, strong) CCMenuItemImage * army2Button;
@property (nonatomic, strong) CCMenuItemImage * army3Button;
@property (nonatomic, strong) CCNode *          unitListPaper;
@property (nonatomic, strong) CCNode *          helpPaper;
@property (nonatomic, strong) CCNode *          armiesPaper;
@property (nonatomic, strong) CCLabelBMFont *   armyNameLabel;
@property (nonatomic, strong) CCLabelBMFont *   unitListLabel;
@property (nonatomic, strong) CCLabelBMFont *   noUnitsLabel;

@end
