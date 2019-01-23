
#import <Crashlytics/Answers.h>

#import "CCBReader.h"

#import "EditArmy.h"
#import "Globals.h"
#import "Utils.h"
#import "SelectArmy.h"
#import "UnitDefinition.h"
#import "Army.h"

@interface UnitData : NSObject

@property (nonatomic, strong) UnitDefinition *unitDef;
@property (nonatomic, assign) int bought;

- (instancetype) initWithNDefinition:(UnitDefinitionType)unitDef;

@end

@implementation UnitData

- (instancetype) initWithNDefinition:(UnitDefinitionType)unitDef {
    self = [super init];
    if (self) {
        self.unitDef = [[UnitDefinition alloc] initWithType:unitDef];
        self.bought = 0;
    }

    return self;
}

@end


@interface EditArmy ()

@property (nonatomic, assign) int credits;
@property (nonatomic, strong) NSArray *infantryUnitData;
@property (nonatomic, strong) NSArray *artilleryUnitData;
@property (nonatomic, strong) NSArray *supportUnitData;
@property (nonatomic, strong) NSArray *currentForces;
@property (nonatomic, strong) NSArray *allForces;
@end


@implementation EditArmy

@synthesize backButton;
@synthesize infantryButton;
@synthesize artilleryButton;
@synthesize supportButton;
@synthesize messagePaper;
@synthesize buttonsPaper;
@synthesize forcesPaper;
@synthesize baseForcesNode;
@synthesize creditsLabel;
@synthesize forcesMenu;
@synthesize unitCountLabel;

+ (CCScene *) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"EditArmy.ccb"];
}


- (void) didLoadFromCCB {
    self.credits = 1000;

    self.infantryUnitData = @[
            [[UnitData alloc] initWithNDefinition:kInfantryBattalionDef],
            [[UnitData alloc] initWithNDefinition:kAssaultInfantryBattalionDef],
            [[UnitData alloc] initWithNDefinition:kCavalryBattalionDef],
            [[UnitData alloc] initWithNDefinition:kInfantryCompanyDef],
            [[UnitData alloc] initWithNDefinition:kAssaultInfantryCompanyDef],
            [[UnitData alloc] initWithNDefinition:kCavalryCompanyDef]];

    self.artilleryUnitData = @[
            [[UnitData alloc] initWithNDefinition:kLightArtilleryBattalionDef],
            [[UnitData alloc] initWithNDefinition:kHeavyArtilleryBattalionDef],
            [[UnitData alloc] initWithNDefinition:kHowitzerArtilleryBattalionDef],
            [[UnitData alloc] initWithNDefinition:kLightArtilleryBatteryDef],
            [[UnitData alloc] initWithNDefinition:kHeavyArtilleryBatteryDef],
            [[UnitData alloc] initWithNDefinition:kHowitzerArtilleryBatteryDef]];

    self.supportUnitData = @[
            [[UnitData alloc] initWithNDefinition:kSupportCompanyDef],
            [[UnitData alloc] initWithNDefinition:kMachineGunTeamDef],
            [[UnitData alloc] initWithNDefinition:kSniperTeamDef],
            [[UnitData alloc] initWithNDefinition:kMortarTeamDef],
            [[UnitData alloc] initWithNDefinition:kFlamethrowerTeamDef]];

    NSMutableArray *all = [NSMutableArray new];
    [all addObjectsFromArray:self.infantryUnitData];
    [all addObjectsFromArray:self.artilleryUnitData];
    [all addObjectsFromArray:self.supportUnitData];
    self.allForces = all;

    // base forces shown
    self.currentForces = self.infantryUnitData;

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
    [self createText:@"Standard" forButton:self.infantryButton];
    [self createText:@"Artillery" forButton:self.artilleryButton];
    [self createText:@"Support" forButton:self.supportButton];

    // set the title for all the add and remove buttons
    CCMenuItemImage *button;
    for (int index = 0; index < 11; ++index) {
        button = (CCMenuItemImage *) [self.forcesMenu getChildByTag:100 + index];
        [Utils createText:@"Add" withYOffset:0 forButton:button withFont:@"ButtonFontSmall.fnt" includeDisabled:NO];

        button = (CCMenuItemImage *) [self.forcesMenu getChildByTag:200 + index];
        [Utils createText:@"Remove" withYOffset:0 forButton:button withFont:@"ButtonFontSmall.fnt" includeDisabled:NO];
    }

    // add in the units from the current army
    for (UnitDefinition *unitDef in [Globals sharedInstance].currentArmy.unitDefinitions) {
        // find the unit data for the unit type
        for (UnitData *data in self.allForces) {
            if (data.unitDef.type == unitDef.type) {
                data.bought += 1;
                self.credits -= data.unitDef.cost;
                break;
            }
        }
    }

    // update the scredits
    [self.creditsLabel setString:[NSString stringWithFormat:@"%d", self.credits]];

    // now show the current forces
    [self showCurrentForces];
    [self updateUnitCount];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];

    // analytics
    [Answers logCustomEventWithName:@"Edit army"
                   customAttributes:@{} ];
}


