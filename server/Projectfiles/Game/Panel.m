
#import "CCBReader.h"

#import "Panel.h"
#import "Globals.h"
#import "Unit.h"
#import "MapLayer.h"
#import "GameLayer.h"
#import "Utils.h"
#import "ChangeModeMission.h"
#import "DisorganizedMission.h"
#import "IdleMission.h"
#import "HelpOverlay.h"

@implementation Panel

@synthesize nameLabel;
@synthesize hqLabelInCommand;
@synthesize hqLabelNotInCommand;
@synthesize hqLabelDestroyed;
@synthesize menLabel;
@synthesize missionLabel;
@synthesize terrainLabel;
@synthesize modeLabel;
@synthesize weaponLabel;
@synthesize experienceLabel;
@synthesize ammoLabel;
@synthesize moraleLabel;
@synthesize fatigueLabel;
@synthesize pingLabel;
@synthesize nextButton;
@synthesize previousButton;
@synthesize findButton;
@synthesize hqButton;
@synthesize cancelButton;
@synthesize changeModeButton;
@synthesize toggleAutoFireButton;
@synthesize helpButton;
@synthesize terrainNames;

+ (Panel *) node {
    Panel * node = (Panel *)[CCBReader nodeGraphFromFile:@"Panel.ccb"];
    return node;
}


- (void) didLoadFromCCB {
    // we want to know when the selected unit changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:sNotificationSelectionChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitChanged:) name:sNotificationSelectedUnitMissionsChanged object:nil];
    
    // and stats too
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedUnitStatsChanged:) name:sNotificationEngineSimulationDone object:nil];

    // cache all terrain names
    self.terrainNames = [CCArray arrayWithCapacity:kNoTerrain];
    [self.terrainNames addObject:@"Woods"];
    [self.terrainNames addObject:@"Field"];
    [self.terrainNames addObject:@"Grass"];
    [self.terrainNames addObject:@"Road"];
    [self.terrainNames addObject:@"River"];
    [self.terrainNames addObject:@"House"];
    [self.terrainNames addObject:@"Swamp"];
    [self.terrainNames addObject:@"Rocky"];
    [self.terrainNames addObject:@"Beach"];
    [self.terrainNames addObject:@"Ford"];
    [self.terrainNames addObject:@"Scattered trees"];

    Globals * globals = [Globals sharedInstance];

    // game clock
    Clock * clock = [Clock node];
    clock.position = ccp( -500, 32 );
    globals.clock = clock;
    [self addChild:globals.clock];

    // initial clock update
    [clock update];

    // buttons
    [Utils createImage:@"Buttons/Next.png" withYOffset:0 forButton:self.nextButton];
    [Utils createImage:@"Buttons/Previous.png" withYOffset:0 forButton:self.previousButton];
    [Utils createImage:@"Buttons/Find.png" withYOffset:0 forButton:self.findButton];
    [Utils createImage:@"Buttons/HQ.png" withYOffset:0 forButton:self.hqButton];
    [Utils createImage:@"Buttons/Cancel.png" withYOffset:0 forButton:self.cancelButton];
    [Utils createImage:@"Buttons/ChangeMode.png" withYOffset:0 forButton:self.changeModeButton];
    [Utils createImage:@"Buttons/AutoFireOn.png" withYOffset:0 forButton:self.toggleAutoFireButton];
    [Utils createImage:@"Buttons/Help.png" withYOffset:0 forButton:self.helpButton];

    // initial updates
    [clock update];
    [self updateUnitInfo];
    [self updateUnitNavigation];
    [self updateMissionCanceller];
    [self updateChangeModeButton];
    [self updateAutoFireButton];
    [self updateHelpButton];

    // hide the ping label initially
    self.pingLabel.visible = NO;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) showServerPing:(double)ms {
    [self.pingLabel setString:[NSString stringWithFormat:@"Ping: %d", (int)ms]];
    self.pingLabel.visible = YES;
}


- (void) selectedUnitStatsChanged:(NSNotification *)notification {
    // update everything
    [self updateUnitInfo];
    [self updateUnitNavigation];
    [self updateMissionCanceller];
    [self updateChangeModeButton];
    [self updateAutoFireButton];
    [self updateHelpButton];
}


- (void) selectedUnitChanged:(NSNotification *)notification {
    // update everything
    [self updateUnitInfo];
    [self updateUnitNavigation];
    [self updateMissionCanceller];
    [self updateChangeModeButton];
    [self updateAutoFireButton];
    [self updateHelpButton];
}



// ****************************************************************************************************************
// Auto fire

