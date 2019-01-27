
#import "InfluenceMap.h"
#import "Globals.h"

@interface InfluenceMap ()

@property (nonatomic, weak) UnitStrengthMap * player1;
@property (nonatomic, weak) UnitStrengthMap * player2;

@end


@implementation InfluenceMap


- (id) initWithPlayer1:(UnitStrengthMap *)player1 player2:(UnitStrengthMap *)player2 {
    if ( ( self = [super init] ) ) {
        self.title = @"Influence";
        _player1 = player1;
        _player2 = player2;
	}
    
	return self;
}


- (void) update {
    [self clear];

    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            float aiStrength = [self.player1 getValue:x y:y];
            float humanStrength = [self.player2 getValue:x y:y];

            // the sum of the values
            float sum = humanStrength - aiStrength;

            // save
            data[ self.width * y + x ] = sum;

            // new min or max?
            self.max = MAX( self.max, sum );
            self.min = MIN( self.min, sum );
        }
    }

    NSLog( @"max: %f, min: %f", self.max, self.min );
}

@end
