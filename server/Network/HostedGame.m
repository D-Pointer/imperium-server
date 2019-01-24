
#import "HostedGame.h"

@implementation HostedGame

- (instancetype) initWithId:(unsigned int)gameId scenarioId:(unsigned short)scenarioId opponentName:(NSString *)playerName {
    self = [super init];
    if (self) {
        self.gameId     = gameId;
        self.scenarioId = scenarioId;
        self.opponentName = playerName;

        // these are set later
        self.udpPort    = 0;
        self.localPlayerId = kPlayer1;
    }
    return self;
}


- (NSString *)description {
    if ( self.opponentName ) {
        return [NSString stringWithFormat:@"[HostedGame %d, scenario: %d, opponent: %@]", self.gameId, self.scenarioId, self.opponentName];
    }

    return [NSString stringWithFormat:@"[HostedGame %d, scenario: %d, no opponent]", self.gameId, self.scenarioId];
}

@end