- (void) updateAutoFireButton {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // any current unit or enemy?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // no unit, missions or enemy
        self.toggleAutoFireButton.visible = NO;
        return;
    }

    // set up the auto fire button
    NSString * iconName = selected.autoFireEnabled ? @"Buttons/AutoFireOn.png" : @"Buttons/AutoFireOff.png";
    [Utils createImage:iconName withYOffset:0 forButton:self.toggleAutoFireButton];

    // show the button
    self.toggleAutoFireButton.visible = YES;
}


- (void) toggleAutoFire {
    CCLOG(@"in");
    Globals * globals = [Globals sharedInstance];

    [globals.audio playSound:kActionClicked];

    Unit * selected = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selected != nil && selected.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );

    if ( selected.autoFireEnabled ) {
        // disable it
        selected.autoFireEnabled = NO;
        [Utils createImage:@"Buttons/AutoFireOff.png" withYOffset:0 forButton:self.toggleAutoFireButton];

        // does the unit currently fire? if so clear its mission immediately
        if ( selected.mission.type == kFireMission) {
            selected.mission = [IdleMission new];
        }
    }
    else {
        // enable
        selected.autoFireEnabled = YES;
        [Utils createImage:@"Buttons/AutoFireOn.png" withYOffset:0 forButton:self.toggleAutoFireButton];
    }
}


// ****************************************************************************************************************
// Change mode

- (void) updateChangeModeButton {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // any current unit or enemy?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // no unit, missions or enemy
        self.changeModeButton.visible = NO;
        return;
    }

    if ( ! [selected canBeGivenMissions] ) {
        //CCLOG( @"unit can't be given missions" );
        self.changeModeButton.visible = NO;
        return;
    }

    self.changeModeButton.visible = YES;
}


- (void) changeMode {
    [[Globals sharedInstance].audio playSound:kActionClicked];

    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // can the unit be given missions?
    if ( ! selected.canBeGivenMissions ) {
        CCLOG( @"can not be given missions" );
        return;
    }

    // check if the last mission is already a change mode. if so, we're done
    if ( selected.mission && selected.mission.type == kChangeModeMission ) {
        CCLOG( @"already changing mode" );
        return;
    }

    // set a new mission
    selected.mission = [ChangeModeMission new];
}


// ****************************************************************************************************************
// Auto fire

- (void) updateHelpButton {
    // nothing to do
}


- (void) showHelp {
    CCLOG( @"in" );

    HelpOverlay * popup = [HelpOverlay node];
    [[Globals sharedInstance].gameLayer addChild:popup z:kHelpOverlayZ];
}


// ****************************************************************************************************************
// Mission cancelling

- (void) updateMissionCanceller {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // any current unit or enemy?
    if ( selected == nil || selected.owner != [Globals sharedInstance].localPlayer.playerId || selected.mission.type == kIdleMission ) {
        // no unit, missions or enemy
        self.cancelButton.visible = NO;
        return;
    }

    // can it be cancelled at all?
    if ( ! selected.mission.canBeCancelled ) {
        CCLOG( @"mission can not be cancelled" );
        self.cancelButton.visible = NO;
        return;
    }

    self.cancelButton.visible = YES;
}


- (void) cancelMission {
    CCLOG( @"in" );
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // nothing selected?
    NSAssert( selected, @"No selected unit" );

    Mission * mission = selected.mission;

    // any missions?
    if ( mission && mission.type != kIdleMission ) {
        // can it be cancelled at all?
        if ( ! mission.canBeCancelled ) {
            CCLOG( @"mission can not be cancelled" );
            return;
        }

        // is it a retreat mission?
        if ( mission.type == kRetreatMission ) {
            DisorganizedMission * disorganizedMission = [DisorganizedMission new];
            disorganizedMission.fastReorganizing = YES;
            selected.mission = disorganizedMission;
            CCLOG( @"cancelled retreat mission, now disorganized" );
        }
        else {
            // something else, just cancel it
            selected.mission = nil;
            CCLOG( @"cancelled mission, now idle" );
        }
    }

    [[Globals sharedInstance].audio playSound:kMissionCancelled];
}


// ****************************************************************************************************************
// Unit navigation

- (void) updateUnitNavigation {
    Player * player = [Globals sharedInstance].localPlayer;
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // any current unit or enemy?
    if ( selected == nil || selected.owner != player.playerId ) {
        // no unit or enemy
        self.nextButton.visible = NO;
        self.previousButton.visible = NO;
        self.findButton.visible = NO;
        self.hqButton.visible = NO;
        return;
    }

    self.nextButton.visible = YES;
    self.previousButton.visible = YES;
    self.findButton.visible = YES;

    // does it have a headquarter?
    self.hqButton.visible = selected.headquarter != nil && ! selected.headquarter.destroyed;
}

