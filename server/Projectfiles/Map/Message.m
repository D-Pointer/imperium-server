
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
    
    // first create the name
    self.label = [CCLabelBMFont labelWithString:message_str fntFile:self.unit.owner == kPlayer1 ? @"CombatMessageFont1.fnt" : @"CombatMessageFont2.fnt" ];
    self.label.anchorPoint = ccp( 0.5, 0.5 );
    self.label.position = self.unit.position;
    [[Globals sharedInstance].mapLayer addChild:self.label z:kMessageZ];

    // first under the label a background
    self.background = [CCSprite spriteWithSpriteFrameName:@"TextBackground.png"];
    self.background.position = self.unit.position;
    [[Globals sharedInstance].mapLayer addChild:self.background z:kMessageBackgroundZ];
    
    // scale the background suitably
    float scale_x = ( self.label.boundingBox.size.width + 10 ) / self.background.boundingBox.size.width;
    float scale_y = ( self.label.boundingBox.size.height + 6 ) / self.background.boundingBox.size.height;
    self.background.scaleX = scale_x;
    self.background.scaleY = scale_y;

    // show the label some seconds, fade out and then remove
    [self.label runAction:[CCSequence actions:
                           [CCDelayTime actionWithDuration:5.0f], 
                           [CCFadeOut actionWithDuration:0.5f], 
                           [CCCallFuncN actionWithTarget:self selector:@selector(messageDone:)],
                           nil] ];
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
