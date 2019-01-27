
#import "Player.h"
#import "Globals.h"

@interface Player ()

@property (nonatomic, readwrite, assign) PlayerId   playerId;

@end


@implementation Player

- (id) initWithId:(PlayerId)playerId {
    self = [super init];
    if (self) {
        self.playerId = playerId;

        // default name
        self.name = @"Unknown";
    }
    
    return self;
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[Player %d %@]", self.playerId, self.name];
}


@end
