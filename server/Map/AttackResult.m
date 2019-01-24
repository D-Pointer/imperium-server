
#import "AttackResult.h"
#import "Globals.h"
#import "GameLayer.h"

@interface AttackResult ()

@property (nonatomic, strong) CCLabelBMFont *   label;
@property (nonatomic, strong) CCSprite *        background;

@end


@implementation AttackResult

- (id) initWithMessage:(AttackMessageType)message
          withAttacker:(Unit *)attacker
             forTarget:(Unit *)target
            casualties:(int)casualties
           routMission:(RoutMission *)routMission
    targetMoraleChange:(float)targetMoraleChange
  attackerMoraleChange:(float)attackerMoraleChange {
    self = [super init];
    if (self) {
        self.attacker = attacker;
        self.target = target;
        self.casualties = casualties;
        self.messageType = message;
        self.routMission = routMission;
        self.targetMoraleChange = targetMoraleChange;
        self.attackerMoraleChange = attackerMoraleChange;
    }

    return self;
}


- (void) execute {
    // first deliver casualties
    if ( self.target.men < self.casualties ) {
        self.target.men = 0;
    }
    else {
        self.target.men -= self.casualties;
    }
    
    CCLOG( @"%@ lost %d men, now %d left, destroyed: %@", self.target, self.casualties, self.target.men, (self.messageType & kDefenderDestroyed ? @"yes" : @"no") );

    // deliver morale changes
    self.target.morale   -= self.targetMoraleChange;
    self.attacker.morale += self.attackerMoraleChange;

    // does the target already have an attack result?
    if ( self.target.attackResult ) {
        AttackResult * old = self.target.attackResult;

        // yes, old result exists, add the old result to our data
        self.casualties += old.casualties;
        self.messageType |= old.messageType;

        // get rid of the old result
        [old removeFromParentAndCleanup:YES];
        self.target.attackResult = nil;
    }

    // add in some bodies
    [[Globals sharedInstance].mapLayer addBodies:self.casualties around:self.target];

    if ( self.routMission ) { // && [Globals sharedInstance].gameType == kSinglePlayerGame ) {
        // if the target routs then that's the target's new mission. this gets set for multiplayer games too so that
        // the unit has routed immediately, and doesn't have to wait until the fire packet has been sent to the other
        // player and a misison packet sent back with the rout mission
        self.target.mission = self.routMission;
    }

    // get rid of the mission from here
    self.routMission = nil;

    // assemble a message string from the type and bits of data
    NSString * text = @"";

    // the possible first line of text
    if ( self.messageType & kDefenderOutflanked ) {
        text = @"Flank attack!\n";
    }

    else if ( self.messageType & kMeleeAttack ) {
        text = @"Melee!\n";
    }

    // destroyed outright?
    if ( self.messageType & kDefenderDestroyed ) {
        [[Globals sharedInstance].audio playSound:kUnitDestroyed];
        text = @"Destroyed!";
    }

    // lost men?
//    if ( (self.messageType & kDefenderLostMen) && self.casualties > 0 ) {
//        //text = [text stringByAppendingFormat:@"%d killed", self.casualties];
//    }

    // routs too?
    if ( self.messageType & kDefenderRouted ) {
        if ( [text isEqualToString:@""] ) {
            text = @"Routed!";
        }
        else {
            text = [text stringByAppendingString:@"\nRouted!"];
        }
    }

    // if we got no message then make sure nothing get shown
    if ( [text isEqualToString:@""] ) {
        // no text to show, so we're done here
        CCLOG( @"no text to show, we're done" );
        return;
    }

    // we have text to show, so save in the target, we need to stay alive while the actions below are shown
    self.target.attackResult = self;

    // first under the label a background
    self.background = [CCSprite spriteWithSpriteFrameName:@"TextBackground.png"];
    self.background.anchorPoint = ccp( 0.5, 0.5 );
    [self addChild:self.background];

    // then the text, use a small y offset to get it centered
    self.label = [CCLabelBMFont labelWithString:text fntFile:self.target.owner == kPlayer1 ? @"CombatMessageFont1.fnt" : @"CombatMessageFont2.fnt" ];
    self.label.anchorPoint = ccp( 0.5, 0.5 );
    self.label.position = ccp( 0, -2 );
    [self addChild:self.label];

    // scale the background suitably
    float scale_x = ( self.label.boundingBox.size.width + 10 ) / self.background.boundingBox.size.width;
    float scale_y = ( self.label.boundingBox.size.height + 6 ) / self.background.boundingBox.size.height;
    self.background.scaleX = scale_x;
    self.background.scaleY = scale_y;

    // the size of the panel
    float width = self.background.boundingBox.size.width;
    float height = self.background.boundingBox.size.height;

    CGPoint defenderPos = self.target.position;

    // size of the defender's sprite. we use the width as it's wider and the unit may be rotated too
    float defenderSize = self.target.boundingBox.size.width / 2;

    // visible map rect
    CGRect mapRect = [Globals sharedInstance].gameLayer.visibleMapRect;

    // is the target inside the visible map rect? if so we use the whole map rect as the visible rect and make sure
    // that the label gets positioned right near the target. this means that it will not be placed near any edge or
    // similar
    if ( ! CGRectContainsPoint( mapRect, defenderPos ) ) {
        mapRect = CGRectMake( 0, 0, [Globals sharedInstance].mapLayer.mapWidth, [Globals sharedInstance].mapLayer.mapHeight );
    }

    CGPoint result;

    // margin to the top or bottom of the visible map area
    float yMargin = 10;

    if ( self.attacker.position.x < defenderPos.x ) {
        // try to put the menu to the right
        if ( defenderPos.x + defenderSize + width > mapRect.origin.x + mapRect.size.width ) {
            // to the right would be outside
            //result = CGPointMake( -defenderSize - width / 2, 0 );
            result = CGPointMake( defenderPos.x - defenderSize - width / 2, defenderPos.y );
        }
        else {
            // fits to the right
            //result = CGPointMake( defenderSize + width / 2, 0 );
            result = CGPointMake( defenderPos.x + defenderSize + width / 2, defenderPos.y );
        }
    }
    else {
        // try to put the menu to the left
        if ( defenderPos.x - defenderSize - width < mapRect.origin.x ) {
            // to the left would be outside
            //result = CGPointMake( defenderSize + width / 2, 0 );
            result = CGPointMake( defenderPos.x + defenderSize + width / 2, defenderPos.y );
        }
        else {
            // fits to the left
            result = CGPointMake( defenderPos.x - defenderSize - width / 2, defenderPos.y );
            //result = CGPointMake( -defenderSize - width / 2, 0 );
        }
    }

    // too high up or too low down?
    if ( result.y + height / 2 + yMargin > mapRect.origin.y + mapRect.size.height ) {
        result.y = (mapRect.origin.y + mapRect.size.height) - height / 2 - yMargin;
    }
    else if ( result.y - ( height / 2 + yMargin ) < 0 ) {
        result.y = height / 2 + yMargin;
    }

    // position the elements according to what we found out
    self.position = result;

    [[Globals sharedInstance].mapLayer addChild:self z:kCombatReportZ];

    // set a suitable scale as the map layer may be scaled and we want the results to always have the same size
    self.scale = 1.0f / [Globals sharedInstance].mapLayer.scale;

    // show the label and background some seconds, fade out and then remove. Note that the removal is done by the background
    [self.label runAction:[CCSequence actions:
                           [CCDelayTime actionWithDuration:5.0f],
                           [CCFadeOut actionWithDuration:0.3f],
                           nil] ];

    [self.background runAction:[CCSequence actions:
                                [CCDelayTime actionWithDuration:5.0f],
                                [CCFadeOut actionWithDuration:0.4f],
                                [CCCallFuncN actionWithTarget:self
                                                     selector:@selector(resultDone)],
                                nil] ];
}


- (void) resultDone {
    // no longer a result for the target
    self.target.attackResult = nil;

    // get rid of ourselves
    if ( self.parent ) {
        [self removeFromParentAndCleanup:YES];
    }
}

@end
