
#import "ActionsMenu.h"
#import "Globals.h"
#import "MapLayer.h"
#import "TerrainModifiers.h"
#import "Audio.h"
#import "GameLayer.h"
#import "Messages.h"
#import "Message.h"
#import "Engine.h"
#import "Utils.h"
#import "LineOfSight.h"

#import "RotateMission.h"
#import "MoveMission.h"
#import "MoveFastMission.h"
#import "RetreatMission.h"
#import "AdvanceMission.h"
#import "AssaultMission.h"
#import "FireMission.h"
#import "AreaFireMission.h"
#import "SmokeMission.h"
#import "ScoutMission.h"
#import "ChangeModeMission.h"
#import "RallyMission.h"

@interface ActionsMenu () {
    CGPoint cachedClickedPos;
    Unit * cachedClickedUnit;
}

@property (nonatomic, strong) CCMenu *           menu;
@property (nonatomic, strong) CCMenuItemSprite * moveButton;
@property (nonatomic, strong) CCMenuItemSprite * moveFastButton;
@property (nonatomic, strong) CCMenuItemSprite * turnButton;
@property (nonatomic, strong) CCMenuItemSprite * rallyButton;
@property (nonatomic, strong) CCMenuItemSprite * selectButton;
@property (nonatomic, strong) CCMenuItemSprite * retreatButton;
@property (nonatomic, strong) CCMenuItemSprite * scoutButton;
@property (nonatomic, strong) CCMenuItemSprite * fireButton;
@property (nonatomic, strong) CCMenuItemSprite * areaFireButton;
@property (nonatomic, strong) CCMenuItemSprite * smokeButton;
@property (nonatomic, strong) CCMenuItemSprite * advanceButton;
@property (nonatomic, strong) CCMenuItemSprite * assaultButton;

// optional drag path
@property (nonatomic, strong) Path *             path;
@property (nonatomic, strong) NSMutableArray *   pathNodes;

// deployment time position
@property (nonatomic, strong) CCSprite *         deploymentPosition;

@end


@implementation ActionsMenu

- (id)init {
    self = [super init];
    if (self) {
        // we want to know when the selected unit changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectedUnitChanged:)
                                                     name:sNotificationSelectionChanged object:nil];

        // load all actions as menu items into a list
        self.moveButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1.png"]
                                                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1Pressed.png"]
                                                          target:self
                                                        selector:@selector(move)];

        self.moveFastButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2.png"]
                                                      selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2Pressed.png"]
                                                              target:self
                                                            selector:@selector(moveFast)];

        self.turnButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton3.png"]
                                                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton3Pressed.png"]
                                                          target:self
                                                        selector:@selector(turn)];

        self.rallyButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1.png"]
                                                   selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1Pressed.png"]
                                                           target:self
                                                         selector:@selector(rally)];
        self.selectButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2.png"]
                                                    selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2Pressed.png"]
                                                            target:self
                                                          selector:@selector(selectUnit)];

        self.retreatButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1.png"]
                                                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1Pressed.png"]
                                                             target:self
                                                           selector:@selector(retreat)];

        self.scoutButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2.png"]
                                                   selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2Pressed.png"]
                                                           target:self
                                                         selector:@selector(scout)];

        self.fireButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton3.png"]
                                                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton3Pressed.png"]
                                                          target:self
                                                        selector:@selector(fire)];

        self.areaFireButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton3.png"]
                                                      selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton3Pressed.png"]
                                                              target:self
                                                            selector:@selector(areaFire)];
        self.smokeButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2.png"]
                                                   selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2Pressed.png"]
                                                           target:self
                                                         selector:@selector(smoke)];

        self.advanceButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1.png"]
                                                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton1Pressed.png"]
                                                             target:self
                                                           selector:@selector(advance)];

        self.assaultButton = [CCMenuItemSprite itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2.png"]
                                                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"Buttons/ActionButton2Pressed.png"]
                                                             target:self
                                                           selector:@selector(assault)];

        // create the labels
        [Utils createText:@"Move"      forButton:self.moveButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Move fast" forButton:self.moveFastButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Turn"      forButton:self.turnButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Retreat"   forButton:self.retreatButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Scout"     forButton:self.scoutButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Area fire" forButton:self.areaFireButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Fire"      forButton:self.fireButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Smoke"     forButton:self.smokeButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Advance"   forButton:self.advanceButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Assault"   forButton:self.assaultButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Rally"     forButton:self.rallyButton withFont:@"ActionsFont.fnt"];
        [Utils createText:@"Select"    forButton:self.selectButton withFont:@"ActionsFont.fnt"];

        // create an empty menu
        self.menu = [CCMenu menuWithItems:nil];
        self.menu.position = ccp( 0, 0 );
        [self addChild:self.menu];

        // not visible by default
        self.visible = NO;

        self.deploymentPosition = nil;
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) onEnter {
    [super onEnter];
    CCLOG( @"in" );

    // we handle touches, make sure we get before all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority + 1 swallowsTouches:YES];
}


