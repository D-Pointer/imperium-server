
#import "ResultMap.h"
#import "Globals.h"
#import "ResultPosition.h"

@implementation ResultMap

@synthesize potentials;

- (id) init {
	// Apple recommends to re-assign "self" with the "super" return value
    if ( ( self = [super init] ) ) {
        self.title = @"Result";
        self.potentials = [NSMutableArray array];
	}
    
	return self;
}


- (void) dealloc {
    self.potentials = nil;
}


- (void) markImpassable {
//    Map * map = [Globals sharedInstance].map;
//    
//    int impassable = 0;
//    
//    for ( int y = 0; y < self.height; ++y ) {
//        for ( int x = 0; x < self.width; ++x ) {
//            Hex * hex = [map getHex:x y:y];
//            
//            // is it passable?
//            if ( hex.movementCost == -1 || hex.unit != nil ) {
//                // not passable
//                data[ y * self.width + x ] = -1;
//                impassable++;
//            }
//        }
//    }
//    
//    NSLog( @"ResultMap.markImpassable: found %d impassable hexes", impassable );
}


- (void) extractPotentials {
    [self.potentials removeAllObjects];
    
    // set up the colors
    for ( int index = 0; index < self.width * self.height; ++index ) {
        int value = data[ index ];
    
        // only handle > 0 
        if ( value > 0 ) {
            ResultPosition * pos = [[ResultPosition alloc] initWithIndex:index value:value];
            [self.potentials addObject:pos];
        }
    }
    
    // sort the values this sorts them ascending, so the best values are at the end..
    [self.potentials sortUsingSelector:@selector(compare:)];
    
    NSLog( @"ResultMap.extractPotentials: found %d potential positions", [self.potentials count] );
}


- (void) update:(NSArray *)maps {
    [self clear];
    
    // go through all the maps
    for ( int index = kAIUnitsMapType; index < kResultMapType; ++index ) {
        MapBase * map = [maps objectAtIndex:index];
        
        // have the map write the result into us
        [map saveResult:self];
    }
    
   // [self markImpassable];
    
    // extract all potential positions
    [self extractPotentials];
 
    // set up the colors
//    for ( int index = 0; index < [possible count]; ++index ) {
//        ResultPosition * pos = [possible objectAtIndex:index];
//        
//        NSLog( @"%d -> %d", pos.index, pos.value );
//    }
    
    // set up the colors
    for ( int index = 0; index < self.width * self.height; ++index ) {
        int value = data[ index ];
        
        // impassable?
        if ( value == -1 ) {
            colors[ index ] = ccc4( 255, 0, 0, 255 );
        }
        else {
            value = (int)( (float)value / (float)self.max * 255.0 );
            colors[ index ] = ccc4( value, value, value, 255 );
        }
    }
}


@end
