
#import "Messages.h"
#import "Globals.h"

@interface Messages ()

@property (nonatomic, strong) CCArray * messages;

@end


@implementation Messages

@synthesize messages;

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [CCArray array];
    }
    
    return self;
}


- (void) addMessage:(NSString *)message ofType:(MessageType)type {
    NSString * font;
    
    switch ( type ) {
        case kCombatMessage:
            font = @"CombatMessageFont1.fnt";
            break;
            
        case kInformationMessage:
            font = @"InfoMessageFont.fnt";
            break;
    }
    
    // create a new label
    CCLabelBMFont * label = [CCLabelBMFont labelWithString:message fntFile:font];

    // anchor at upper right
    label.anchorPoint = ccp( 1.0, 1.0 );

    // any old messages?
    if ( self.messages.count > 0 ) {
        // below the last label
        CCLabelBMFont * last = [self.messages lastObject];
        label.position = ccp( 0, last.position.y - last.boundingBox.size.height );
    }
    else {
        // first label
        label.position = ccp( 0, 0 );
    }
    
    [self addChild:label];
    [self.messages addObject:label];
}


@end
