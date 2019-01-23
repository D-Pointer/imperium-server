
#import "Smoke.h"

@implementation Smoke

- (BOOL) update:(CGPoint)drift {
    self.position = ccpAdd( self.position, drift );

    if ( arc4random_uniform( 100 ) < 50 ) {
        self.opacity--;
        //self.scale *= 0.99f;
    }

    return self.opacity < 50;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"[Smoke owner:%d, %.0f,%.0f, opacity:%d]", self.creator, self.position.x, self.position.y, self.opacity];
}

@end
