
#import "Objective.h"
#import "Globals.h"
#import "Unit.h"
#import "Utils.h"
#import "MapLayer.h"

@i
@implementation Objective

- (NSString *) description {
    return [NSString stringWithFormat:@"[Objective %@]", self.title];
}


- (BOOL) isHit:(CGPoint)pos {
    return ccpDistance( self.position, pos ) < sParameters[kParamObjectiveRadiusF].floatValue;
}


+ (void) updateOwnerForAllObjectives {
    // all units
     NSMutableArray * units = [Globals sharedInstance].units;

    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        BOOL near[2] = { NO, NO };

        // check all units
        for ( Unit * unit in units ) {
            // destroyed units don't count...
            if ( unit.destroyed ) {
                continue;
            }
            
            // don't check if we already have one unit for that player that is close enough
            if ( near[ unit.owner ] == YES ) {
                continue;
            }

            float distance = ccpDistance( unit.position, objective.position );

            // is the unit within range to capture the objective?
            if ( distance < sParameters[kParamObjectiveMaxDistanceF].floatValue ) {
                near[ unit.owner ] = YES;
            }
        }

        // it's contested if both are near it
        if ( near[ kPlayer1 ] && near[ kPlayer2 ] ) {
            // contested
            objective.state = kContested;
            CCLOG( @"%@ contested", objective.title );
        }
        else if ( near[ kPlayer1 ] ) {
            objective.state = kOwnerPlayer1;
            CCLOG( @"%@ owned by player 1", objective.title );
        }
        else if ( near[ kPlayer2 ] ) {
            objective.state = kOwnerPlayer2;
            CCLOG( @"%@ owned by player 2", objective.title );
        }
        else {
            // neutral
            objective.state = kNeutral;
            CCLOG( @"%@ neutral", objective.title );
        }
    }
}


- (void) setTitle:(NSString *)title {
    _title = title;

    if ( self.titleLabel != nil ) {
        [self.titleLabel removeFromParent];
        self.titleLabel = nil;
    }

    // show the objective title under the sprite
    self.titleLabel = [CCLabelBMFont labelWithString:@"" fntFile:@"ObjectiveNameFont.fnt"];
    [Utils showString:self.title onLabel:self.titleLabel withMaxLength:100];
    self.titleLabel.anchorPoint = ccp( 0.5, 0.5 );

    // this requires that the position is set before the title
    self.titleLabel.position = ccp( self.position.x, self.position.y - 30 );
    [[Globals sharedInstance].mapLayer addChild:self.titleLabel z:kObjectiveTitleZ];
}


+ (Objective *) create {
    Objective * objective = [Objective spriteWithSpriteFrameName:@"ObjectiveNeutral.png"];
    objective.objectiveId = -1;
    objective.state = kNeutral;

    return objective;
}

@end
