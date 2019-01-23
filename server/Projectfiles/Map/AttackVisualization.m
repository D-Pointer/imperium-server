#import "AttackVisualization.h"
#import "Unit.h"
#import "Globals.h"
#import "MapLayer.h"
#import "GameLayer.h"
#import "Audio.h"
#import "AttackResult.h"

@interface AttackVisualization ()

@property (nonatomic, weak) Unit *attacker;
@property (nonatomic, strong) CCArray *casualties;
@property (nonatomic, strong) CCParticleSystem *fireEmitter;
@property (nonatomic, strong) CCParticleSystem *explosionEmitter;
@property (nonatomic, assign) BOOL createExplosion;
@property (nonatomic, assign) BOOL resultCreated;
@property (nonatomic, assign) CGPoint hitPosition;

@end


@implementation AttackVisualization

- (id) initWithAttacker:(Unit *)attacker casualties:(CCArray *)casualties hitPosition:(CGPoint)hitPosition {
    self = [super init];
    if (self) {
        self.attacker = attacker;
        self.casualties = casualties;
        self.hitPosition = hitPosition;

        // no emitters yet
        self.fireEmitter = nil;
        self.explosionEmitter = nil;
        self.createExplosion = NO;
        self.resultCreated = NO;
    }

    return self;
}


- (id) initWithAttacker:(Unit *)attacker smokePosition:(CGPoint)smokePosition {
    self = [super init];
    if (self) {
        self.attacker = attacker;
        self.casualties = nil;
        self.hitPosition = smokePosition;

        // no emitters yet
        self.fireEmitter = nil;
        self.explosionEmitter = nil;
        self.createExplosion = NO;
        self.resultCreated = NO;
    }

    return self;
}


- (void) dealloc {
    self.attacker = nil;
    self.fireEmitter = nil;
    self.explosionEmitter = nil;
}


- (void) execute {
    // the angle from the attacker to the target
    float angle = CC_RADIANS_TO_DEGREES( ccpToAngle( ccpSub( self.hitPosition, self.attacker.position ) ) );

    self.fireEmitter = nil;

    CCLOG( @"%.1f, %.1f -> %.1f, %.1f", self.attacker.position.x, self.attacker.position.y, self.hitPosition.x, self.hitPosition.y );

    // create the fire emitter only if the attacker is visible
    switch (self.attacker.weapon.type) {
        case kRifle:
        case kRifleMk2:
        case kSniperRifle:
            if (self.attacker.visible) {
                self.fireEmitter = [[CCParticleSystemQuad alloc] initWithFile:@"RifleFire.plist"];
            }
            [self createBullets];
            break;

        case kMachineGun:
        case kSubmachineGun:
            if (self.attacker.visible) {
                self.fireEmitter = [[CCParticleSystemQuad alloc] initWithFile:@"MachineGun.plist"];
            }
            [self createBullets];
            break;

        case kLightCannon:
        case kHeavyCannon:
        case kHowitzer:
            if (self.attacker.visible) {
                self.fireEmitter = [[CCParticleSystemQuad alloc] initWithFile:[NSString stringWithFormat:@"ArtilleryFire%d.plist", self.attacker.weaponCount]];
            }
            [self createBullets];

            // artillery fire also has an explosion
            self.createExplosion = YES;
            break;

        case kMortar:
            // no firing explosion for mortars
            [self createBullets];

            // mortar fire also has an explosion
            self.createExplosion = YES;
            break;

        case kFlamethrower:
            // flamethrowers are always visible...
            self.fireEmitter = [[CCParticleSystemQuad alloc] initWithFile:@"Flamethrower.plist"];

            // flamethrower effects are delivered immediately
            [self showResults];
            break;
    }

    // we may not have a fire emitter
    if (self.fireEmitter) {
        self.fireEmitter.position = self.attacker.position;
        self.fireEmitter.autoRemoveOnFinish = YES;

        // rotation of the entire effect
        self.fireEmitter.rotation = self.attacker.rotation;

        // emitting angle, not affected by the rotation above
        self.fireEmitter.angle = self.attacker.rotation + angle;

        [[Globals sharedInstance].mapLayer addChild:self.fireEmitter z:kFireEffectZ];
    }

    // play a sound too
    [[Globals sharedInstance].audio playSound:self.attacker.weapon.firingSound];
}


