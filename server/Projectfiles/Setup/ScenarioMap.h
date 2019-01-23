
#import "cocos2d.h"
#import "Scenario.h"
#import "PanZoomNode.h"

@protocol ScenarioMapDelegate <NSObject>

- (void) scenarioPressed:(Scenario *)scenario;

@end


@interface ScenarioMap : CCNode

@property (nonatomic, strong)   CCSprite *              background;
@property (nonatomic, strong)   CCMenu *                menu;
@property (nonatomic, strong)   CCNode *                citiesNode;
@property (nonatomic, readonly) int                     completedScenarios;
@property (nonatomic, readonly) int                     playableScenarios;
@property (nonatomic, weak)     id<ScenarioMapDelegate> delegate;

@end
