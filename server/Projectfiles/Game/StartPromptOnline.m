
#import "CCBReader.h"

#import "StartPromptOnline.h"
#import "Globals.h"

@implementation StartPromptOnline


+ (StartPromptOnline *) node {
    StartPromptOnline * node = (StartPromptOnline *)[CCBReader nodeGraphFromFile:@"StartPromptOnline.ccb"];
    return node;
}


- (void) didLoadFromCCB {
}

@end
