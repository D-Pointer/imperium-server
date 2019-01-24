
#import "MapBase.h"
#import "Player.h"

@interface UnitStrengthMap : MapBase {
}

@property (readwrite, nonatomic) PlayerId playerId;

- (id) initForPlayer:(PlayerId)player withTitle:(NSString *)title_;

- (void) update;

@end
