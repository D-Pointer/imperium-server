
#import "CCNode.h"
#import "Unit.h"
#import "Path.h"

@interface ActionsMenu : CCNode <CCTouchOneByOneDelegate>

- (void) path:(Path *)path createdTo:(CGPoint)pos withNodes:(NSMutableArray *)pathNodes;

- (void) mapClicked:(CGPoint)pos;

- (BOOL) ownUnitClicked:(Unit *)clicked;

- (void) enemyClicked:(Unit *)enemy;

- (void) hide;


@end
