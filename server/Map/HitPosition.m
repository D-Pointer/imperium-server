
#import "HitPosition.h"

NSInteger compareHitPositions (id hp1, id hp2, void * context) {
    HitPosition * h1 = (HitPosition *)hp1;
    HitPosition * h2 = (HitPosition *)hp2;

    if ( h1.position < h2.position ) {
        return NSOrderedAscending ;
    }

    if ( h1.position > h2.position ) {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}


@implementation HitPosition

- (id) initWithPolygon:(PolygonNode *)polygon atPosition:(float)position {
    self = [super init];
    if (self) {
        _polygon = polygon;
        _position = position;
    }

    return self;
}

@end
