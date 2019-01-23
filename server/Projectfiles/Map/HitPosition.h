
#import <Foundation/Foundation.h>

#import "PolygonNode.h"

@interface HitPosition : NSObject

@property (nonatomic, weak)   PolygonNode * polygon;
@property (nonatomic, assign) float         position;

- (id) initWithPolygon:(PolygonNode *)polygon atPosition:(float)position;

@end

NSInteger compareHitPositions (id hp1, id hp2, void * context);
