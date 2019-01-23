#import "AppDelegate.h"
#import "Globals.h"
#import "Intro.h"
#import "ResourceDownloader.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@implementation MyNavigationController

// The available orientations should be defined in the Info.plist file.
// And in iOS 6+ only, you can override it in the Root View controller in the "supportedInterfaceOrientations" method.
// Only valid for iOS 6+. NOT VALID for iOS 4 / 5.
- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end


@implementation AppDelegate

//@synthesize window = self.window, navController = self.navController, director = director_;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Create the main window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // CCGLView creation
    // viewWithFrame: size of the OpenGL view. For full screen use [_window bounds]
    //  - Possible values: any CGRect
    // pixelFormat: Format of the render buffer. Use RGBA8 for better color precision (eg: gradients). But it takes more memory and it is slower
    //	- Possible values: kEAGLColorFormatRGBA8, kEAGLColorFormatRGB565
    // depthFormat: Use stencil if you plan to use CCClippingNode. Use Depth if you plan to use 3D effects, like CCCamera or CCNode#vertexZ
    //  - Possible values: 0, GL_DEPTH_COMPONENT24_OES, GL_DEPTH24_STENCIL8_OES
    // sharegroup: OpenGL sharegroup. Useful if you want to share the same OpenGL context between different threads
    //  - Possible values: nil, or any valid EAGLSharegroup group
    // multiSampling: Whether or not to enable multisampling
    //  - Possible values: YES, NO
    // numberOfSamples: Only valid if multisampling is enabled
    //  - Possible values: 0 to glGetIntegerv(GL_MAX_SAMPLES_APPLE)
    CCGLView *glView = [CCGLView viewWithFrame:[self.window bounds]
                                   pixelFormat:kEAGLColorFormatRGB565
                                   depthFormat:0
                            preserveBackbuffer:NO
                                    sharegroup:nil
                                 multiSampling:NO
                               numberOfSamples:0];

    // we want multitouch
    [glView setMultipleTouchEnabled:YES];

    self.director = (CCDirectorIOS *) [CCDirector sharedDirector];

    //self.director.wantsFullScreenLayout = YES;
    self.director.edgesForExtendedLayout = UIRectEdgeNone;

    // DEBUG: display FSP and SPF
    [self.director setDisplayStats:sFpsDebugging];

    // set FPS at 60
    [self.director setAnimationInterval:1.0 / 60];

    // attach the openglView to the director
    [self.director setView:glView];

    // 2D projection
    [self.director setProjection:kCCDirectorProjection2D];

    // Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
    if (![self.director enableRetinaDisplay:YES]) {
        CCLOG( @"retina display not supported" );
    }

    // Default texture format for PNG/BMP/TIFF/JPEG/GIF images
    // It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
    // You can change this setting at any time.
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];

    // If the 1st suffix is not found and if fallback is enabled then fallback suffixes are going to searched. If none is found, it will try with the name without suffix.
    // On iPad HD  : "-ipadhd", "-ipad",  "-hd"
    // On iPad     : "-ipad", "-hd"
    // On iPhone HD: "-hd"
    CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
    [sharedFileUtils setEnableFallbackSuffixes:NO];                // Default: NO. No fallback suffixes are going to be used
    [sharedFileUtils setiPadSuffix:@""];                    // Default on iPad is "ipad"
    [sharedFileUtils setiPadRetinaDisplaySuffix:@"-hd"];    // Default on iPad RetinaDisplay is "-ipadhd"
    [sharedFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];        // Default on iPhone RetinaDisplay is "-hd"

    // load the sprite sheet
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Spritesheet.plist"];

    Globals *globals = [Globals sharedInstance];

    // make us available to others
    [Globals sharedInstance].appDelegate = self;

    // set default values for the audio to make sure it's enabled
//    NSDictionary *defaultValues = @{
//            @"soundsEnabled" : @(kEnabled),
//            @"musicEnabled" : @(kEnabled),
//            @"showAllMissions" : @(YES),
//            @"showCommandControl" : @(YES),
//            @"showFiringRange" : @(YES),
//            @"lastDownload" : @(-1),
//            @"tutorialsCompleted" : @(NO),
//            };
//    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];

    // now we can perform the network login as we have a local player name
    CCLOG( @"initializing network connection" );
    globals.tcpConnection = [TcpNetworkHandler new];

    // now connect
    [globals.tcpConnection connect];

    // Assume that PVR images have premultiplied alpha
    [CCTexture2D PVRImagesHavePremultipliedAlpha:YES];

    // Create a Navigation Controller with the Director
    self.navController = [[MyNavigationController alloc] initWithRootViewController:self.director];
    self.navController.navigationBarHidden = YES;

    // for rotation and other messages
    [self.director setDelegate:self.navController];

    // set the Navigation Controller as the root view controller
    [self.window setRootViewController:self.navController];

    // make main window visible
    [self.window makeKeyAndVisible];

    // show a static launch screen for a short while to mask the short fade to black that comes after the
    // launch storyboard and the intro scene
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LaunchBackground.jpg"]];
    [self.window addSubview:view];
    [view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.4];

    [self.director runWithScene:[Intro scene]];

    // Crashlytics
    [Fabric with:@[CrashlyticsKit]];

    return YES;
}

// getting a call, pause the game
- (void) applicationWillResignActive:(UIApplication *)application {
    if ([self.navController visibleViewController] == self.director) {
        [self.director pause];
    }
}

// call got rejected
- (void) applicationDidBecomeActive:(UIApplication *)application {
    [[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
    if ([self.navController visibleViewController] == self.director) {
        [self.director resume];
    }
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
    if ([self.navController visibleViewController] == self.director) {
        [self.director stopAnimation];
    }
}

- (void) applicationWillEnterForeground:(UIApplication *)application {
    if ([self.navController visibleViewController] == self.director) {
        [self.director startAnimation];
    }
}

// application will be killed
- (void) applicationWillTerminate:(UIApplication *)application {
    CC_DIRECTOR_END();
}

// purge memory
- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
- (void) applicationSignificantTimeChange:(UIApplication *)application {
    [[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}


- (void) dealloc {
    CCLOG( @"in" );
}

@end
