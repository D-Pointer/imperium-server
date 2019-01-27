#import "Definitions.h"
#import "UdpPacket.h"

@class Unit;


@protocol UdpNetworkHandlerDelegate <NSObject>

@optional

- (void) serverPongReceived:(double)milliseconds;
- (void) playerPongReceived:(double)milliseconds;

@end


@interface UdpNetworkHandler : NSObject

- (instancetype) initWithServer:(NSString *)server port:(unsigned short)port delegate:(id<UdpNetworkHandlerDelegate>)delegate;

- (void) disconnect;

- (void) sendPingToServer;
- (void) sendPingToPlayer;

- (void) sendMissions:( NSMutableArray *)units;

- (void) sendSetMission:(MissionType)mission forUnit:(Unit *)unit;

- (void) sendUnitStats:( NSMutableArray *)units;

- (void) sendSmoke:( NSMutableArray *)smoke;

- (void) sendFireWithAttacker:(Unit *)attacker casualties:( NSMutableArray *)casualties hitPosition:(CGPoint)hitPosition;

- (void) sendMeleeWithAttacker:(Unit *)attacker
                        target:(Unit *)target
                       message:(AttackMessageType)message
                    casualties:(int)casualties
            targetMoraleChange:(float)targetMoraleChange;


@end
