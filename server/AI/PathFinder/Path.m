
#import "Path.h"

@interface Path ()

@property (readwrite, nonatomic, retain)  NSMutableArray * hexes;

@end


@implementation Path

@synthesize count;
@synthesize hexes;
@synthesize highlighted;

- (id) init {
    self = [super init];
    if (self) {
        self.hexes = [[[ NSMutableArray alloc] init] autorelease];
    }
    
    return self;
}


- (void) dealloc {
    // clear any highlights
    Hex * hex;
     NSMutableArray_FOREACH( self.hexes, hex ) {
        hex.highlighted = NO;
    }
    
    self.hexes = nil;
    [super dealloc];
}


- (int) count {
    return [self.hexes count];
}


- (void) setHighlighted: (BOOL)highlighted_ {
    highlighted = highlighted_;
    
    Hex * hex;
     NSMutableArray_FOREACH( self.hexes, hex ) {
        hex.highlighted = highlighted_;
    }
}


- (Hex *) firstHex {
    NSAssert( self.count > 0, @"Path.firstHex: path is empty" );
    return [self.hexes objectAtIndex:0];
}


- (Hex *) hexAtIndex: (int)index {
    NSAssert( index < self.count, @"Path.hexAtIndex: index out of bounds" );
    return [self.hexes objectAtIndex:index];
}


- (void) addHex: (Hex *)hex {
    [self.hexes addObject:hex];
}


- (void) removeFirst {
    NSAssert( self.count > 0, @"Path.removeFirst: path is empty" );
    [self.hexes removeObjectAtIndex:0];
}


- (void) fixOrdering {
    [self.hexes reverseObjects];
}
@end
