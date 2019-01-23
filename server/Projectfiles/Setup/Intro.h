

#import "cocos2d.h"
#import "Layer.h"
#import "ResourceDownloader.h"

//@protocol IntroJS <JSExport>
//
//- (void) jsTest:(NSString *)text;
//
//@end

@interface Intro : Layer <ResourceDownloaderDelegate, CCTouchOneByOneDelegate> //, IntroJS>

@property (nonatomic, strong) CCSprite *      logo;
@property (nonatomic, strong) CCNode *        storyPaper;
@property (nonatomic, strong) CCLabelBMFont * text;
@property (nonatomic, strong) CCLabelBMFont * continueLabel;

+ (CCScene *) scene;

@end
