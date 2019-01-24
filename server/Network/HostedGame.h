
#import "Definitions.h"

@interface HostedGame : NSObject

@property (nonatomic, assign) unsigned int       gameId;
@property (nonatomic, assign) unsigned short     scenarioId;
@property (nonatomic, strong) NSString *         opponentName;
@property (nonatomic, assign) unsigned short     udpPort;
@property (nonatomic, assign) PlayerId           localPlayerId;
@property (nonatomic, assign) MultiplayerEndType endType;

- (instancetype) initWithId:(unsigned int)gameId
                 scenarioId:(unsigned short)scenarioId
               opponentName:(NSString *)playerName;

@end
