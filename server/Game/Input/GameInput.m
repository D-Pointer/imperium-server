
#import "GameInput.h"
#import "Globals.h"
#import "MapLayer.h"
#import "Objective.h"
#import "TerrainModifiers.h"
#import "Path.h"
#import "PathFinder.h"
#import "Debugging.h"

@interface GameInput ()

@property (nonatomic, strong) Path *           dragPath;
@property (nonatomic, strong) NSMutableArray * pathNodes;
@end


@implementation GameInput

- (id) init {
    self = [super init];
    if (self) {
        self.dragPath = nil;
        self.pathNodes = nil;
    }

    return self;
}


- (void) dealloc {
    [self clearPathNodes];
}


- (void) handleClickedUnit:(Unit *)clicked {
    Globals * globals = [Globals sharedInstance];

    Unit * selected_unit = globals.selection.selectedUnit;

    if ( clicked == selected_unit ) {
        // yes, then toggle selection
        [globals.audio playSound:kUnitDeselected];
        globals.selection.selectedUnit = nil;
        return;
    }

    // clicked an enemy unit while have own selected?
    if ( selected_unit && selected_unit.owner == globals.localPlayer.playerId && clicked.owner != globals.localPlayer.playerId ) {
        // enemy unit clicked
        [globals.audio playSound:kEnemyUnitSelected];
        [globals.actionsMenu enemyClicked:clicked];
    }
    else {
        // clicked an own unit, see if the actions menu can handle it
        [globals.audio playSound:kUnitSelected];
        if ( ! [globals.actionsMenu ownUnitClicked:clicked] ) {
            // not handled make it the new selected unit
            globals.selection.selectedUnit = clicked;
        }
    }
}


- (void) handleClickedObjective:(Objective *)objective {
    // if we have a unit selected then we instead see it as if the position was clicked so that movement can
    // take place normally
    Unit * selected_unit = [Globals sharedInstance].selection.selectedUnit;
    if ( selected_unit && selected_unit.owner == [Globals sharedInstance].localPlayer.playerId ) {
        [self handleClickedPos:objective.position];
        return;
    }
}


- (void) handleClickedPos:(CGPoint)pos {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;

    if ( selectedUnit == nil ) {
        // no selected unit, nothing to do here
        return;
    }

    if ( selectedUnit.owner != [Globals sharedInstance].localPlayer.playerId ) {
        // enemy is selected and terrain clicked, deselect it
        [Globals sharedInstance].selection.selectedUnit = nil;
        [[Globals sharedInstance].audio playSound:kUnitDeselected];
        return;
    }

    // play a sound too
    [[Globals sharedInstance].audio playSound:kMapClicked];

    ActionsMenu * actionsMenu = [Globals sharedInstance].actionsMenu;

    // is the actionsmenu already visible? if so we just hide it
    if ( actionsMenu.visible ) {
        [actionsMenu hide];
    }
    else {
        // an own unit is selected and no old actions menu, show it
        [[Globals sharedInstance].actionsMenu mapClicked:pos];
    }

    // DEBUG: test path finder
    //[[Globals sharedInstance].pathFinder findPathFrom:selectedUnit.position to:pos forUnit:selectedUnit];

    // DEBUG: test line tracing
    //[Debugging showLineFrom:selectedUnit.position to:pos];
}


- (void) handleDragStartForUnit:(Unit *)unit {
    self.dragPath = [Path new];

    // precautions
    [self clearPathNodes];

    self.pathNodes = [NSMutableArray new];
}


- (BOOL) handleDragForUnit:(Unit *)unit toPos:(CGPoint)pos {
    Unit * selectedUnit = [Globals sharedInstance].selection.selectedUnit;;

    NSAssert( selectedUnit, @"no selected unit" );
    NSAssert( self.dragPath, @"invalid drag path" );

    // what terrain type at the given position?
    TerrainType terrainType = [[Globals sharedInstance].mapLayer getTerrainAt:pos];

    // terrain modifier
    if ( getTerrainMovementModifier( selectedUnit, terrainType ) < 0 ) {
        // the unit can not enter the terrain, allow only a few actions
        [[Globals sharedInstance].audio playSound:kUnitNoActions];

        // get rid of all path nodes
        [self clearPathNodes];
        return NO;
    }

    // last handled position or the unit's current one if no positions yet have been set
    CGPoint lastPos;
    if ( self.dragPath.count > 0 ) {
        lastPos = [[self.dragPath.positions lastObject] CGPointValue];
    }
    else {
        lastPos = unit.position;
    }

    // how far is it?
    if ( ccpDistance( lastPos, pos ) > 10 ) {
        // travelled far enough
        [self.dragPath addPosition:pos];

        // create a path node sprite
        CCSprite * pathNode = [CCSprite spriteWithSpriteFrameName:@"PathNode.png"];
        pathNode.position = pos;
        [[Globals sharedInstance].mapLayer addChild:pathNode z:kPathNodeZ];
        [self.pathNodes addObject:pathNode];

        CCLOG( @"added %.0f, %.0f, positions now: %lu", pos.x, pos.y, (unsigned long)self.dragPath.count );

        // how long is the path now? we only allow 1000 m long paths
        float length = self.dragPath.length;
        if ( length > sParameters[kParamMaxPathLengthF].floatValue ) {
            CCLOG( @"drag path length (%.0f) has exceeded the max length of 1000, stopping path", length );
            [[Globals sharedInstance].audio playSound:kUnitNoActions];

            // create a path that far
            [self createPathForUnit:unit];
            return NO;
        }
    }

    // go on with dragging
    return YES;
}


- (void) handleDragEndForUnit:(Unit *)unit {
    NSAssert( self.dragPath, @"invalid drag path" );

    [self createPathForUnit:unit];
}


- (void) createPathForUnit:(Unit *)unit {
    CCLOG( @"drag positions: %lu", (unsigned long)self.dragPath.count );

    if ( self.dragPath.count > 10 ) {
        // remove some positions from the path to avoid the initial jerks that happen when starting a drag
        [self.dragPath removeFirstPosition];
        [self.dragPath removeFirstPosition];
    }

    // enough positions?
    if ( self.dragPath.count >= 2 ) {
        // update the final facing for the drag path
        [self.dragPath updateFinalFacing];

        // get the last node and give it a different sprite to show it's the last node in the path
        CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
        [[self.pathNodes lastObject] setDisplayFrame:[cache spriteFrameByName:@"PathNodeLast.png"]];

        // allow the player to choose what should be done
        [[Globals sharedInstance].actionsMenu path:self.dragPath createdTo:[[self.dragPath.positions lastObject] CGPointValue] withNodes:self.pathNodes];
    }
    else {
        // too few path nodes, so get rid of our old ones
        [self clearPathNodes];
    }

    // here we lose the path nodes
    self.pathNodes = nil;
    self.dragPath = nil;
}


- (void) clearPathNodes {
    if ( self.pathNodes ) {
        for ( CCSprite * point in self.pathNodes ) {
            [point removeFromParentAndCleanup:YES];
        }

        self.pathNodes = nil;
    }
}

@end
