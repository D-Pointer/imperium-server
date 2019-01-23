
#import "UnitIconGenerator.h"

@interface UnitIconGenerator ()

@property (nonatomic, strong) NSMutableDictionary * cache;
@property (nonatomic, strong) NSArray *             infantry;
@property (nonatomic, strong) NSArray *             cavalry;
@property (nonatomic, strong) NSArray *             artillery;
@property (nonatomic, strong) CCSprite *            lightGun;
@property (nonatomic, strong) CCSprite *            heavyGun;

@end

@implementation UnitIconGenerator

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [NSMutableDictionary new];

        // load all infantry
        self.infantry = @[ [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/1_0.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/1_1.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/1_2.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/1_3.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/1_4.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/1_5.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/2_0.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/2_1.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/2_2.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/2_3.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/2_4.png"],
                           [CCSprite spriteWithSpriteFrameName:@"Units/Infantry/2_5.png"] ];

        // load all cavalry
        self.cavalry = @[ [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/1_0.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/1_1.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/1_2.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/1_3.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/1_4.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/1_5.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/2_0.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/2_1.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/2_2.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/2_3.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/2_4.png"],
                          [CCSprite spriteWithSpriteFrameName:@"Units/Cavalry/2_5.png"] ];

        // artillery guns
        self.lightGun = [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/light.png"];
        self.lightGun.anchorPoint = ccp( 0, 0 );
        self.heavyGun = [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/heavy.png"];
        self.heavyGun.anchorPoint = ccp( 0, 0 );

        // artillery men
        self.artillery = @[ [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/1_0.png"],
                            [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/1_1.png"],
                            [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/1_2.png"],
                            [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/2_0.png"],
                            [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/2_1.png"],
                            [CCSprite spriteWithSpriteFrameName:@"Units/Artillery/2_2.png"] ];

        for ( CCSprite * sprite in self.infantry ) {
            sprite.anchorPoint = ccp( 0, 0 );
        }
        for ( CCSprite * sprite in self.cavalry ) {
            sprite.anchorPoint = ccp( 0, 0 );
        }
        for ( CCSprite * sprite in self.artillery ) {
            sprite.anchorPoint = ccp( 0, 0 );
        }
    }

    return self;
}


+ (UnitIconGenerator *) sharedInstance {
    static UnitIconGenerator * globalsInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        globalsInstance = [[UnitIconGenerator alloc] init];
    });

	// return the instance
	return globalsInstance;
}


- (CCSpriteFrame *) spriteFrameFor:(Unit *)unit {
    // a mission that should show the unit as disorganized
    Mission * mission = unit.mission;
    int disorganized = 0;
    if ( mission && ( mission.type == kRetreatMission || mission.type == kDisorganizedMission || mission.type == kRoutMission  || mission.type == kChangeModeMission ) ) {
        disorganized = 1;
    }

    NSString * frameName = [NSString stringWithFormat:@"%d-%d-%d-%d-%d-%d",
                            unit.type,
                            unit.owner,
                            unit.mode,
                            unit.men,
                            unit.weaponCount,
                            disorganized];

    // already present in our cache?
    CCSpriteFrame * frame = self.cache[frameName];
    if ( frame ) {
        return frame;
    }

    // artillery?
    if ( unit.type == kArtillery ) {
        return [self spriteFrameForArtillery:unit withName:frameName];
    }

    // a retreat or disorganized mission?
    if ( mission && disorganized == 1 ) {
        return [self spriteFrameForDisorganized:unit withName:frameName];
    }

    // how many men wide should the formation be?
    int menWide;
    if ( unit.mode == kColumn ) {
        // fewer units means narrower columns
        if ( unit.men >= 30 ) {
            menWide = 5;
        }
        else if ( unit.men >= 20 ) {
            menWide = 4;
        }
        else {
            menWide = 3;
        }
    }

    else if ( unit.men >= 75 ) {
        menWide = 25;
    }
    else if ( unit.men >= 60 ) {
        menWide = 20;
    }
    else if ( unit.men >= 45 ) {
        menWide = 15;
    }
    else if ( unit.men >= 36 ) {
        menWide = 12;
    }
    else if ( unit.men >= 30 ) {
        menWide = 10;
    }
    else if ( unit.men >= 24 ) {
        menWide = 8;
    }
    else if ( unit.men >= 18 ) {
        menWide = 7;
    }
    else if ( unit.men >= 10 ) {
        menWide = 6;
    }
    else {
        menWide = unit.men;
    }

    // the number of lines. add an extra not filled line if needed
    int lines = unit.men / menWide;
    if ( lines * menWide < unit.men ) {
        lines++;
    }

    // size of one guy in pixels, including spacing between them
    int manWidth, manHeight;

    int textureWidth, textureHeight;
    if ( unit.type == kInfantry || unit.type == kInfantryHeadquarter ) {
        // men are 2 x 3 px
        manWidth = 3;
        manHeight = 4;
    }
    else {
        // horses are 2 x 5 px
        manWidth = 3;
        manHeight = 6;
    }

    textureWidth = menWide * manWidth;
    textureHeight = lines * manHeight;

    // save the width as the formation's width for other visualizations
    unit.formationWidth = textureWidth;

    CCRenderTexture * renderTexture = [CCRenderTexture renderTextureWithWidth:textureWidth height:textureHeight];
    [renderTexture begin];

    CCSprite * sprite;
    int row = 0, column = 0;
    for ( int index = 0; index < unit.men; ++index ) {
        // get a random sprite for the correct player
        if ( unit.type == kInfantry || unit.type == kInfantryHeadquarter ) {
            sprite = self.infantry[ arc4random_uniform( 6 ) + unit.owner * 6];
        }
        else {
            sprite = self.cavalry[ arc4random_uniform( 6 ) + unit.owner * 6];
        }

        // set position and render it by visiting
        sprite.position = ccp( column * manWidth, row * manHeight );
        [sprite visit];

        if ( ++column == menWide ) {
            column = 0;
            row++;
        }
    }

    // use the render texture's result frame
    [renderTexture end];
    frame = [CCSpriteFrame frameWithTexture:renderTexture.sprite.texture rect:renderTexture.sprite.textureRect];

    // save in our cache
    self.cache[frameName] = frame;
    return frame;
}


- (CCSpriteFrame *) spriteFrameForDisorganized:(Unit *)unit withName:(NSString *)frameName {
    int radius;

    //CCLOG( @"creating new frame %@ for %@", frameName, unit );

    // how big should the rect be where the men are placed?
    if ( unit.men >= 70 ) {
        radius = 30;
    }
    else if ( unit.men >= 60 ) {
        radius = 26;
    }
    else if ( unit.men >= 50 ) {
        radius = 22;
    }
    else if ( unit.men >= 40 ) {
        radius = 18;
    }
    else if ( unit.men >= 30 ) {
        radius = 16;
    }
    else if ( unit.men >= 20 ) {
        radius = 12;
    }
    else if ( unit.men >= 10 ) {
        radius = 8;
    }
    else {
        radius = 5;
    }

    int margin = 4;
    CCRenderTexture * renderTexture = [CCRenderTexture renderTextureWithWidth:radius * 2 + margin * 2
                                                                       height:radius * 2 + margin * 2];
    [renderTexture begin];

    CCSprite * sprite;
    for ( int index = 0; index < unit.men; ++index ) {
        // get a random sprite for the correct player
        if ( unit.type == kInfantry || unit.type == kInfantryHeadquarter ) {
            sprite = self.infantry[ arc4random_uniform( 6 ) + unit.owner * 6];
        }
        else {
            sprite = self.cavalry[ arc4random_uniform( 6 ) + unit.owner * 6];
        }

        // set position and render it by visiting
        sprite.position = ccp( margin + CCRANDOM_0_1() * radius * 2, margin + CCRANDOM_0_1() * radius * 2 );
        [sprite visit];
    }

    // use the render texture's result frame
    [renderTexture end];
    CCSpriteFrame * frame = [CCSpriteFrame frameWithTexture:renderTexture.sprite.texture rect:renderTexture.sprite.textureRect];

    // save in our cache
    self.cache[frameName] = frame;
    return frame;
}


- (CCSpriteFrame *) spriteFrameForArtillery:(Unit *)unit withName:(NSString *)frameName {
    CCRenderTexture * renderTexture;
    CCSprite * man;

    // x/y positions for men around guns in formation
    static int formationPositions[] = {
        1,6, 10,6, 2,9, 11,9, 1,12, 10,12,
        6,11, 6,14, 4,17, 8,17,
        11,15, 1,15 };

    // positions for column mode, around the guns
    static int columnPositions[] = {
        1,3, 11,3, 1,6, 11,6, 1,9, 11,9, 1,12, 11,12, 6,11, 6,14, 1,0, 11,0 };

    int manIndex = 0;
    int gunIndex = 0;
    int textureWidth, textureHeight;

    // gun sprite based on the weapon. heavy and howitzer is the same icon
    CCSprite * gun = unit.weapon.type == kLightCannon ? self.lightGun : self.heavyGun;

    if ( unit.mode == kColumn ) {
        // all guns in a queue
        textureWidth = 14;
        textureHeight = 16 * unit.weaponCount;

        renderTexture = [CCRenderTexture renderTextureWithWidth:textureWidth height:textureHeight];
        [renderTexture begin];

        // add in all the guns
        for ( int index = 0; index < unit.weaponCount; ++index ) {
            gun.position = ccp( 4, index * 16 );
            [gun visit];
        }

        // add in men. we add in men one per gun
        for ( int index = 0; index < unit.men; ++index ) {
            // a random artillery man
            man = self.artillery[ arc4random_uniform( 3 ) + unit.owner * 3 ];

            //
            man.position = ccp( columnPositions[manIndex * 2], gunIndex * 16 + columnPositions[manIndex * 2 + 1] );
            [man visit];

            gunIndex++;

            // next man position?
            if ( index > 0 && (index % unit.weaponCount) == 0 ) {
                manIndex++;
                gunIndex = 0;
            }
        }
    }

    else {
        // all guns on a line
        textureWidth = ( 10 + 5 ) * unit.weaponCount;
        textureHeight = 20;

        renderTexture = [CCRenderTexture renderTextureWithWidth:textureWidth height:textureHeight];
        [renderTexture begin];

        // add in all the guns
        for ( int index = 0; index < unit.weaponCount; ++index ) {
            gun.position = ccp( 4 + index * 15, 0 );
            [gun visit];
        }

        // add in men. we add in men one per gun
        for ( int index = 0; index < unit.men; ++index ) {
            // a random artillery man
            man = self.artillery[ arc4random_uniform( 3 ) + unit.owner * 3 ];

            //
            man.position = ccp( gunIndex * 15 + formationPositions[manIndex * 2], formationPositions[manIndex * 2 + 1] );
            [man visit];

            gunIndex++;
            
            // next man position?
            if ( index > 0 && (index % unit.weaponCount) == 0 ) {
                manIndex++;
                gunIndex = 0;
            }
        }
    }

    // save the width as the formation's width for other visualizations
    unit.formationWidth = textureWidth;

    // use the render texture's result frame
    [renderTexture end];
    CCSpriteFrame * frame = [CCSpriteFrame frameWithTexture:renderTexture.sprite.texture rect:renderTexture.sprite.textureRect];

    // save in our cache
    self.cache[frameName] = frame;
    return frame;
}


@end
