
#import "Definitions.h"

@interface PotentialFieldLayer : NSObject {
    float *     data;
    ccColor4B * colors;
}


@property (nonatomic, assign)            float        max;
//@property (nonatomic, assign)            float        min;
@property (nonatomic, assign, readonly)  unsigned int dataSize;
@property (nonatomic, assign, readonly)  int          width;
@property (nonatomic, assign, readonly)  int          height;

// a weight 0..100 indicating how important the layer is
@property (nonatomic, assign)            float        weight;

// for debugging use
@property (nonatomic, strong)            CCSprite *   sprite;

- (void) update;

- (void) applyTo:(PotentialFieldLayer *)target;

- (float *) getData;

- (void) clear;

- (void) clearToValue:(float)value;

- (float) getValue:(CGPoint)pos;

- (int) fromWorld:(float)value;

- (void) updateDebugSprite;

@end
