
#import "Quote.h"
#import "Utils.h"

@interface Quote ()

@property (nonatomic, strong) CCLabelBMFont * textLabel;
@property (nonatomic, strong) CCLabelBMFont * authorLabel;

@end


@implementation Quote

- (id) init {
    self = [super init];
    if (self) {
        // set up the paper
        CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
        [self setDisplayFrame:[cache spriteFrameByName:@"Tutorial/Paper.png"]];

        // create the labels
        self.textLabel = [CCLabelBMFont labelWithString:@"" fntFile:@"GameFont1.fnt"];
        self.textLabel.position = ccp( 150, 55 );
        [self addChild:self.textLabel];

        self.authorLabel = [CCLabelBMFont labelWithString:@"" fntFile:@"GameFont3.fnt"];
        self.authorLabel.anchorPoint = ccp( 1.0, 0.5 );
        self.authorLabel.position = ccp( 270, 20 );
        [self addChild:self.authorLabel];
    }
    
    return self;
}


- (void) setText:(NSString *)text {
    // nicely wrap the quote
    [Utils showString:text onLabel:self.textLabel withMaxLength:260];
}


- (void) setAuthor:(NSString *)author {
    [self.authorLabel setString:author];
}


@end
