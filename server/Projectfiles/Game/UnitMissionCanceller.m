
#import "UnitMissionCanceller.h"
#import "GameLayer.h"
#import "Globals.h"
#import "Unit.h"
#import "ChangeModeMission.h"
#import "DisorganizedMission.h"
#import "IdleMission.h"
#import "Utils.h"

@interface UnitMissionCanceller ()

@property (nonatomic, strong) CCMenuItemSprite * cancelButton;
@property (nonatomic, strong) CCMenu *           menu;
@end


@implementation UnitMissionCanceller

- (id) init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:NotificationSelectionChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:NotificationSelectedUnitMissionsChanged object:nil];

        // find unit button
        self.cancelButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2.png"]
                                                    selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall2Pressed.png"]
                                                            target:self
                                                          selector:@selector(cancelMission)];

        [Utils createImage:@"Buttons/Cancel.png" withYOffset:0 forButton:self.cancelButton];

        
        self.menu = [CCMenu menuWithItems:self.cancelButton, nil];
        self.menu.position = ccp( 0, 0 );
        [self addChild:self.menu];

        // not visible by default
        self.menu.opacity = 0;
        self.menu.visible = NO;
    }
    
    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    CCLOG( @"in" );
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
        
    // any current unit or enemy?
    if ( selectedUnit == nil || selectedUnit.owner != [Globals sharedInstance].localPlayer.playerId || [selectedUnit.mission isKindOfClass:[IdleMission class]] ) {
        // no unit, missions or enemy
        [self fadeOut];
        return;
    }

    // can it be cancelled at all?
    if ( ! selectedUnit.mission.canBeCancelled ) {
        CCLOG( @"mission can not be cancelled" );
        [self fadeOut];
        return;
    }

    // show ourselves
    [self fadeIn];
}


- (void) fadeOut {
    CCLOG( @"in" );

    if ( self.menu.opacity <= 0.05f ) {
        return;
    }

    // cancel any actions running and then fade out
    [self.menu stopAllActions];
    [self.menu runAction:[CCSequence actions:
                          [CCFadeOut actionWithDuration:0.3f],
                          [CCCallFuncN actionWithTarget:self selector:@selector(hide)], nil]];
}


- (void) fadeIn {
    CCLOG( @"in" );

    if ( self.menu.opacity >= 0.95f ) {
        return;
    }

    self.menu.visible = YES;
    self.menu.opacity = 0;
    
    // cancel any actions running and then fade out
    [self.menu stopAllActions];
    [self.menu runAction:[CCFadeIn actionWithDuration:0.4f]];
}


- (void) hide {
    self.menu.visible = NO;
}


- (void) cancelMission {
    CCLOG( @"in" );
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // precautions, don't
    if ( self.menu.numberOfRunningActions > 0 ) {
        // don't allow anything to take place while the menu is fading. it could also be fading in and then
        // pressing would be ok, but that's a small issue
        return;
    }

    // nothing selected?
    NSAssert( selectedUnit, @"No selected unit" );

    Mission * mission = selectedUnit.mission;

    // any missions?
    if ( mission && mission.type != kIdleMission ) {
        // can it be cancelled at all?
        if ( ! mission.canBeCancelled ) {
            CCLOG( @"mission can not be cancelled" );
            return;
        }

        // is it a retreat mission?
        if ( mission.type == kRetreatMission ) {
            DisorganizedMission * disorganizedMission = [[DisorganizedMission alloc] initWithUnit:selectedUnit];
            disorganizedMission.fastReorganizing = YES;
            selectedUnit.mission = disorganizedMission;
            CCLOG( @"cancelled retreat mission, now disorganized" );
        }
        else {
            // something else, just cancel it
            selectedUnit.mission = nil;
            CCLOG( @"cancelled mission, now idle" );
        }
    }

    [[Globals sharedInstance].audio playSound:kMissionCancelled];
}

@end
