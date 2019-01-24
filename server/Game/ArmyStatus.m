
#import "CCBReader.h"

#import "ArmyStatus.h"
#import "Globals.h"
#import "Engine.h"
#import "Organization.h"

@implementation ArmyStatus

@synthesize paper;

+ (id) node {
    return [CCBReader nodeGraphFromFile:@"ArmyStatus.ccb"];
}


- (id) init {
    self = [super init];
    if (self) {
    }
    
    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
}


- (void) didLoadFromCCB {
    CCLOG( @"in" );

    [self createBackground];

    // show info for all own units
    Globals * globals = [Globals sharedInstance];
    PlayerId localPlayer = globals.localPlayer.playerId == kPlayer1 ? kPlayer1 : kPlayer2;
    CCArray * ownUnits = globals.localPlayer.playerId == kPlayer1 ? globals.unitsPlayer1 : globals.unitsPlayer1;

    int y = 600;

    NSMutableSet * added = [NSMutableSet new];

    // first add in all organizations
    for ( Organization * organization in globals.organizations ) {
        if ( organization.owner != localPlayer ) {
            continue;
        }

        for ( Unit * unit in organization.units ) {
            [self showUnit:unit atLevel:y];
            y -= 20;

            [added addObject:unit];
        }
    }

    // now find all units that do not belong to any organization
    for ( Unit * unit in ownUnits ) {
        if ( [added containsObject:unit] ) {
            continue;
        }

        // an independent unit
        [self showUnit:unit atLevel:y];
        y -= 20;
    }

    // we handle touches now, make sure we get *before* all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1 swallowsTouches:YES];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CCLOG( @"in" );

    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        return YES;
    }

    // resume the engine
    [[Globals sharedInstance].engine resume];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // kill ourselves
    [self removeFromParentAndCleanup:YES];

    return YES;
}


- (void) showUnit:(Unit *)unit atLevel:(int)y {
    // different font for destroyed units
    NSString * fontFile = unit.destroyed ? @"GameFont4.fnt" : @"GameFont1.fnt";

    // name
    CCLabelBMFont * name = [CCLabelBMFont labelWithString:unit.name fntFile:fontFile];
    name.anchorPoint = ccp( 0, 0.5 );
    [self.paper addChild:name];

    // hq units have no extra indentation while subordinates have some extra indentation
    int x = unit.headquarter != nil ? 80: 50;
    name.position = ccp( x, y );

    // men
    CCLabelBMFont * men = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d / %d men", unit.men, unit.originalMen] fntFile:fontFile];
    men.anchorPoint = ccp( 0, 0.5 );
    men.position    = ccp( 250, y );
    [self.paper addChild:men];

    // mission
    Mission * mission = unit.mission;
    NSString * missionName;
    if ( mission == nil ) {
        missionName = @"No mission";
    }
    else if ( mission.commandDelay > 0 ) {
        missionName = mission.preparingName;
    }
    else {
        missionName = mission.name;
    }

    CCLabelBMFont * missionLabel = [CCLabelBMFont labelWithString:missionName fntFile:fontFile];
    missionLabel.anchorPoint = ccp( 0, 0.5 );
    missionLabel.position    = ccp( 370, y );
    [self.paper addChild:missionLabel];

    // weapon
    NSString * weaponName;
    if ( unit.weapon.menRequired == 1 ) {
        weaponName = unit.weapon.name;
    }
    else {
        // we have weapons where we need more than one man per weapon
        weaponName = [NSString stringWithFormat:@"%d %@", unit.weaponCount, unit.weapon.name];
    }

    CCLabelBMFont * weaponLabel = [CCLabelBMFont labelWithString:weaponName fntFile:fontFile];
    weaponLabel.anchorPoint = ccp( 0, 0.5 );
    weaponLabel.position    = ccp( 570, y );
    [self.paper addChild:weaponLabel];

    // ammo
    NSString * ammo;
    if ( unit.weapon.ammo <= 0 ) {
        ammo = @"Low ammo";
    }
    else {
        ammo = [NSString stringWithFormat:@"%d", unit.weapon.ammo];
    }

    CCLabelBMFont * ammoLabel = [CCLabelBMFont labelWithString:ammo fntFile:fontFile];
    ammoLabel.anchorPoint = ccp( 0, 0.5 );
    ammoLabel.position    = ccp( 690, y );
    [self.paper addChild:ammoLabel];

    // mode
    CCLabelBMFont * modeLabel = [CCLabelBMFont labelWithString:unit.modeName fntFile:fontFile];
    modeLabel.anchorPoint = ccp( 0, 0.5 );
    modeLabel.position    = ccp( 770, y );
    [self.paper addChild:modeLabel];
}


- (void) createBackground {
    for ( int row = 0; row < 6; row++ ) {
        for ( int column = 0; column < 9; column++ ) {
            NSString * name;

            // bottom left?
            if ( row == 0 && column == 0 ) {
                name = @"Paper/paper_bottom_left.png";
            }

            // bottom right?
            else if ( row == 0 && column == 8 ) {
                name = @"Paper/paper_bottom_right.png";
            }

            // left?
            else if ( column == 0 ) {
                name = @"Paper/paper_left.png";
            }

            // bottom?
            else if ( row == 0 ) {
                name = @"Paper/paper_bottom.png";
            }

            // right?
            else if ( column == 8 ) {
                name = @"Paper/paper_right.png";
            }

            else {
                // normal center
                name = @"Paper/paper_center.png";
            }

            // create a path node sprite
            CCSprite * piece = [CCSprite spriteWithSpriteFrameName:name];
            piece.position = ccp( column * 100 + 50, row * 100 + 50 );
            [self.paper addChild:piece];
        }
    }
}

@end
