
#import "ScenarioScript.h"
#import "Globals.h"
#import "Scenario.h"

@interface ScenarioScript()

@property (nonatomic, strong) JSContext * context;
@property (nonatomic, strong) JSValue *   updateFunction;
@end


@implementation ScenarioScript

- (instancetype) initWithScript:(NSString *)script {
    self = [super init];
    if (self) {
        self.context = [JSContext new];

        // enable error logging
        [self.context setExceptionHandler:^(JSContext *context, JSValue *value) {
            CCLOG(@"JS exception: %@", value);
        }];

        // set up console.log for JS
        [self.context evaluateScript:@"var console = {};"];
        self.context[@"console"][@"log"] = ^(NSString *message) {
            CCLOG(@"JS: %@", message);
        };

        // evaluate the script itself
        [self.context evaluateScript:script];

        // calling a JavaScript function
        self.updateFunction = self.context[@"update"];
    }

    return self;
}


- (void) setupForScenario:(Scenario *)scenario {
    if ( ! self.context ) {
        CCLOG( @"no JS context, can not set up" );
        return;
    }

    self.context[@"scenario"] = scenario;
    self.context[@"map"] = [Globals sharedInstance].mapLayer;

    // have the script init itself
    JSValue * initFunction = self.context[@"init"];
    if ( initFunction.isUndefined ) {
        CCLOG( @"script has no init() function, skipping initialization" );
    }
    else {
        CCLOG( @"executing JS init script" );
        [initFunction callWithArguments:nil];
    }
}


- (void) runScript {
    if ( self.updateFunction && ! self.updateFunction.isUndefined ) {
        CCLOG( @"executing JS update function");
        [self.updateFunction callWithArguments:@[@([Globals sharedInstance].clock.elapsedTime)]];
    }
}

@end