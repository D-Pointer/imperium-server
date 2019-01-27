
#include <Foundation/Foundation.h>


@interface MapBase : NSObject {
    float * data;
}

@property (nonatomic, strong)    NSString *    title;
@property (nonatomic, readonly)  int           width;
@property (nonatomic, readonly)  int           height;
@property (nonatomic, readwrite) float         max;
@property (nonatomic, readwrite) float         min;

@property (nonatomic, readonly) int            tileSize;
@property (nonatomic, readonly) int            tileScale;

- (float) getValue:(int)x y:(int)y;
- (float) getValue:(CGPoint)pos;
- (void) addValue:(float)value index:(int)index;


- (void) clear;

- (int) fromWorld:(float)value;

@end
