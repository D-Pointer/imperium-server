
#import <Foundation/Foundation.h>

@interface Path : NSObject

@property (nonatomic, strong)   NSMutableArray * positions;
@property (nonatomic, readonly) NSUInteger       count;
@property (nonatomic, readonly) CGPoint          firstPosition;
@property (nonatomic, readonly) CGPoint          lastPosition;
@property (nonatomic, readonly) CGPoint          finalFacingTarget;
@property (nonatomic, readonly) CGFloat          length;

- (void) addPosition:(CGPoint)pos;

- (void) removeFirstPosition;

- (void) updateFinalFacing;

- (void) debugPath;

// saves the path to a string
- (NSString *) save;

// loads the path from an array of parts
+ (Path *) pathFromData:(NSArray *)parts startIndex:(int)startIndex;

@end
