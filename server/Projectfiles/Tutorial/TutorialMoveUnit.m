#import "TutorialMoveUnit.h"
#import "Globals.h"
#import "MapLayer.h"

@interface TutorialMoveUnit ()

@property (nonatomic, assign)   int     unitId;
@property (nonatomic, weak)   Unit *     unit;
@property (nonatomic, assign) float      radius;
@property (nonatomic, assign) CGPoint    pos;
@property (nonatomic, strong) CCSprite * sprite;
@property (nonatomic, assign) BOOL       enemySeen;

@end


@implementation TutorialMoveUnit

- (id) initWithUnitId:(int)unitId toPos:(CGPoint)pos radius:(float)radius {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.unitId = unitId;
        self.radius = radius;
        self.pos = pos;
        self.enemySeen = NO;
    }

    return self;
}


- (id) initWithUnitId:(int)unitId toPos:(CGPoint)pos radius:(float)radius orEnemySeen:(BOOL)seen {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.unitId = unitId;
        self.radius = radius;
        self.pos = pos;
        self.enemySeen = seen;
    }

    return self;

}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    self.sprite = [CCSprite spriteWithSpriteFrameName:@"Tutorial/MovementHighlight.png"];
    self.sprite.position = self.pos;
    [[Globals sharedInstance].mapLayer addChild:self.sprite z:kTutorialZ];

    // scale up and down
    [self.sprite runAction:[CCRepeatForever actionWithAction:
                            [CCSequence actions:
                             [CCScaleTo actionWithDuration:0.5 scale:0.95],
                             [CCScaleTo actionWithDuration:0.5 scale:1.05],
                             nil]]];

    // find the unit
    for ( Unit * unit in [Globals sharedInstance].units ) {
        if ( unit.unitId == self.unitId ) {
            self.unit = unit;
        }
    }

    NSAssert( self.unit, @"unit not found!" );
}


- (void) cleanup {
    // stop the animation
    [self.sprite stopAllActions];

    // get rid of the label
    [self.sprite runAction:[CCSequence actions:
                            [CCFadeOut actionWithDuration:0.2f],
                            [CCCallFunc actionWithTarget:self selector:@selector(cleanupDone)],
                            nil]];
}


- (void) cleanupDone {
    [self.sprite removeFromParentAndCleanup:YES];
    self.sprite = nil;
}


- (BOOL) canProceed {
    // distance to the position from the unit
    float distance = ccpDistance( self.unit.position, self.pos );

    // close enough?
    if ( distance < self.radius  ) {
        // yes, we're done
        return YES;
    }

    // stop at seen units
    if ( self.enemySeen ) {
        for ( Unit * unit in [Globals sharedInstance].unitsPlayer2 ) {
            if ( unit.visible ) {
                return YES;
            }
        }
    }

    // not close enough or no unit seen
    return NO;
}

@end
