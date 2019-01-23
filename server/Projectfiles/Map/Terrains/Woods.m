
#import "Woods.h"

@implementation Woods

- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing {
    self = [super initWithPolygon:vertices smoothing:smoothing];
    if (self) {
        // use custom z order
        self.mapLayerZ = kWoodsZ;
    }

    return self;
}


@end
