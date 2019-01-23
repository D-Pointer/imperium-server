
#import "PolygonNode.h"

@interface DefaultPolygonNode : PolygonNode

@property (strong, nonatomic) CCTexture2D * texture;
//@property (nonatomic, strong) CCTexture2D * normalMap;

- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing;

- (void) rotateTextureBy:(float)degrees;

- (void) scaleTextureBy:(float)factor;

@end