- (void) onExit {
    [super onExit];
    CCLOG( @"in" );

    // no mre touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        return NO;
    }

    CCLOG( @"hiding" );

    // we were visible, hide
    [self hide];
    return YES;
}


- (void) selectedUnitChanged:(NSNotification *) notification {
    // always hidden by default
    [self hide];
}


- (void) path:(Path *)path createdTo:(CGPoint)pos withNodes:(NSMutableArray *)pathNodes {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    NSAssert( selectedUnit, @"No selected unit" );

    CCLOG( @"show movement menu, path size: %lu", (unsigned long)path.count );

    // save the path
    self.path = path;
    self.pathNodes = pathNodes;

    // remove all old items that the menu may have
    [self.menu removeAllChildrenWithCleanup:NO];

    // remove all old selectors
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

    // can the unit perform any actions at all, or is it meleeing/disorganized? it could have
    // gone bad while the path was drawn, even if it was ok when the path was started
    if ( ! [selectedUnit canBeGivenMissions] ) {
        // play an error sound
        [[Globals sharedInstance].audio playSound:kUnitNoActions];
        [self hide];
        return;
    }

    [self show];

    // all action buttons that will be shown
    CCArray * actions = [CCArray new];

    // assume the terrain is ok, add the actions that can always be executed
    [actions addObject:self.moveButton];

    // get the mode that the unit is in right now
    if ( selectedUnit.mode == kColumn ) {
        if ( selectedUnit.fastMovementSpeed > 0 ) {
            [actions addObject:self.moveFastButton];
        }
    }

    // the rest of the always enabled actions
    [actions addObject:self.scoutButton];
    [actions addObject:self.retreatButton];

    if ( [selectedUnit canFire] ) {
        // how long is the path? we can only assault and advance for so long
        float pathLength = path.length;

        // can we advance?
        if ( selectedUnit.advanceSpeed > 0 && pathLength < selectedUnit.advanceRange ) {
            [actions addObject:self.advanceButton];
        }

        // can we assault?
        if ( selectedUnit.assaultSpeed > 0 && pathLength < selectedUnit.assaultRange ) {
            [actions addObject:self.assaultButton];
        }
    }

    // now lay out the buttons
    [self layoutActions:actions near:pos];
}


