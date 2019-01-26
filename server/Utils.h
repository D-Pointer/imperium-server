


@interface Utils : NSObject

/**
 * Misc utility functions.
 **/
+ (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button;

+ (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button includeDisabled:(BOOL)includeDisabled;

+ (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button withFont:(NSString *)fontName;

+ (void) createText:(NSString *)text withYOffset:(int)offset forButton:(CCMenuItemSprite *)button withFont:(NSString *)fontName includeDisabled:(BOOL)includeDisabled;

+ (void) createImage:(NSString *)frameName forButton:(CCMenuItemSprite *)button;

+ (void) createImage:(NSString *)frameName withYOffset:(int)offset forButton:(CCMenuItemSprite *)button;

+ (void) showString:(NSString *)text onLabel:(CCLabelBMFont *)label withMaxLength:(int)maxLength;

@end
