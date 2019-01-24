
#import "cocos2d.h"

@interface Path : NSObject

@property (readonly, nonatomic)         int       count;
@property (readonly, nonatomic, strong) CCArray * hexes;
@property (readwrite, nonatomic)        BOOL      highlighted;

- (Hex *) firstHex;
- (Hex *) hexAtIndex: (int)index;

- (void) addHex: (Hex *)hex;

- (void) removeFirst;

- (void) fixOrdering;

@end