- (void) mapClicked:(CGPoint)pos {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    NSAssert( selectedUnit, @"No selected unit" );

    CCLOG( @"show movement menu" );

    cachedClickedPos = pos;

    // no path when the map is clicked
    self.path = nil;

    // remove all old items that the menu may have
    [self.menu removeAllChildrenWithCleanup:NO];

    // remove all old selectors
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

    CCArray * actions = nil;

    // can the unit perform any actions at all, or is it meleeing/disorganized?
    if ( ! [selectedUnit canBeGivenMissions] ) {
        // play an error sound
        [[Globals sharedInstance].audio playSound:kUnitNoActions];

        // show an error label to the player
        [[Globals sharedInstance].engine.messages addObject:[[Message alloc] initWithMessage:kNoMissions forUnit:selectedUnit]];

        [self hide];
        return;
    }

    // all action buttons that will be shown
    actions = [CCArray new];
    [actions addObject:self.turnButton];

    // and show a LOS line
    BOOL canSeeTarget = [[Globals sharedInstance].mapLayer canSeeFrom:selectedUnit.position to:pos visualize:YES withMaxRange:selectedUnit.visibilityRange];

    // area fire possible?
    if ( [selectedUnit canFire] ) {
        // is the clicked unit inside the firing range?
        if ( ccpDistance( selectedUnit.position, pos ) < selectedUnit.weapon.firingRange ) {
            // can we see the pos?
            if (canSeeTarget ) {
                // we see it too so we can fire at the position
                [actions addObject:self.areaFireButton];

                // can the unit fire smoke too?
                if ( selectedUnit.weapon.canFireSmoke ) {
                    [actions addObject:self.smokeButton];
                }
            }

            // inside firing range but we can't see it
            else if ( selectedUnit.weapon.type == kMortar || selectedUnit.weapon.type == kHowitzer) {
                // yes, so it could use its HQ as a spotter
                Unit * hq = selectedUnit.headquarter;

                // does it have an hq within command distance that is alive that can see the enemy?
                if ( hq &&
                    ! hq.destroyed &&
                    [hq isIdle] &&
                    selectedUnit.inCommand &&
                    [[Globals sharedInstance].mapLayer canSeeFrom:hq.position to:pos visualize:NO withMaxRange:hq.visibilityRange] ) {
                    CCLOG( @"mortar/howitzer unit %@ can fire at %.1f,%.1f using hq %@ as spotter", selectedUnit, pos.x, pos.y, hq );
                    // we can fire at the enemy using our HQ as spotter
                    [actions addObject:self.areaFireButton];

                    // can the unit fire smoke too?
                    if ( selectedUnit.weapon.canFireSmoke ) {
                        [actions addObject:self.smokeButton];
                    }
                }
            }
        }
    }


    [self show];

    // now lay out the buttons
    [self layoutActions:actions near:pos];
}


- (BOOL) ownUnitClicked:(Unit *)clicked {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    // must be a HQ
    if ( ! selectedUnit.isHeadquarter ) {
        return NO;
    }

    // must be able to give missions
    if ( ! [selectedUnit canBeGivenMissions] ) {
        return NO;
    }

    // clicked must be one of its subordinates
    if ( clicked.headquarter != selectedUnit ) {
        return NO;
    }

    // is it in command?
    if ( ! clicked.inCommand ) {
        return NO;
    }

    // it also can have no mission apart from being disorganized
    if ( clicked.mission.type != kIdleMission && clicked.mission.type != kDisorganizedMission ) {
        return NO;
    }

    // is the morale of the clicked unit low?
    if ( clicked.morale >= sParameters[kParamMaxMoraleShakenF].floatValue ) {
        return NO;
    }

    // does the HQ see the unit?
    if  ( ! [clicked.headquarter.losData seesUnit:clicked] ) {
        // does not see the unit, can't rally
        return NO;
    }

    // in case the player decides to turn we need this along with the enemy
    cachedClickedPos = clicked.position;
    cachedClickedUnit = clicked;

    // remove all old items that the menu may have
    [self.menu removeAllChildrenWithCleanup:NO];

    // remove all old hide selectors
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

    [self show];

    // all action buttons that will be shown
    CCArray * actions = [CCArray new];

    // add the buttons
    [actions addObject:self.rallyButton];
    [actions addObject:self.selectButton];

    // now lay out the buttons
    [self layoutActions:actions near:clicked.position];

    // we took this
    return YES;
}