//- (void) dealloc {
//    CCLOG( @"in" );
//}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.messagePaper.position = ccp( -200, 800 );
    self.messagePaper.rotation = 30;
    self.messagePaper.scale = 2.0f;

    self.buttonsPaper.position = ccp( 100, -200 );
    self.buttonsPaper.rotation = -30;
    self.buttonsPaper.scale = 2.0f;

    self.forcesPaper.position = ccp( 1300, 300 );
    self.forcesPaper.rotation = -20;
    self.forcesPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.messagePaper toPos:ccp( 170, 480 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.messagePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.messagePaper toAngle:-1 inTime:0.5f atRate:0.5f];

    [self moveNode:self.buttonsPaper toPos:ccp( 215, 235 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.buttonsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.buttonsPaper toAngle:-3 inTime:0.5f atRate:1.5f];

    [self moveNode:self.forcesPaper toPos:ccp( 700, 310 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.forcesPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.forcesPaper toAngle:2 inTime:0.5f atRate:1.5f];

    // these can be animated
    [self addAnimatableNode:self.messagePaper];
    [self addAnimatableNode:self.buttonsPaper];
    [self addAnimatableNode:self.forcesPaper];
}


- (void) showInfantry {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // base forces shown
    self.currentForces = self.infantryUnitData;
    [self showCurrentForces];
}


- (void) showArtillery {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // artillery forces shown
    self.currentForces = self.artilleryUnitData;
    [self showCurrentForces];
}


- (void) showSupport {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // support forces shown
    self.currentForces = self.supportUnitData;
    [self showCurrentForces];
}


- (void) back {
    Globals *globals = [Globals sharedInstance];

    // disable back button
    [self disableBackButton:self.backButton];

    [globals.audio playSound:kMenuButtonClicked];

    // clear the current unit definitions
    Army *currentArmy = globals.currentArmy;
    [currentArmy.unitDefinitions removeAllObjects];

    for (UnitData *data in self.allForces) {
        for (int index = 0; index < data.bought; ++index) {
            [currentArmy.unitDefinitions addObject:[[UnitDefinition alloc] initWithType:data.unitDef.type]];
        }
    }

    CCLOG( @"current army: %@", currentArmy );

    // save all armies
    [Army saveArmies];

    [self animateNodesAwayAndShowScene:[SelectArmy node]];
}


- (void) add:(id)sender {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    CCMenuItemImage *button = (CCMenuItemImage *) sender;

    int index = (int) button.tag - 100;

    NSAssert( index < self.currentForces.count, @"add button tag out of range!" );

    UnitData *data = self.currentForces[index];

    // what does this cost?
    int cost = data.unitDef.cost;

    // can we afford it?
    if (cost <= self.credits) {
        // yes, buy it
        self.credits -= cost;
        data.bought += 1;

        // set the label too
        CCLabelBMFont *countLabel = (CCLabelBMFont *) [self.baseForcesNode getChildByTag:index];
        [countLabel setString:[NSString stringWithFormat:@"%d", data.bought]];

        // update the scredits
        [self.creditsLabel setString:[NSString stringWithFormat:@"%d", self.credits]];
    }

    [self updateUnitCount];
}


- (void) remove:(id)sender {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    CCMenuItemImage *button = (CCMenuItemImage *) sender;

    int index = (int) button.tag - 200;

    NSAssert( index < self.currentForces.count, @"add button tag out of range!" );

    UnitData *data = self.currentForces[index];

    // can we remove anything?
    if (data.bought > 0) {
        data.bought -= 1;

        // return cost
        self.credits += data.unitDef.cost;

        // update the scredits
        [self.creditsLabel setString:[NSString stringWithFormat:@"%d", self.credits]];

        // set the label too
        CCLabelBMFont *countLabel = (CCLabelBMFont *) [self.baseForcesNode getChildByTag:index];
        [countLabel setString:[NSString stringWithFormat:@"%d", data.bought]];
    }

    [self updateUnitCount];
}


- (void) showCurrentForces {
    CCLabelBMFont *label;

    int index = 0;
    for (UnitData *data in self.currentForces) {
        // count
        label = (CCLabelBMFont *) [self.baseForcesNode getChildByTag:index];
        [label setString:[NSString stringWithFormat:@"%d", data.bought]];
        label.visible = YES;

        // name
        label = (CCLabelBMFont *) [self.baseForcesNode getChildByTag:300 + index];
        [label setString:data.unitDef.name];
        label.visible = YES;

        // contents
        label = (CCLabelBMFont *) [self.baseForcesNode getChildByTag:500 + index];
        [label setString:data.unitDef.desc];
        label.visible = YES;

        // cost
        label = (CCLabelBMFont *) [self.baseForcesNode getChildByTag:400 + index];
        [label setString:[NSString stringWithFormat:@"%d", data.unitDef.cost]];
        label.visible = YES;

        // show the add/remove buttons
        [self.forcesMenu getChildByTag:100 + index].visible = YES;
        [self.forcesMenu getChildByTag:200 + index].visible = YES;

        index++;
    }

    // hide all other labels and buttons
    while (index < 6) {
        [self.baseForcesNode getChildByTag:index].visible = NO;
        [self.baseForcesNode getChildByTag:300 + index].visible = NO;
        [self.baseForcesNode getChildByTag:400 + index].visible = NO;
        [self.baseForcesNode getChildByTag:500 + index].visible = NO;
        [self.forcesMenu getChildByTag:100 + index].visible = NO;
        [self.forcesMenu getChildByTag:200 + index].visible = NO;
        index++;
    }
}


- (void) updateUnitCount {
    int count = 0;

    // add in the sizes for all selected formations
    for (UnitData *data in self.allForces) {
        count += data.bought * data.unitDef.units.count;
    }

    [self.unitCountLabel setString:[NSString stringWithFormat:@"%d", count]];
}


@end
