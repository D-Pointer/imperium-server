
#import "Blackboard.h"


@implementation Blackboard

- (instancetype)init {
    self = [super init];
    if (self) {
        self.trace = [NSMutableArray arrayWithCapacity:50];
        self.enemiesInRange = [NSMutableSet set];
        self.enemiesInFieldOfFire = [NSMutableSet set];
        self.rallyableUnits = [NSMutableSet set];

        self.closestEnemyInFieldOfFire = nil;
        self.closestEnemyInRange = nil;
        self.closestRallyableUnit = nil;
        self.executedAction = nil;

        self.nodeData = [NSMutableDictionary dictionaryWithCapacity:100];

        CCLOG( @"creating" );
    }

    return self;
}


- (void) clear {
    self.closestEnemyInFieldOfFire = nil;
    self.closestEnemyInRange = nil;
    self.closestRallyableUnit = nil;
    self.executedAction = nil;
    
    [self.trace removeAllObjects];
    [self.enemiesInRange removeAllObjects];
    [self.enemiesInFieldOfFire removeAllObjects];
    [self.rallyableUnits removeAllObjects];
}

@end
