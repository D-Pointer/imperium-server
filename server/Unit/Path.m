
#import <UIKit/UIKit.h>

#import "Path.h"
#import "Globals.h"
#import "Map.h"

@interface Path ()

@property (nonatomic, readwrite, assign) CGPoint finalFacingTarget;

@end


@implementation Path

- (id)init {
    self = [super init];
    if (self) {
        self.positions = [NSMutableArray new];
    }

    return self;
}


- (NSUInteger) count {
    return self.positions.count;
}


- (CGFloat) length {
    CGFloat total = 0;

    if ( self.positions.count < 2 ) {
        return total;
    }

    for ( int index = 0; index < self.positions.count - 1; ++index ) {
        CGPoint pos1 = [self.positions[ index ] CGPointValue];
        CGPoint pos2 = [self.positions[ index + 1 ] CGPointValue];

        total += ccpDistance( pos1, pos2 );
    }

    return total;
}


- (CGPoint) firstPosition {
    return [[self.positions firstObject] CGPointValue];
}


- (CGPoint) secondToLastPosition {
    NSValue * secondToLast = self.positions[ self.positions.count - 2];
    return [secondToLast CGPointValue];
}


- (CGPoint) lastPosition {
    return [[self.positions lastObject] CGPointValue];
}


- (void) addPosition:(CGPoint)pos {
    [self.positions addObject:[NSValue valueWithCGPoint:pos]];
}



- (void) removeFirstPosition {
    if ( self.positions.count > 0 ) {
        [self.positions removeObjectAtIndex:0];
    }
}


- (void) updateFinalFacing {
    self.finalFacingTarget = ccpAdd( [self lastPosition], ccpNormalize( ccpSub( [self lastPosition], [self secondToLastPosition]) ) );
}


- (void) debugPath {
    for ( NSValue * value in self.positions ) {
        CGPoint position = [value CGPointValue];

        CCSprite * sprite = [CCSprite spriteWithSpriteFrameName:@"CannonBullet.png"];
        sprite.position = position;
        [[Globals sharedInstance].map addChild:sprite z:kBulletZ];
    }
}


- (NSString *) save {
    NSMutableString * data = [NSMutableString new];

    // first the number of positions in the path
    [data appendFormat:@"%lu ", (unsigned long)self.positions.count];

    // then each position
    for ( NSValue * value in self.positions ) {
        CGPoint pos = [value CGPointValue];
        [data appendFormat:@"%.1f %.1f ", pos.x, pos.y];
    }

    return data;
}


+ (Path *) pathFromData:(NSArray *)parts startIndex:(int)startIndex {
    // a new path
    Path * path = [Path new];

    // first the number of positions
    int size = [parts[ startIndex ] intValue];

    for ( int index = 0; index < size; ++index ) {
        // the +1 and +2 are to offset for the count which is always first
        [path addPosition:CGPointMake( [parts[ startIndex + index * 2 + 1] floatValue], [parts[ startIndex + index * 2 + 2] floatValue] )];
    }

    // update the final facing
    [path updateFinalFacing];
    
    return path;
}


@end
