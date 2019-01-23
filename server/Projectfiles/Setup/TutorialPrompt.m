
#import "CCBReader.h"
#import "Flurry.h"

#import "TutorialPrompt.h"
#import "Globals.h"
#import "SelectScenario.h"
#import "GameCenter.h"
#import "GameSerializer.h"
#import "ResumeGame.h"

@implementation TutorialPrompt

+ (id) node {
    TutorialPrompt * node = (TutorialPrompt *)[CCBReader nodeGraphFromFile:@"TutorialPrompt.ccb"];
    
    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    // TODO
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    
    [[CCDirector sharedDirector] popScene];     
}


- (void) tutorial {
    [Flurry logEvent:@"Tutorial prompt - start tutorial"];

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    
    // single player game
    [Globals sharedInstance].gameType = kSinglePlayerGame;
    
    [[CCDirector sharedDirector] replaceScene:[SelectScenario tutorialNode]]; 
}


- (void) play {
    [Flurry logEvent:@"Tutorial prompt - ignore tutorial"];

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    
    if ( [Globals sharedInstance].gameType == kSinglePlayerGame ) {
        // do we still have a resumeable game?
        if ( [GameSerializer hasSavedGame:SaveFileNameSingle] ) {
            // make sure the player knows what he/she is doing and ask
            [[CCDirector sharedDirector] replaceScene:[ResumeGame singleNode]];   
        }
        else {
            [[CCDirector sharedDirector] replaceScene:[SelectScenario singleNode]]; 
        }
        
    }
    
    else if ( [Globals sharedInstance].gameType == kMultiplayerGame ) {
        // do we still have a resumeable game?
        if ( [GameSerializer hasSavedGame:SaveFileNameMulti] ) {
            // make sure the player knows what he/she is doing and ask
            [[CCDirector sharedDirector] replaceScene:[ResumeGame multiNode]];   
        }
        else {
            [[CCDirector sharedDirector] replaceScene:[SelectScenario multiNode]]; 
        }
        
    }
    
    else {
        // online
        [[Globals sharedInstance].gameCenter findMatch];
        
        // get rid of ourselves
        [[CCDirector sharedDirector] popScene];
    }
}


@end
