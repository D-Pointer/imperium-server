#import <GameKit/GameKit.h>
#import "GameCenter.h"
#import "Globals.h"


@implementation GameCenter

- (id) initWithDelegate:(id <GameCenterDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        //self.friends = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( localPlayerAuthenticationChanged ) name:GKPlayerAuthenticationDidChangeNotificationName object:nil];
    }

    return self;
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) authenticateLocalPlayer {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        if ([GKLocalPlayer localPlayer].isAuthenticated) {
            CCLOG( @"player authenticated, Game Center ok" );
        }

        else if (viewController) {
            // show view controller
            UIViewController *vc = [Globals sharedInstance].appDelegate.navController;
            [vc presentViewController:viewController animated:YES completion:nil];
        }

        else {
            CCLOG( @"Game Center disabled" );
        }
    };
}


- (void) localPlayerAuthenticationChanged {
    CCLOG( @"authenticated: %@", [GKLocalPlayer localPlayer].isAuthenticated ? @"yes" : @"no" );
    if ([GKLocalPlayer localPlayer].isAuthenticated) {
        if ([self.delegate respondsToSelector:@selector( playerAuthenticated: )]) {
            [self.delegate playerAuthenticated:[GKLocalPlayer localPlayer].alias];
        }
    }

//    if ( self.isAuthenticated ) {
//        [self retrieveFriends];
//    }
}


- (BOOL) isAuthenticated {
    return [GKLocalPlayer localPlayer].isAuthenticated;
}


//- (NSString *) localPlayerName {
//    if ( [GKLocalPlayer localPlayer].isAuthenticated ) {
//        return [GKLocalPlayer localPlayer].alias;
//    }
//
//    return nil;
//}


//- (void) retrieveFriends {
//    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
//
//    [localPlayer loadFriendPlayersWithCompletionHandler:^(NSArray *friends, NSError *error) {
//        if ( error != nil ) {
//            CCLOG( @"error getting list of friends: %@", error.localizedDescription );
//            return;
//        }
//
//        if ( friends != nil ) {
//            // create a new array with the friend id:s
//            NSMutableArray * identifiers = [[NSMutableArray alloc] initWithCapacity:friends.count];
//            for ( GKPlayer * friend in friends ) {
//                [identifiers addObject:friend.playerID];
//            }
//
//            [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *friendsData, NSError *error2) {
//                if ( error2 != nil ) {
//                    CCLOG( @"error getting data for the friends: %@", error2.localizedDescription );
//                }
//                else if ( friendsData != nil ) {
//                    self.friends = friendsData;
//
//                    for ( GKPlayer * friend in friendsData ) {
//                        CCLOG( @"Game Center friend: %@", friend );
//                    }
//                }
//            }];
//        }
//        else {
//            // local player has no friends
//        }
//    }];
//}

@end