- (void) nextUnit {
    CCLOG( @"in" );
    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selected_unit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selected_unit != nil && selected_unit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );

    // the own units
    CCArray * own = selected_unit.owner == kPlayer1 ? globals.unitsPlayer1 : globals.unitsPlayer2;

    // index of the selected unit
    NSUInteger index = [own indexOfObject:selected_unit];
    Unit * found = nil;

    while ( found == nil ) {
        if ( ++index == own.count ) {
            index = 0;
        }

        Unit * check = [own objectAtIndex:index];

        // did we loop around and got to our start unit?
        if ( check == selected_unit ) {
            break;
        }

        // destroyed?
        if ( check.destroyed ) {
            continue;
        }

        found = check;
    }

    if ( found != nil ) {
        // set a new selected unit
        globals.selection.selectedUnit = found;

        // center the map on it
        [globals.gameLayer centerMapOn:globals.selection.selectedUnit];
    }
}


- (void) previousUnit {
    CCLOG( @"in" );

    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selected_unit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selected_unit != nil && selected_unit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );

    // the own units
    CCArray * own = selected_unit.owner == kPlayer1 ? globals.unitsPlayer1 : globals.unitsPlayer2;

    // index of the selected unit
    NSUInteger index = [own indexOfObject:selected_unit];
    Unit * found = nil;

    while ( found == nil ) {
        if ( index == 0 ) {
            index = own.count - 1;
        }
        else {
            index--;
        }

        Unit * check = [own objectAtIndex:index];

        // did we loop around and got to our start unit?
        if ( check == selected_unit ) {
            break;
        }

        // destroyed?
        if ( check.destroyed ) {
            continue;
        }

        found = check;
    }

    if ( found != nil ) {
        // set a new selected unit
        globals.selection.selectedUnit = found;

        // center the map on it
        [globals.gameLayer centerMapOn:globals.selection.selectedUnit];
    }
}


- (void) activateHq {
    CCLOG( @"in" );

    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selected_unit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selected_unit != nil && selected_unit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );

    // does it have a hq?
    Unit * hq = selected_unit.headquarter;
    if ( hq ) {
        globals.selection.selectedUnit = hq;

        // center the map on it
        [globals.gameLayer centerMapOn:hq];
    }
}


- (void) findUnit {
    CCLOG( @"in" );

    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    Unit * selectedUnit = globals.selection.selectedUnit;
    Player * player = globals.localPlayer;

    NSAssert( selectedUnit != nil && selectedUnit.owner == player.playerId && player.type == kLocalPlayer, @"Invalid state" );
    
    // center the map on it
    [globals.gameLayer centerMapOn:selectedUnit];
}


// ****************************************************************************************************************
// Unit info

