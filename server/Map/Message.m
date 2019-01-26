
#import "Message.h"
#import "Unit.h"
#import "Globals.h"
#import "MapLayer.h"

@interface Message ()

@property (nonatomic, strong) CCLabelBMFont *        label;
@property (nonatomic, strong) CCSprite *             background;

@end


@implementation Message

// used for serialization
- (id) init {
    self = [super init];
    if (self) {
        self.unit = nil;
        self.message = kNoStackingAllowed;
    }
    
    return self;
}


- (id) initWithMessage:(MessageType)message forUnit:(Unit *)unit {
    self = [super init];
    if (self) {
        self.unit    = unit;
        self.message = message;
        
        CCLOG( @"unit: %@, message: %d", self.unit, self.message );
    }
    
    return self;    
}


- (void) dealloc {
    self.unit  = nil;
    self.label = nil;
    self.background = nil;
}


- (void) execute {    
    // assemble a message string from the type and bits of data
    NSString * message_str = @"";

    switch ( self.message ) {
        case kNoStackingAllowed:
            message_str = @"Can not stack\nunits, stopping!";
            break;

        case kNewEnemySpotted:
            message_str = @"New enemy spotted!";
            break;

        case kNewEnemySpottedStopping:
            message_str = @"New enemy spotted,\nstopping!";
            break;

        case kNoMissions:
            message_str = @"Can not give missions\nto the unit!";
            break;
   }
     
    CCLOG( @"%@", [message_str stringByReplacingOccurrencesOfString:@"\n" withString:@" "] );
    }

/*
- (void) cleanup {
    if ( self.label ) {
        [self.label stopAllActions];
        [self.label removeFromParentAndCleanup:YES];
        self.label = nil;
    }

    if ( self.background ) {
        [self.background stopAllActions];
        [self.background removeFromParentAndCleanup:YES];
        self.background = nil;
    }
}
*/

- (void) messageDone:(id)sender {
    [sender removeFromParentAndCleanup:YES];
    self.label = nil;

    if ( self.background ) {
        [self.background stopAllActions];
        [self.background removeFromParentAndCleanup:YES];
        self.background = nil;
    }
}

@end