- (void) enemyClicked:(Unit *)enemy {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    //CGPoint ownPos = selectedUnit.position;
    CGPoint enemyPos = enemy.position;

    // in case the player decides to turn we need this along with the enemy
    cachedClickedPos = enemyPos;
    cachedClickedUnit = enemy;

    // no path when an enemy is clicked
    self.path = nil;

    NSAssert( selectedUnit, @"no selected own unit" );

    // remove all old items that the menu may have
    [self.menu removeAllChildrenWithCleanup:NO];

    // remove all old hide selectors
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

    // can the unit perform any actions at all, or is it meleeing/disorganized?
    if ( ! [selectedUnit canBeGivenMissions] ) {
        // play an error sound
        [[Globals sharedInstance].audio playSound:kUnitNoActions];

        [self hide];
        return;
    }

    [self show];

    // all action buttons that will be shown
    CCArray * actions = [CCArray new];

    if ( [selectedUnit canFire] ) {
        // is the clicked unit inside the firing range?
        if ( ccpDistance( selectedUnit.position, enemy.position ) < selectedUnit.weapon.firingRange ) {
            // can we see the enemy?
            if ( [selectedUnit.losData seesUnit:enemy] ) {
                // we see it too so we can fire at the enemy
                [actions addObject:self.fireButton];
            }

            // inside firing range but we can't see it
            else if ( selectedUnit.weapon.type == kMortar || selectedUnit.weapon.type == kHowitzer) {
                // yes, so it could use its HQ as a spotter
                Unit * hq = selectedUnit.headquarter;

                // does it have an hq within command distance that is alive that can see the enemy?
                if ( hq &&
                    ! hq.destroyed &&
                    [hq isIdle] &&
                    ccpDistance( selectedUnit.position, hq.position ) < hq.commandRange &&
                    [hq.losData seesUnit:enemy] ) {
                    CCLOG( @"mortar unit %@ can fire at %@ using hq %@ as spotter", selectedUnit, enemy, hq );
                    // we can fire at the enemy using our HQ as spotter
                    [actions addObject:self.fireButton];
                }
            }
        }
    }

    // the rest of the always enabled actions
    [actions addObject:self.turnButton];

    // now lay out the buttons
    [self layoutActions:actions near:enemyPos];

    // and show a LOS line
    [[Globals sharedInstance].mapLayer canSeeFrom:selectedUnit.position to:enemyPos visualize:YES withMaxRange:selectedUnit.visibilityRange];
}


- (void) hide {
    // remove all old items that the menu may have
    [self.menu removeAllChildrenWithCleanup:NO];

    // hide the LOS visualizer
    [Globals sharedInstance].mapLayer.losVisualizer.visible = NO;

    // remove all path nodes
    if ( self.pathNodes ) {
        for ( CCSprite * point in self.pathNodes ) {
            [point removeFromParentAndCleanup:YES];
        }
    }

    // if deploying this is valid
    if ( self.deploymentPosition ) {
        [self.deploymentPosition removeFromParent];
        self.deploymentPosition = nil;
    }

    self.visible = NO;
}


- (void) show {
    // remove all old hide selectors
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

    // schedule a hide after some seconds
    [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector(hide) forTarget:self interval:5.0f paused:NO];

    // make ourselves visible
    self.visible = YES;
}


