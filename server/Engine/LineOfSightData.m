
#import "LineOfSightData.h"
#import "Unit.h"

@interface LineOfSightData () {
    UInt8 * data;
    int *   seen;
    int *   oldSeen;
}

@property (nonatomic, readwrite) unsigned int count;
@property (nonatomic, readwrite) unsigned int seenCount;
@property (nonatomic, readwrite) unsigned int oldSeenCount;
@property (nonatomic, weak)       NSMutableArray *    units;

@end

@implementation LineOfSightData

- (instancetype) initWithUnits:( NSMutableArray * )units {
    self = [super init];
    if (self) {
        self.count = units.count;
        self.units = units;
        self.seenCount = 0;
        self.oldSeenCount = 0;
        self.didSpotNewEnemies = NO;

        // allocate space for the internal data
        data = malloc( self.count * sizeof( UInt8 ) );
        memset( data, 0, self.count * sizeof( UInt8 ) );

        // the array of seen units
        seen = malloc( self.count * sizeof( int ) );
        memset( seen, 0, self.count * sizeof( int ) );

        // an array of old seen units, used to check what units we no longer see
        oldSeen = malloc( self.count * sizeof( int ) );
        memset( oldSeen, 0, self.count * sizeof( int ) );
    }

    return self;
}


- (void) dealloc {
    free( data );
    free( seen );
    free( oldSeen );
}


- (void) clearSeen {
    _oldSeenCount = 0;
    _didSpotNewEnemies = NO;

    // copy the old data
    unsigned int oldSeenIndex = 0;
    for ( unsigned int index = 0; index < self.count; ++index ) {
        if ( data[ index ] > 0 ) {
            oldSeen[ oldSeenIndex++ ] = index;
            _oldSeenCount++;
        }
    }

    // clear
    memset( data, 0, self.count * sizeof( UInt8 ) );

    // now clear the new seen data
    memset( seen, 0, self.count * sizeof( int ) );
    self.seenCount = 0;
}


- (void) setSeen:(Unit *)unit {
    // only update the seen count if the unit was not seen before, avoids seeing the same enemy twice
    if ( data[ unit.losIndex ] == 0 ) {
        seen[ self.seenCount ] = unit.losIndex;
        self.seenCount++;
    }

    data[ unit.losIndex ] = 1;
}


- (BOOL) seesUnit:(Unit *) unit {
    return data[ unit.losIndex ] > 0;
}


- (Unit *) getSeenUnit:(unsigned int)index {
    return [ _units objectAtIndex:seen[ index ]];
}


- (Unit *) getPreviouslySeenUnit:(unsigned int)index {
    return [ _units objectAtIndex:oldSeen[ index ]];
}


- (BOOL) wasUnitPreviouslySeen:(Unit *)unit {
    for ( unsigned int index = 0; index < _oldSeenCount; ++index ) {
        if ( unit.losIndex == oldSeen[ index ] ) {
            // yes, it was seen during the last update
            return YES;
        }
    }

    // the unit was not previously seen
    return NO;
}

@end
