#import "Tutorial.h"
#import "Globals.h"
#import "Scenario.h"
#import "GameLayer.h"
#import "GameMenuPopup.h"

#import "TutorialText.h"
#import "TutorialSprite.h"
#import "TutorialClick.h"
#import "TutorialCompleted.h"
#import "TutorialSelectUnit.h"
#import "TutorialMoveUnit.h"
#import "TutorialTurnUnit.h"
#import "TutorialWait.h"
#import "TutorialChangeMode.h"
#import "TutorialWaitDestroyed.h"

@interface Tutorial () {
    unsigned int currentIndex;
    BOOL active;
}

@property (nonatomic, strong) NSArray *parts;
@property (nonatomic, strong) NSMutableArray *shownParts;

@end


@implementation Tutorial

@synthesize parts;
@synthesize shownParts;

- (id) init {
    self = [super init];
    if (self) {
        active = YES;

        // the the game is manually quit
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( gameQuit ) name:sNotificationQuitGame object:nil];

        [self createParts];

        // show the first part
        [self showNextParts];
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );

    // make sure we're not registered anymore to avoid crashes
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) checkTutorial {
    // have we reached the end?
    if (!active) {
        return;
    }

    // the last part of the shown parts should be blocking
    TutorialPart *blocking = [self.shownParts lastObject];
    NSAssert( blocking, @"no blocking tutorial part" );

    // can it proceed?
    if ([blocking canProceed] == NO) {
        // can't proceed yet, so we're done here
        return;
    }

    // proceeding was ok, advance the tutorial
    [self showNextParts];
}


- (BOOL) checkTap:(CGPoint)pos {
    // have we reached the end?
    if (!active) {
        return NO;
    }

    CCLOG( @"tap pos: %f %f", pos.x, pos.y );

    // the last part of the shown parts should be blocking
    TutorialPart *blocking = [self.shownParts lastObject];
    NSAssert( blocking, @"no blocking tutorial part" );

    // can it proceed?
    if ([blocking canProceed:pos] == NO) {
        // can't proceed yet, so we don't claim the touch
        return NO;
    }

    [[Globals sharedInstance].audio playSound:kMapClicked];

    // proceeding was ok, advance the tutorial
    [self showNextParts];

    // we claimed this tap
    return YES;
}


- (void) gameQuit {
    CCLOG( @"in" );
}


- (void) showNextParts {
    // someone is speed tapping or we have reached the end
    if (!active) {
        return;
    }

    // cleanup all old show parts
    for (TutorialPart *part in self.shownParts) {
        [part cleanup];
    }
    [self.shownParts removeAllObjects];

    // are we done?
    if (currentIndex == self.parts.count) {
        // no longer active
        active = NO;

        CCLOG( @"all parts shown, no longer active" );
        return;
    }

    // loop and add all parts until a part blocks
    while (currentIndex < self.parts.count) {
        // show the next part
        TutorialPart *part = self.parts[currentIndex];
        [part showPartInTutorial:self];
        [self.shownParts addObject:part];

        // next part index
        currentIndex++;

        // does it block? if so we've now shown all we can
        if (part.blocks) {
            break;
        }
    }
}


