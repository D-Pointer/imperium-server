
#import "Player.h"
#import "Globals.h"

@interface Player ()

@property (nonatomic, readwrite, assign) PlayerId   playerId;
@property (nonatomic, readwrite, assign) PlayerType type;

@end


@implementation Player

- (id) initWithId:(PlayerId)playerId type:(PlayerType)type {
    self = [super init];
    if (self) {
        self.playerId = playerId;
        self.type     = type;

        // default name
        self.name = @"Unknown";
    }
    
    return self;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[Player %d %@]", self.playerId, self.name];
}


@end
