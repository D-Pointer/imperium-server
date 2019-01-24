
#import "InfluenceMap.h"
#import "Globals.h"

@interface InfluenceMap ()

@property (nonatomic, weak) UnitStrengthMap * ai;
@property (nonatomic, weak) UnitStrengthMap * human;

@end


@implementation InfluenceMap


- (id) initWithAI:(UnitStrengthMap *)ai human:(UnitStrengthMap *)human {
    if ( ( self = [super init] ) ) {
        self.title = @"Influence";
        _ai = ai;
        _human = human;
	}
    
	return self;
}


- (void) update {
    [self clear];

    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            float aiStrength = [self.ai getValue:x y:y];
            float humanStrength = [self.human getValue:x y:y];

            // the sum of the values
            float sum = humanStrength - aiStrength;

            // save
            data[ self.width * y + x ] = sum;

            // new min or max?
            self.max = max( self.max, sum );
            self.min = min( self.min, sum );
        }
    }

    CCLOG( @"max: %f, min: %f", self.max, self.min );

    int color1, color2;
    
    // create the texture data. most influence will be white, least will be black
    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            int dataIndex = y * self.width + x;
            //int textureIndex = y * self.textureWidth + x;
            float value = data[ dataIndex ];

            if ( value < 0 ) {
                color1 = (int)(value / self.min * 255.0f);
                color2 = (int)(value / self.min * 100.0f);
                [self setPixel:ccc4( color2, color2, color1, 255 ) x:x y:y];
            }
            else {
                color1 = (int)(value / self.max * 255.0f);
                color2 = (int)(value / self.max * 100.0f);
                [self setPixel:ccc4( color2, color2, color1, 255 ) x:x y:y];
            }
        }
    }
}

@end
