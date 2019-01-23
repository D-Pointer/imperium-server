
#import "Layer.h"

#import "BonjourServer.h"

@interface Wait : Layer <BonjourServerDelegate>

@property (nonatomic, strong) CCMenuItemImage * backButton;

@end
