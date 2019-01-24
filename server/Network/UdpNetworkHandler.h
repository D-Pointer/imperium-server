#import "GCDAsyncUdpSocket.h"
#import "Definitions.h"
#import "UdpPacket.h"

@class Unit;


@protocol UdpNetworkHandlerDelegate <NSObject>

@optional

- (void) serverPongReceived:(double)milliseconds;
- (void) playerPongReceived:(double)milliseconds;

@end


@interface UdpNetworkHandler : NSObject <GCDAsyncUdpSocketDelegate>

- (instancetype) initWithServer:(NSString *)server port:(unsigned short)port delegate:(id<UdpNetworkHandlerDelegate>)delegate;

- (void) disconnect;

- (void) sendPingToServer;
- (void) sendPingToPlayer;

- (void) sendMissions:(CCArray *)units;

- (void) sendSetMission:(MissionType)mission forUnit:(Unit *)unit;

- (void) sendUnitStats:(CCArray *)units;

- (void) sendSmoke:(CCArray *)smoke;

- (void) sendFireWithAttacker:(Unit *)attacker casualties:(CCArray *)casualties hitPosition:(CGPoint)hitPosition;

- (void) sendMeleeWithAttacker:(Unit *)attacker
                        target:(Unit *)target
                       message:(AttackMessageType)message
                    casualties:(int)casualties
            targetMoraleChange:(float)targetMoraleChange;


@end