- (void) updateUnitInfo {
    Unit * selected = [Globals sharedInstance].selection.selectedUnit;

    // any current unit?
    BOOL hasUnit = selected != nil;

    self.nameLabel.visible = hasUnit;
    self.missionLabel.visible = hasUnit;
    self.menLabel.visible = hasUnit;
    self.terrainLabel.visible = hasUnit;
    self.modeLabel.visible = hasUnit;
    self.weaponLabel.visible = hasUnit;
    self.moraleLabel.visible = hasUnit;
    self.fatigueLabel.visible = hasUnit;

    // hide the rest if no unit
    if ( ! hasUnit ) {
        self.hqLabelInCommand.visible = NO;
        self.hqLabelNotInCommand.visible = NO;
        self.hqLabelDestroyed.visible = NO;
        self.experienceLabel.visible = NO;
        self.ammoLabel.visible = NO;
        return;
    }

    BOOL ownUnit = selected.owner == [Globals sharedInstance].localPlayer.playerId;

    // name
    [self.nameLabel setString:selected.name];

    // any hq?
    Unit * headquarter;
    if ( ownUnit && ( headquarter = selected.headquarter) != nil ) {
        if ( headquarter.destroyed ) {
            self.hqLabelInCommand.visible = NO;
            self.hqLabelNotInCommand.visible = NO;
            self.hqLabelDestroyed.visible = YES;
        }
        else if ( selected.inCommand ) {
            [self.hqLabelInCommand setString:[NSString stringWithFormat:@"(%@)", headquarter.name]];
            self.hqLabelInCommand.visible = YES;
            self.hqLabelNotInCommand.visible = NO;
            self.hqLabelDestroyed.visible = NO;
        }
        else {
            [self.hqLabelNotInCommand setString:[NSString stringWithFormat:@"(%@)", headquarter.name]];
            self.hqLabelNotInCommand.visible = YES;
            self.hqLabelInCommand.visible = NO;
            self.hqLabelDestroyed.visible = NO;
        }
    }
    else {
        // no headquarter
        self.hqLabelInCommand.visible = NO;
        self.hqLabelNotInCommand.visible = NO;
        self.hqLabelDestroyed.visible = NO;
    }

    // men and experience. show more exact for own men
    if ( ownUnit ) {
        [self.menLabel setString:[NSString stringWithFormat:@"%d / %d men", selected.men, selected.originalMen]];

        self.experienceLabel.visible = YES;
        switch ( selected.experience ) {
            case kGreen:
                [self.experienceLabel setString:@"Green"];
                break;
            case kRegular:
                [self.experienceLabel setString:@"Regular"];
                break;
            case kVeteran:
                [self.experienceLabel setString:@"Veteran"];
                break;
            case kElite:
                [self.experienceLabel setString:@"Elite"];
                break;
        }

        // ammunition
        self.ammoLabel.visible = YES;
        if ( selected.weapon.ammo <= 0 ) {
            [self.ammoLabel setString:@"Low ammo"];
        }
        else {
            [self.ammoLabel setString:[NSString stringWithFormat:@"%d ammo", selected.weapon.ammo]];
        }
    }
    else {
        // show an approximation
        int min = (selected.men / 10) * 10;
        int max = min + 10;

        [self.menLabel setString:[NSString stringWithFormat:@"%d - %d men", min, max]];

        // no experience for enemies
        self.experienceLabel.visible = NO;
        self.ammoLabel.visible = NO;
    }

    // mission
    Mission * mission = selected.mission;
    if ( mission == nil ) {
        [self.missionLabel setString:@"No mission"];
    }
    else if ( ownUnit && mission.commandDelay > 0 ) {
        [self.missionLabel setString:mission.preparingName];
    }
    else {
        [self.missionLabel setString:mission.name];
    }

    // terrain under the unit
    TerrainType terrain_type = [[Globals sharedInstance].mapLayer getTerrainForUnit:selected];
    NSString * terrain_name = [self.terrainNames objectAtIndex:terrain_type];
    [self.terrainLabel setString:terrain_name];

    // unit mode
    [self.modeLabel setString:selected.modeName];

    // weapon type and count
    if ( selected.weapon.menRequired == 1 ) {
        [self.weaponLabel setString:selected.weapon.name];
    }
    else {
        // we have weapons where we need more than one man per weapon
        [self.weaponLabel setString:[NSString stringWithFormat:@"%d %@", selected.weaponCount, selected.weapon.name]];
    }


    // morale
    float morale = selected.morale;
    if ( ownUnit ) {
        // for own units we show complete morale
        if ( morale < sParameters[kParamMaxMoraleRoutedF].floatValue ) {
            [self.moraleLabel setString:[NSString stringWithFormat:@"Routed (%.1f)", morale]];
        }
        else if ( morale < sParameters[kParamMaxMoraleShakenF].floatValue ) {
            [self.moraleLabel setString:[NSString stringWithFormat:@"Shaken (%.1f)", morale]];
        }
        else if ( morale < sParameters[kParamMaxMoraleWorriedF].floatValue ) {
            [self.moraleLabel setString:[NSString stringWithFormat:@"Worried (%.1f)", morale]];
        }
        else if ( morale < sParameters[kParamMaxMoraleCalmF].floatValue ) {
            [self.moraleLabel setString:[NSString stringWithFormat:@"Calm (%.1f)", morale]];
        }
        else {
            [self.moraleLabel setString:[NSString stringWithFormat:@"Firm (%.1f)", morale]];
        }

        // make sure it's visible
        self.moraleLabel.visible = YES;
    }
    else {
        // enemy unit, only show the routed status, everything else is hidden
        if ( morale < 20 ) {
            [self.moraleLabel setString:[NSString stringWithFormat:@"Routed (%.1f)", morale]];

            // make sure it's visible
            self.moraleLabel.visible = YES;
        }
        else {
            self.moraleLabel.visible = NO;
        }
    }


    // fatigue
    float fatigue = selected.fatigue;
    if ( ownUnit ) {
        // for own units we show complete morale
        if ( fatigue < 20 ) {
            [self.fatigueLabel setString:[NSString stringWithFormat:@"Rested (%.1f)", fatigue]];
        }
        else if ( fatigue < 40 ) {
            [self.fatigueLabel setString:[NSString stringWithFormat:@"Ready (%.1f)", fatigue]];
        }
        else if ( fatigue < 60 ) {
            [self.fatigueLabel setString:[NSString stringWithFormat:@"Tired (%.1f)", fatigue]];
        }
        else if ( fatigue < 80 ) {
            [self.fatigueLabel setString:[NSString stringWithFormat:@"Worn (%.1f)", fatigue]];
        }
        else {
            [self.fatigueLabel setString:[NSString stringWithFormat:@"Exhausted (%.1f)", fatigue]];
        }

        // make sure it's visible
        self.fatigueLabel.visible = YES;
    }
    else {
        // enemy unit, we have no idea
        self.fatigueLabel.visible = NO;
    }
}

@end
