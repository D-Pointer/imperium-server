
#import <UIKit/UIKit.h>
#import "cocos2d.h"

// Added only for iOS 6 support
@interface MyNavigationController : UINavigationController <CCDirectorDelegate>
@end

@interface AppDelegate : NSObject <UIApplicationDelegate>
//{
//	UIWindow *window_;
//	MyNavigationController *navController_;
//
//	CCDirectorIOS	*director_;							// weak ref
//}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MyNavigationController *navController;
@property (nonatomic, strong) CCDirectorIOS *director;

@end
