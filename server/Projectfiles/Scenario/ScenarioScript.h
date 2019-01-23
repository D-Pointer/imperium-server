
#import <JavaScriptCore/JavaScriptCore.h>
#import <Foundation/Foundation.h>

@class Scenario;


@interface ScenarioScript : NSObject

- (instancetype) initWithScript:(NSString *)script;

- (void) setupForScenario:(Scenario *)scenario;

- (void) runScript;

@end