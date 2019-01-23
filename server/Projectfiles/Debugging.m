
#import "cocos2d.h"
#import "Debugging.h"
#import "Globals.h"
#import "MapLayer.h"

@implementation Debugging

+ (void) printTree:(CCNode *)node {
    NSString * result = @"";
    result = [Debugging recurseTree:node withLevel:0 intoResult:@"\n"];
    CCLOG( @"%@", result );
}


+ (NSString *) recurseTree:(CCNode *)node withLevel:(int)level intoResult:(NSString *)result {
    NSString * indent = @"";
    for ( int index = 0; index < level; ++index ) {
        indent = [indent stringByAppendingString:@"  "];
    }

    result = [result stringByAppendingFormat:@"%@%@\n", indent, [node class] ];

    for ( CCNode * child in node.children ) {
        result = [Debugging recurseTree:child withLevel:level + 1 intoResult:result];
    }

    return result;
}


+ (void) showLineFrom:(CGPoint)start to:(CGPoint)end {
    int x0 = (int)start.x;
    int y0 = (int)start.y;
    int x1 = (int)end.x;
    int y1 = (int)end.y;

    int dx = abs( x1-x0 );
    int sx = x0 < x1 ? 1 : -1;
    int dy = abs(y1-y0);
    int sy = y0 < y1 ? 1 : -1;
    int err = (dx > dy ? dx : -dy) / 2;
    int e2;

    while ( x0 != x1 || y0 != y1 ) {
        CCSprite * sprite = [CCSprite spriteWithSpriteFrameName:@"RifleBullet.png"];
        sprite.position = ccp( x0, y0 );
        [[Globals sharedInstance].mapLayer addChild:sprite z:kBulletZ];

        e2 = err;
        if ( e2 >-dx ) {
            err -= dy;
            x0 += sx;
        }
        if ( e2 < dy ) {
            err += dx;
            y0 += sy;
        }
    }
}

@end
