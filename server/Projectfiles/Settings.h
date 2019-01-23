
#import "Definitions.h"

@interface Settings : NSObject

@property (nonatomic, strong) NSString * onlineName;
@property (nonatomic, assign) AudioState soundsEnabled;
@property (nonatomic, assign) AudioState musicEnabled;
@property (nonatomic, assign) BOOL showAllMissions;
@property (nonatomic, assign) BOOL showCommandControl;
@property (nonatomic, assign) BOOL showFiringRange;
@property (nonatomic, assign) BOOL tutorialsCompleted;
@property (nonatomic, assign) int lastDownload;

/**
 * Returns a singleton instance of the game data.
 **/
+ (Settings *) sharedInstance;


@end