- (void) layoutActions:(CCArray *)actions near:(CGPoint)clickedPos {
    // precautions
    if ( actions.count == 0  ) {
        CCLOG( @"no actions given");
        return;
    }

    CGPoint result;

    // position of the selected unit
    CGPoint unitPos = [Globals sharedInstance].selection.selectedUnit.position;

    // convert to our coordinate system
    unitPos = [[Globals sharedInstance].gameLayer convertMapCoordinateToWorld:unitPos];
    clickedPos = [[Globals sharedInstance].gameLayer convertMapCoordinateToWorld:clickedPos];

    // vertical spacing between items
    float xSpacing = 10;
    float ySpacing = 0;

    // margin to the top or bottom of the screen
    float yMargin = 10;

    // the rect that we need for all actions. the height adds some spacing
    float width = self.moveFastButton.boundingBox.size.width;
    float height = actions.count * self.moveFastButton.boundingBox.size.height + (actions.count - 1) * ySpacing;

    // viewport size
    CGSize winSize = [CCDirector sharedDirector].winSize;

    if ( unitPos.x < clickedPos.x ) {
        // try to put the menu to the right
        if ( clickedPos.x + xSpacing + width > winSize.width ) {
            // to the right would be outside
            result = CGPointMake( clickedPos.x - xSpacing - width / 2, clickedPos.y );
        }
        else {
            // fits to the right
            result = CGPointMake( clickedPos.x + xSpacing + width / 2, clickedPos.y );
        }
    }
    else {
        // try to put the menu to the left
        if ( clickedPos.x - xSpacing - width < 0 ) {
            // to the left would be outside
            result = CGPointMake( clickedPos.x + xSpacing + width / 2, clickedPos.y );
        }
        else {
            // fits to the left
            result = CGPointMake( clickedPos.x - xSpacing - width / 2, clickedPos.y );
        }
    }

    // too high up or too low down?
    if ( result.y + height / 2 + yMargin > winSize.height ) {
        result.y = winSize.height - height / 2 - yMargin;
    }
    else if ( result.y - ( height / 2 + yMargin ) < 0 ) {
        result.y = height / 2 + yMargin;
    }

    //CCLOG( @"unit: %.0f %.0f, clicked: %.0f %.0f -> result: %.0f %.0f", unitPos.x, unitPos.y, clickedPos.x, clickedPos.y, result.x, result.y);

    // now lay out the action buttons vertically
    CCMenuItemSprite * action = [actions objectAtIndex:0];
    float y = result.y + height / 2 - [action boundingBox].size.height / 2;
    for ( CCMenuItem * button in actions ) {
        [self.menu addChild:button];
        button.position = ccp( result.x, y );
        y -= (button.boundingBox.size.height + ySpacing);
        CCLOG( @"%f %@", y, button );
    }
}


- (void) move {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self addMovementMission:[[MoveMission alloc] initWithPath:self.path] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) moveFast {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self addMovementMission:[[MoveFastMission alloc] initWithPath:self.path] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) retreat {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self addMovementMission:[[RetreatMission alloc] initWithPath:self.path] forUnit:selectedUnit];

    // hide ourselves
    [self hide];
}


- (void) scout {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self addMovementMission:[[ScoutMission alloc] initWithPath:self.path] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) turn {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self setMission:[[RotateMission alloc] initFacingTarget:cachedClickedPos] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) rally {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self setMission:[[RallyMission alloc] initWithTarget:cachedClickedUnit] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) selectUnit {
    CCLOG(@"in");
    [Globals sharedInstance].selection.selectedUnit = cachedClickedUnit;
    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) areaFire {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self setMission:[[AreaFireMission alloc] initWithTargetPosition:cachedClickedPos] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) smoke {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self setMission:[[SmokeMission alloc] initWithTargetPosition:cachedClickedPos] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) fire {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self setMission:[[FireMission alloc] initWithTarget:cachedClickedUnit] forUnit:selectedUnit];

    [[Globals sharedInstance].audio playSound:kActionClicked];

    // hide ourselves
    [self hide];
}


- (void) advance {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self addMovementMission:[[AdvanceMission alloc] initWithPath:self.path] forUnit:selectedUnit];

    // hide ourselves
    [self hide];
}


- (void) assault {
    CCLOG(@"in");
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;
    [self addMovementMission:[[AssaultMission alloc] initWithPath:self.path] forUnit:selectedUnit];

    // hide ourselves
    [self hide];
}


- (void) setMission:(Mission *)mission forUnit:(Unit *)unit {
    // can the unit still be given missions?
    if ( ! [unit canBeGivenMissions] ) {
        // no, something has changed here
        [[Globals sharedInstance].audio playSound:kUnitNoActions];
        return;
    }
    
    unit.mission = mission;
}


- (void) addMovementMission:(Mission *)mission forUnit:(Unit *)unit {
    // can the unit still be given missions?
    if ( ! [unit canBeGivenMissions] ) {
        // no, something has changed here
        CCLOG( @"unit %@ can not be given missions anymore, not adding %@", unit, mission );
        [[Globals sharedInstance].audio playSound:kUnitNoActions];
        return;
    }
    
    // set the new mission
    unit.mission = mission;
}

@end
