
#import "EnemyGroup.h"

@implementation EnemyGroup

- (id) initWithEnemies:(CCArray *)enemies {
    self = [super init];
    if (self) {
        self.enemies = enemies;
    }

    return self;
}


- (id) initWithEnemy:(Unit *)enemy {
    self = [super init];
    if (self) {
        self.enemies = [CCArray new];
        [self.enemies addObject:enemy];
    }

    return self;
}


- (void) dealloc {
    self.enemies = nil;
}


- (BOOL) is:(Unit *)unit closerThan:(float)distance {
    for ( Unit * tmp in self.enemies ) {
        if ( ccpDistance( tmp.position, unit.position ) < distance ) {
            // close enough
            return YES;
        }
    }

    // not close enough
    return NO;
}

@end