- (void) createParts {
    int scenario_id = [Globals sharedInstance].scenario.scenarioId;

    if (scenario_id == 0) {
        self.parts = @[
                // welcome
                [[TutorialText alloc] initBlockingWithText:@"Welcome to Imperium basic training! Tap anywhere to proceed unless instructed to do something else." atPos:ccp( 600, 500 )],
                [[TutorialText alloc] initBlockingWithText:@"In this tutorial you will learn basic skills such as how to navigate the map." atPos:ccp( 600, 500 )],

                // real time
                [[TutorialText alloc] initBlockingWithText:@"Imperium operates in accelerated real time. Once the battle starts the clock is ticking." atPos:ccp( 180, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The clock at the left in the panel shows the current time." atPos:ccp( 180, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"You have to think fast so that your opponent does not outmaneuver you!" atPos:ccp( 180, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"Battles normally have a fixed length and end when the time is up or one of the players has won a decisive victory." atPos:ccp( 180, 150 )],

                // pause button
                [[TutorialText alloc] initBlockingWithText:@"You can pause the game using this button in the right corner. Tap again to resume." atPos:ccp( 800, 700 )],
                [[TutorialText alloc] initBlockingWithText:@"Orders can still be given to units even when the game is paused." atPos:ccp( 800, 700 )],
                [[TutorialText alloc] initBlockingWithText:@"Only single player games can be paused, online games can not be paused." atPos:ccp( 800, 700 )],
                [[TutorialText alloc] initBlockingWithText:@"Use pausing to give yourself some time to think and lay out those big plans!" atPos:ccp( 800, 700 )],

                // look at ui components

                // tell and navigate around the map
                [[TutorialText alloc] initBlockingWithText:@"At the default zoom level the visible portion of the map is about 1 km wide." atPos:ccp( 500, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"You can pan around the map and pinch to zoom in and out." atPos:ccp( 500, 400 )],
                [[TutorialText alloc] initWithText:@"Now try navigating and zooming the map." atPos:ccp( 500, 400 )],
                [[TutorialWait alloc] initWithTime:10],

                // in game menu
                [[TutorialText alloc] initBlockingWithText:@"The in game menu is up at the left." atPos:ccp( 220, 700 )],
                [[TutorialText alloc] initBlockingWithText:@"Opening the in game menu also pauses the game when in single player mode." atPos:ccp( 220, 700 )],
                [[TutorialText alloc] initBlockingWithText:@"From the menu you can look at help documentation, change sound settings, view battle statistics and quit the game." atPos:ccp( 220, 700 )],

                // help overlay
                [[TutorialText alloc] initBlockingWithText:@"The question mark button in the lower right corner shows an overlay with info about currently active user interface elements." atPos:ccp( 790, 80 )],
                [[TutorialText alloc] initBlockingWithText:@"Tap to show a help overlay and then tap anywhere to dismiss it. Try it now." atPos:ccp( 790, 80 )],

                // terrain
                [[TutorialText alloc] initBlockingWithText:@"The map consists of different terrain." atPos:ccp( 512, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Some terrain such as water is impassable while other types affect visibility, movement speed and cover." atPos:ccp( 512, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Moving on roads and open grass is faster than moving in woods. Some units can not move in woods at all." atPos:ccp( 512, 200 )],

                // line of sight
                [[TutorialText alloc] initBlockingWithText:@"You can only see enemies that at least one of your units sees. Terrain such as woods will obstruct visibility." atPos:ccp( 512, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Use that to your advantage and beware of hidden enemy units." atPos:ccp( 512, 200 )],

                // final words
                [[TutorialText alloc] initBlockingWithText:@"Now you are ready to continue with the next tutorial and meet your troops." atPos:ccp( 750, 384 )],
                [[TutorialText alloc] initWithText:@"Select 'Quit' from the in game menu to proceed." atPos:ccp( 220, 700 )],

                // mark it as completed
                [[TutorialCompleted alloc] initWithScenario:[Globals sharedInstance].scenario]];
    }

    else if (scenario_id == 1) {
        self.parts = @[
                // present the unit types
                [[TutorialText alloc] initBlockingWithText:@"Your army consists of different types of units that have different tasks on the battle field." atPos:ccp( 700, 500 )],
                [[TutorialText alloc] initBlockingWithText:@"Infantry units form the backbone of your army. They are slow but strong." atPos:ccp( 700, 500 )],

                [[TutorialText alloc] initBlockingWithText:@"Horse mounted cavalry units are fast but weaker. Great for scouting the map!" atPos:ccp( 700, 650 )],

                [[TutorialText alloc] initBlockingWithText:@"Artillery units are very slow but they also deliver the most damage." atPos:ccp( 710, 320 )],
                [[TutorialText alloc] initBlockingWithText:@"You need to protect artillery units from being outflanked or assaulted by enemy units." atPos:ccp( 710, 320 )],

                [[TutorialText alloc] initBlockingWithText:@"Headquarter units are small units that command larger organizations so keep them safe." atPos:ccp( 220, 575 )],
                [[TutorialText alloc] initBlockingWithText:@"There are both infantry and cavalry headquarter units" atPos:ccp( 220, 575 )],

                // click a unit
                [[TutorialText alloc] initWithText:@"To give orders to units tap them to select. Now select the infantry unit to the left." atPos:ccp( 700, 500 )],
                [[TutorialSelectUnit alloc] initWithUnitId:1],

                // show unit info
                [[TutorialText alloc] initBlockingWithText:@"Good. Down here in the panel you can see info about the selected unit." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"Top left is the unit name and to the right is the name of its headquarter." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The current number of men in the unit is shown at the left along with the number of men the unit originally had." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"This unit has no current mission and it is standing on grass." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"Formation means that it is ready for combat while a column mode means that the troops are lined up for fast marching." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The unit is close enough to its headquarter unit and thus is in command." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"If the headquarter name is shown in red the unit is too far from the headquarter, or it has been destroyed." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"This unit is of regular quality. Units can also be green, veteran or elite." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The morale is next to the quality. This unit has great morale and is not about to rout." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"Next is the fatigue. Units get tired when they move and fight. Tired units perform worse than rested." atPos:ccp( 512, 150 )],

                // select the artillery
                [[TutorialText alloc] initWithText:@"Now select your artillery unit." atPos:ccp( 700, 310 )],
                [[TutorialSelectUnit alloc] initWithUnitId:2],

                // guns and field of fire
                [[TutorialText alloc] initBlockingWithText:@"In the unit info you can see that artillery units have guns too. This one has five light cannons." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The artillery unit is too far from its HQ, so the HQ name is in red." atPos:ccp( 512, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The white arc shows the field of fire. The unit can fire at enemies inside this arc without turning." atPos:ccp( 280, 320 )],
                [[TutorialText alloc] initBlockingWithText:@"Artillery units have a narrow arc but can fire further than other units." atPos:ccp( 280, 320 )],

                // change unit
                [[TutorialText alloc] initBlockingWithText:@"The two arrow buttons allow you to quickly change to the next and previous unit." atPos:ccp( 150, 140 )],
                [[TutorialText alloc] initWithText:@"Lets activate the next unit by pressing the button with the right arrow." atPos:ccp( 150, 140 )],
                [[TutorialSelectUnit alloc] initWithUnitId:3],

                // cavaltry and then navigate to the headquarter
                [[TutorialText alloc] initBlockingWithText:@"The next unit is your cavalry unit." atPos:ccp( 700, 650 )],
                [[TutorialText alloc] initBlockingWithText:@"You can use this button to center the map on the selected unit." atPos:ccp( 200, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"The button with the flag activates the headquarter for the selected unit." atPos:ccp( 272, 140 )],
                [[TutorialText alloc] initWithText:@"Now tap the HQ button to change to the headquarter unit." atPos:ccp( 272, 140 )],
                [[TutorialSelectUnit alloc] initWithUnitId:5],

                // headquarter
                [[TutorialText alloc] initBlockingWithText:@"This is a cavalry headquarter unit." atPos:ccp( 260, 520 )],
                [[TutorialText alloc] initBlockingWithText:@"The green lines shows its subordinate units, in this case only one." atPos:ccp( 260, 520 )],
                [[TutorialText alloc] initBlockingWithText:@"The yellow circle shows the headquarter's command radius." atPos:ccp( 260, 520 )],
                [[TutorialText alloc] initBlockingWithText:@"Subordinate units outside this circle are not in command and will suffer penalties for being too far away." atPos:ccp( 260, 520 )],

                // moving
                [[TutorialText alloc] initWithText:@"Lets see how to move units. Select the big cavalry unit again." atPos:ccp( 700, 650 )],
                [[TutorialSelectUnit alloc] initWithUnitId:3],
                [[TutorialText alloc] initBlockingWithText:@"To move a unit press down on it and drag a movement path. When you release your finger are asked for how to move there." atPos:ccp( 250, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"Choose Move from the popup to move normally." atPos:ccp( 250, 400 )],
                [[TutorialText alloc] initWithText:@"It takes a little time before the unit starts to execute the movement order." atPos:ccp( 250, 400 )],
                [[TutorialText alloc] initWithText:@"Now move your cavalry unit to the highlighted circle to the right of it. Drag a path from the unit to the circle." atPos:ccp( 250, 400 )],
                [[TutorialMoveUnit alloc] initWithUnitId:3 toPos:ccp( 680, 530 ) radius:20],
                [[TutorialText alloc] initBlockingWithText:@"Good. Scouting means to move and stop as soon as a new enemy is seen. This can help you avoid traps!" atPos:ccp( 250, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"Retreating is used to fall back from a bad position, the unit will move backwards without turning around." atPos:ccp( 250, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"Advancing and assaulting are for attacking towards enemies." atPos:ccp( 250, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"If you do not want to give the unit any movement order, just tap anywhere outside the mission buttons." atPos:ccp( 250, 400 )],

                // move hq too
                [[TutorialText alloc] initWithText:@"Now move your cavalry headquarter unit to the highlighted position." atPos:ccp( 200, 500 )],
                [[TutorialMoveUnit alloc] initWithUnitId:5 toPos:ccp( 580, 537 ) radius:20],

                // turn
                [[TutorialText alloc] initBlockingWithText:@"Easy! To turn a selected unit just tap anywhere on the map and select Turn from the popup." atPos:ccp( 300, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"The unit will then turn to face the tapped position." atPos:ccp( 300, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"Note that the line drawn to the tapped position also shows the unit's line of sight." atPos:ccp( 300, 400 )],
                [[TutorialText alloc] initBlockingWithText:@"The unit can see as far as the line is green and if it turns red there have been too many obstacles blocking the line of sight." atPos:ccp( 300, 400 )],

                [[TutorialText alloc] initWithText:@"Turn your infantry unit to the left to face straight south." atPos:ccp( 700, 500 )],
                [[TutorialTurnUnit alloc] initWithUnitId:1 toAngle:180 deviation:10],

                // cancel
                [[TutorialText alloc] initBlockingWithText:@"You can cancel a mission at any time by pressing the X button below." atPos:ccp( 752, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"It is however only visible when the unit is executing a mission and is thus not visible now!" atPos:ccp( 752, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"The change mode button changes between formation and column mode. Changing mode takes a bit of time." atPos:ccp( 824, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"Use column mode for quick movement and formation mode when the unit will engage in combat." atPos:ccp( 824, 140 )],

                [[TutorialText alloc] initBlockingWithText:@"Try out line of sight, canceling orders and changing unit modes." atPos:ccp( 700, 500 )],
                [[TutorialText alloc] initWithText:@"When you are done, select 'Quit' from the in game menu to proceed to learning about combat!" atPos:ccp( 220, 700 )],

                // mark it as completed
                [[TutorialCompleted alloc] initWithScenario:[Globals sharedInstance].scenario]];
    }

    else if (scenario_id == 2) {
        self.parts = @[
                // intro
                [[TutorialText alloc] initBlockingWithText:@"In this tutorial we will take a look at combat and objectives." atPos:ccp( 704, 510 )],
                [[TutorialText alloc] initBlockingWithText:@"Objectives are locations on the map that will award the player victory points." atPos:ccp( 704, 510 )],

                [[TutorialText alloc] initBlockingWithText:@"A player holds an objective if the opponent has no units close to the objective." atPos:ccp( 704, 510 )],
                [[TutorialText alloc] initWithText:@"Lets capture the objective below. First select the cavalry unit at the left." atPos:ccp( 704, 510 )],
                [[TutorialSelectUnit alloc] initWithUnitId:3],

                // move to first position
                [[TutorialText alloc] initWithText:@"Move your cavalry unit to the highlighted location. You can use the 'Move fast' mission as it is in column mode." atPos:ccp( 400, 280 )],
                [[TutorialMoveUnit alloc] initWithUnitId:3 toPos:ccp( 400, 350 ) radius:20],

                // change to formation
                [[TutorialText alloc] initBlockingWithText:@"Your cavalry is curently in column mode, but formation mode is used when in combat." atPos:ccp( 400, 280 )],
                [[TutorialText alloc] initBlockingWithText:@"Column mode allows for fast movement and is useful when moving long distances." atPos:ccp( 400, 280 )],
                [[TutorialText alloc] initBlockingWithText:@"Units can however not fight while in column mode, so make sure to change before the action starts." atPos:ccp( 400, 280 )],
                [[TutorialText alloc] initBlockingWithText:@"For this tutorial changing mode will be fast, but in real battles it takes much longer." atPos:ccp( 400, 280 )],
                [[TutorialText alloc] initWithText:@"Now tap the change mode button with two arrows below to change to formation mode." atPos:ccp( 824, 140 )],
                [[TutorialChangeMode alloc] initWithUnitId:3 toMode:kFormation],

                [[TutorialText alloc] initWithText:@"Now give a 'Scout' mission to your cavalry unit to carefully move forward to the given position." atPos:ccp( 210, 450 )],
                [[TutorialMoveUnit alloc] initWithUnitId:3 toPos:ccp( 600, 340 ) radius:20 orEnemySeen:YES],

                // enemy found
                [[TutorialText alloc] initBlockingWithText:@"You spotted a new enemy unit! Scouting units stop moving when they spot a previously unseen enemy." atPos:ccp( 700, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"In this tutorial enemy units are dummies and will not fire back." atPos:ccp( 700, 150 )],
                [[TutorialText alloc] initBlockingWithText:@"The enemy unit is just outside your cavalry unit's firing range." atPos:ccp( 700, 150 )],

                // select enemy
                [[TutorialText alloc] initBlockingWithText:@"You can view some basic information about enemy units." atPos:ccp( 700, 150 )],
                [[TutorialText alloc] initWithText:@"Now tap your own unit to deselect it and then select the enemy unit by tapping it." atPos:ccp( 700, 150 )],
                [[TutorialSelectUnit alloc] initWithUnitId:1],

                // move closer and destroy it
                [[TutorialText alloc] initBlockingWithText:@"Only some information is shown for enemy units and the number of men is an approximation." atPos:ccp( 512, 140 )],
                [[TutorialText alloc] initWithText:@"Now select your cavalry unit again." atPos:ccp( 440, 520 )],
                [[TutorialSelectUnit alloc] initWithUnitId:3],
                [[TutorialText alloc] initWithText:@"Move a bit closer and then your unit will automatically target the enemy unit." atPos:ccp( 440, 520 )],
                [[TutorialMoveUnit alloc] initWithUnitId:3 toPos:ccp( 590, 300 ) radius:20],
                [[TutorialText alloc] initBlockingWithText:@"Your unit will now fire as fast as it can. In this tutorial the firing rate is faster than normal to speed things up." atPos:ccp( 440, 520 )],
                [[TutorialWaitDestroyed alloc] initWithUnitId:1],
                [[TutorialText alloc] initBlockingWithText:@"You have destroyed your first enemy unit! Lets take a look at the other combat options." atPos:ccp( 440, 520 )],

                // other combat
                [[TutorialText alloc] initBlockingWithText:@"Firing is easy and mostly automatic, your unit does not move anywhere, it simply fires at an enemy in range." atPos:ccp( 400, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"You can of course fire at any other unit in range too, just tap it and select 'Fire'." atPos:ccp( 400, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Advancing will move your unit towards the enemy while firing a volley every now and then." atPos:ccp( 400, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Assaulting is an all out assault towards the enemy in order to engage in close combat." atPos:ccp( 400, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"A melee takes place when two units are next to each other and is normally fatal to one of the units." atPos:ccp( 400, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Artillery units can fire smoke that creates a smoke barrier, useful when advancing over open areas." atPos:ccp(  400, 200 )],
                [[TutorialText alloc] initBlockingWithText:@"Area fire can be used to fire at a specific map position, for instance to create an ambush." atPos:ccp(  400, 200 )],

                // hold fire
                [[TutorialText alloc] initBlockingWithText:@"Units use ammunition each time they fire. The ammo status is shown in the unit info." atPos:ccp( 450, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"If the ammo runs low the unit can still fire but with greatly reduced firepower." atPos:ccp( 450, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"To save ammo tap the 'Hold Fire' button below to stop a unit from automatically firing at enemies." atPos:ccp( 880, 140 )],
                [[TutorialText alloc] initBlockingWithText:@"You can allow fire for instance when enemies are closer and the firing is more efficient." atPos:ccp( 880, 140 )],

                // capture objective
                [[TutorialText alloc] initBlockingWithText:@"Now lets move the cavalry unit and capture the objective." atPos:ccp( 830, 580 )],
                [[TutorialText alloc] initWithText:@"Notice how the objective changes color once the cavalry unit gets close enough to capture it." atPos:ccp( 830, 580 )],
                [[TutorialMoveUnit alloc] initWithUnitId:3 toPos:ccp( 707, 318 ) radius:20],

                // forward and destroy the other unit
                [[TutorialText alloc] initBlockingWithText:@"Another enemy seems to be positioned in the north." atPos:ccp( 480, 660 )],
                [[TutorialText alloc] initWithText:@"Assault the enemy unit! Drag a path to the enemy and select 'Assault' from the popup." atPos:ccp( 480, 318 )],
                [[TutorialWaitDestroyed alloc] initWithUnitId:0],

                [[TutorialText alloc] initBlockingWithText:@"After a melee all surviving units will be disorganized while they reorganize into a coherent formation." atPos:ccp( 480, 550 )],
                [[TutorialText alloc] initBlockingWithText:@"The enemy did not really fight back in this tutorial." atPos:ccp( 480, 550 )],
                [[TutorialText alloc] initBlockingWithText:@"Normally the game ends when either side has suffered too big losses or when the game time runs out." atPos:ccp( 480, 550 )],
                [[TutorialText alloc] initBlockingWithText:@"This concludes the tutorial series. You are now certified to lead your troops in battle." atPos:ccp( 512, 300 )],
                [[TutorialText alloc] initBlockingWithText:@"The complete manual is always accessible from the main menu or from the in game menu." atPos:ccp( 512, 300 )],
                [[TutorialText alloc] initBlockingWithText:@"The question mark in the lower right can be used to show some user interface help." atPos:ccp( 512, 300 )],
                [[TutorialText alloc] initWithText:@"Select 'Quit' from the in game menu to complete your tutorials and get prepared for front line action." atPos:ccp( 220, 700 )],

                // mark it as completed
                [[TutorialCompleted alloc] initWithScenario:[Globals sharedInstance].scenario]];
    }

    // no shown yet
    self.shownParts = [NSMutableArray array];

    currentIndex = 0;
}

@end
