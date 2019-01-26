#import <JavaScriptCore/JavaScriptCore.h>


#import "Definitions.h"
#import "VictoryCondition.h"

// export stuff to Javascript
@protocol ScenarioJS <JSExport>

@property (nonatomic)           int                width;
@property (nonatomic)           int                height;

@end


@interface Scenario : NSObject <ScenarioJS>

@property (nonatomic, assign)   short              scenarioId;
@property (nonatomic, assign)   short              dependsOn;
@property (nonatomic, assign)   int                startTime;
@property (nonatomic, strong)   NSString *         title;
@property (nonatomic, strong)   NSString *         information;
@property (nonatomic, strong)   NSString *         filename;
@property (nonatomic, assign)   AIHint             aiHint;
@property (nonatomic, assign)   BattleSizeType     battleSize;
@property (nonatomic, assign)   ScenarioType       scenarioType;

@property (nonatomic, readonly) ScenarioState      state;
@property (nonatomic, strong)    NSMutableArray *          victoryConditions;
@property (nonatomic, strong)   VictoryCondition * endCondition;

@property (nonatomic)           int                width;
@property (nonatomic)           int                height;

// all starting positions for the map
@property (nonatomic, strong)    NSMutableArray *          startingPositions;

// wind direction (0..360) and strength (m/s)
@property (nonatomic, assign)   float              windDirection;
@property (nonatomic, assign)   float              windStrength;


- (BOOL) isPlayableForCampaign:(int)campaignId;

- (BOOL) isCompletedForCampaign:(int)campaignId;

- (void) setCompletedForCampaign:(int)campaignId;

- (void) clearCompletedForCampaign:(int)campaignId;

@end