- (void) createBullets {
    int count;
    bool scaleBullets = NO;
    float scaleBulletsFactor = 1.0f;

    // bullet speed
    float speed = self.attacker.weapon.projectileSpeed;

    // bullet name
    NSString *frameName = self.attacker.weapon.projectileName;

    // how many bullets?
    switch (self.attacker.weapon.type) {
        case kLightCannon:
        case kHeavyCannon:
        case kHowitzer:
            count = self.attacker.weaponCount;
            scaleBullets = YES;
            scaleBulletsFactor = 2.0f;
            break;

        case kMortar:
            count = self.attacker.weaponCount;
            scaleBullets = YES;
            scaleBulletsFactor = 4.0f;
            break;

        case kMachineGun:
            // one per man, but at least 5
            count = MAX( 5, self.attacker.men );
            break;

        case kRifle:
        case kRifleMk2:
        case kSubmachineGun:
        case kSniperRifle:
            // one per 5 men, but at least 1
            count = MAX( 1, self.attacker.men / 5 );
            break;

        default:
            NSAssert( NO, @"no bullets for this weapon" );
            return;
    }

    for (int index = 0; index < count; ++index) {
        // some random start place
        CGPoint startPos = ccpAdd( self.attacker.position, ccp( CCRANDOM_MINUS1_1() * 20, CCRANDOM_MINUS1_1() * 20 ) );
        CGPoint endPos = ccpAdd( self.hitPosition, ccp( CCRANDOM_MINUS1_1() * 10, CCRANDOM_MINUS1_1() * 10 ) );

        // create the bullet sprite
        CCSprite *bullet = [CCSprite spriteWithSpriteFrameName:frameName];
        bullet.position = startPos;
        [[Globals sharedInstance].mapLayer addChild:bullet z:kBulletZ];

        // time it takes the bullet to travel. the speed varies between 90% and 110% of the speed
        float time = ccpDistance( startPos, endPos ) / (speed * 0.90f + (CCRANDOM_0_1() * 0.2f));

        // cannons get scaled up a bit
        if (scaleBullets) {
            // animate the bullet to the end position and then call a selector, in parallel scale the shots up a bit
            [bullet runAction:[CCSpawn actionOne:[CCSequence actions:
                            [CCMoveTo actionWithDuration:time position:endPos],
                            [CCCallFuncN actionWithTarget:self selector:@selector( bulletDone: )],
                                    nil]
                                             two:[CCSequence actions:
                                                     [CCScaleTo actionWithDuration:time * 0.5f scale:scaleBulletsFactor],
                                                     [CCScaleTo actionWithDuration:time * 0.5f scale:1],
                                                             nil]]];
        }
        else {
            // normal rifle bullets, don't scale
            [bullet runAction:[CCSequence actions:
                    [CCMoveTo actionWithDuration:time position:endPos],
                    [CCCallFuncN actionWithTarget:self selector:@selector( bulletDone: )],
                            nil]];
        }
    }
}


- (void) bulletDone:(id)bullet {
    [bullet removeFromParentAndCleanup:YES];

    // CREATE the explosion if needed
    if (self.createExplosion) {
        if (self.attacker.weapon.type == kHeavyCannon) {
            self.explosionEmitter = [[CCParticleSystemQuad alloc] initWithFile:@"HeavyArtilleryExplosion.plist"];
        }
        else if (self.attacker.weapon.type == kLightCannon) {
            self.explosionEmitter = [[CCParticleSystemQuad alloc] initWithFile:@"LightArtilleryExplosion.plist"];
        }
        else {
            self.explosionEmitter = [[CCParticleSystemQuad alloc] initWithFile:@"MortarExplosion.plist"];
        }

        self.explosionEmitter.position = self.hitPosition;
        self.explosionEmitter.autoRemoveOnFinish = YES;
        [[Globals sharedInstance].mapLayer addChild:self.explosionEmitter z:kExplosionEffectZ];

        // play an explosion sound too
        [[Globals sharedInstance].audio playSound:kArtilleryExplosion];

        // only one explosion needed
        self.createExplosion = NO;
    }

    // first landing bullet? for the first we show the result if we have any text (and thus casualties) to show
    if ( ! self.resultCreated ) {
        [self showResults];
    }
}


- (void) showResults {
    // create all results
    if ( self.casualties ) {
        // normal explosion that killed someone
        for (AttackResult *result in self.casualties) {
            [result execute];
        }
    }
    else {
        // smoke
        [[Globals sharedInstance].mapLayer addSmoke:self.hitPosition forPlayer:self.attacker.owner];
    }

    // now we've shown it
    self.resultCreated = YES;
}


@end
