
#import "GoalMap.h"
#import "Globals.h"

@interface GoalMap ()

@property (nonatomic, weak) UnitStrengthMap * ai;
@property (nonatomic, weak) UnitStrengthMap * human;

@end


@implementation GoalMap

- (void) calculateMap:(UnitStrengthMap *)map1 map2:(UnitStrengthMap *)map2 {
}


- (id) initWithAI:(UnitStrengthMap *)ai human:(UnitStrengthMap *)human {
    if ( ( self = [super init] ) ) {
        self.title = @"Goal";
        _ai = ai;
        _human = human;
	}
    
	return self;
}


- (void) update {
    [self clear];
    
    int w = self.width;

    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            int index = y * w + x;
            float aiStrength = [self.ai getValue:x y:y];
            float humanStrength = [self.human getValue:x y:y];

            // the product of the values -> where both have influence gets a much higher score compared to
            // where only one player has units
            float tension = aiStrength * humanStrength;

            // save
            data[ index ] = tension;

            // new min or max?
            if ( tension > self.max ) {
                self.max = tension;
            }
            else if ( tension < self.min ) {
                self.min = tension;
            }
        }
    }

    CCLOG( @"max: %f, min: %f", self.max, self.min );

    // create the texture data. most tension will be white, least will be black
    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            int dataIndex = y * self.width + x;
            int textureIndex = y * self.textureWidth + x;

            int color = ( data[ dataIndex ] / self.max * 255.0f );
            colors[ textureIndex ] = ccc4( color, color, color, 255 );
        }
    }
}

@end
