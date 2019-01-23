
#import <Foundation/Foundation.h>


@protocol ResourceDownloaderDelegate <NSObject>

// the delegate methods are called on a background thread!
- (void) resourcesDownloaded;
- (void) resourcesFailedWithError:(NSError *)error;

@end


@interface ResourceDownloader : NSObject 

- (instancetype) initWithDelegate:(id<ResourceDownloaderDelegate>)delegate;

// start downloading resources
- (void) downloadResources;

@end
