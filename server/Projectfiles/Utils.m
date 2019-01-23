
#import "Utils.h"

@implementation Utils

+ (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button {
    return [Utils createText:text withYOffset:-6 forButton:button withFont:@"ButtonFont.fnt" includeDisabled:NO];
}


+ (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button includeDisabled:(BOOL)includeDisabled {
    return [Utils createText:text withYOffset:-6 forButton:button withFont:@"ButtonFont.fnt" includeDisabled:includeDisabled];
}


+ (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button withFont:(NSString *)fontName {
    return [Utils createText:text withYOffset:-6 forButton:button withFont:fontName includeDisabled:NO];
}


+ (void) createText:(NSString *)text withYOffset:(int)offset forButton:(CCMenuItemSprite *)button withFont:(NSString *)fontName includeDisabled:(BOOL)includeDisabled {
    CCLabelBMFont * label1 = [CCLabelBMFont labelWithString:text fntFile:fontName];
    CCLabelBMFont * label2 = [CCLabelBMFont labelWithString:text fntFile:fontName];

    int offsetY = offset;
    int selectedOffsetY = offset - 2;

    CGPoint pos1 = ccp( button.normalImage.boundingBox.size.width / 2, button.normalImage.boundingBox.size.height / 2 + offsetY );
    CGPoint pos2 = ccp( button.selectedImage.boundingBox.size.width / 2, button.selectedImage.boundingBox.size.height / 2 + selectedOffsetY );

    label1.position = pos1;
    label2.position = pos2;

    [button.normalImage addChild:label1];
    [button.selectedImage addChild:label2];

    // set up the disabled image too if desired
    if ( includeDisabled ) {
        CCLabelBMFont * label3 = [CCLabelBMFont labelWithString:text fntFile:fontName];
        CGPoint pos3 = ccp( button.disabledImage.boundingBox.size.width / 2, button.disabledImage.boundingBox.size.height / 2 + selectedOffsetY );
        label3.position = pos3;
        [button.disabledImage addChild:label3];
    }
}


+ (void) createImage:(NSString *)frameName forButton:(CCMenuItemSprite *)button {
    [Utils createImage:frameName withYOffset:-3 forButton:button];
}


+ (void) createImage:(NSString *)frameName withYOffset:(int)offset forButton:(CCMenuItemSprite *)button {
    // get the new sprite frames
    //CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    CCSprite * image1 = [CCSprite spriteWithSpriteFrameName:frameName];
    CCSprite * image2 = [CCSprite spriteWithSpriteFrameName:frameName];

    int offsetY = offset;
    int selectedOffsetY = offset - 2;

    CGPoint pos1 = ccp( button.normalImage.boundingBox.size.width / 2, button.normalImage.boundingBox.size.height / 2 + offsetY );
    CGPoint pos2 = ccp( button.selectedImage.boundingBox.size.width / 2, button.selectedImage.boundingBox.size.height / 2 + selectedOffsetY );

    image1.position = pos1;
    image2.position = pos2;

    [button.normalImage removeAllChildren];
    [button.selectedImage removeAllChildren];

    // add to the buttons
    [button.normalImage addChild:image1];
    [button.selectedImage addChild:image2];
}


+ (void) showString:(NSString *)text onLabel:(CCLabelBMFont *)label withMaxLength:(int)maxLength {
    // split into words
    NSArray * words = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * line = @"";
    NSMutableArray * lines = [NSMutableArray new];

    // add words to the line until the length overflows
    for ( NSString * word in words ) {
        NSString * tmp = [line stringByAppendingString:word];
        [label setString:tmp];

        // too long?
        int length = label.boundingBox.size.width;
        if ( length > maxLength ) {
            // start a new line
            [lines addObject:line];
            line = [word stringByAppendingString:@" "];
        }
        else {
            // not too long yet
            line = [tmp stringByAppendingString:@" "];
        }
    }

    // add in the last half line too
    [lines addObject:line];
    
    // join the lines and use as the label
    [label setString:[lines componentsJoinedByString:@"\n"]];
}


@end
