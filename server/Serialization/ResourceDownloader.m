#import <Crashlytics/Crashlytics.h>
#import <Crashlytics/Answers.h>

#import <CloudKit/CloudKit.h>

#import "ResourceDownloader.h"
#import "Globals.h"
#import "NSData+Compression.h"

@interface ResourceDownloader ()

@property (nonatomic, assign) id<ResourceDownloaderDelegate> delegate;
@property (nonatomic, strong) CKDatabase * database;
@property (nonatomic, strong) NSString * resourceDir;
@property (nonatomic, assign) NSInteger localVersion;

@end

#define LOCAL_VERSION_KEY @"ResourceDownloader.localVersion"

@implementation ResourceDownloader

- (id) initWithDelegate:(id<ResourceDownloaderDelegate>)delegate {
    self = [super init];
    if (self) {
        // set up the database
        self.database = [CKContainer defaultContainer].publicCloudDatabase;
        self.delegate = delegate;
        
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.resourceDir = paths[0];

        // get the version of the data that we currently have
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        self.localVersion = [defaults integerForKey:LOCAL_VERSION_KEY];
    }

    return self;
}


- (void) dealloc {
    // TODO
}


- (void) downloadResources {
    NSLog( @"downloading game resources from iCloud, last downloaded version: %ld", (long)self.localVersion );

    // query all users stash records from the public database. In reality there should be only one
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"Version > %d", self.localVersion];
    CKQuery * query = [[CKQuery alloc] initWithRecordType:@"Resource" predicate:predicate];

    [self.database performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
        if ( error) {
            [self.delegate resourcesFailedWithError:error];
            return;
        }

        if ( results == nil || results.count == 0 ) {
            [self.delegate resourcesDownloaded];
            return;
        }

        NSLog( @"received %lu updated resources", (unsigned long)results.count );

        for ( CKRecord * record in results ) {
            NSInteger resourceVersion = [self handleResource:record];

            // new biggest version?
            if ( resourceVersion > self.localVersion ) {
                self.localVersion = resourceVersion;
            }
        }

        // update the defaults too as we have now fetched new resources
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:self.localVersion forKey:LOCAL_VERSION_KEY];

        NSLog( @"resources downloaded" );
        [self.delegate resourcesDownloaded];
    }];
}


- (NSInteger) handleResource:(CKRecord *)resource {
    // the name of the path is "Title", this is mainly so that the CloudKit dashboard shows a nicer name for the records. It uses "Title" by default
    NSString * filename = [resource objectForKey:@"Title"];
    NSNumber * version = [resource objectForKey:@"Version"];
    CKAsset * asset = [resource objectForKey:@"Data"];
    NSURL * sourceUrl = asset.fileURL;

    NSLog( @"handling resource: %@, version: %@", filename, version );

    // preprend the resource directory
    NSString * fullPath = [self.resourceDir stringByAppendingPathComponent:filename];

    // do we need to create a directory for the file?
    NSString * directory = fullPath.stringByDeletingLastPathComponent;
    NSError * error = nil;
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:directory] ) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error != nil) {
            NSLog( @"error creating resource directory %@: %@", directory, error);
            [self.delegate resourcesFailedWithError:error];
            return -1;
        }

        NSLog( @"created resource directory: %@", directory );
    }


    // check if the filename ends with ".gz"
    if ( [[filename pathExtension] caseInsensitiveCompare:@"gz"] == NSOrderedSame ) {
        // a compressed file, load and uncompress it
        NSData * compressed = [NSData dataWithContentsOfURL:sourceUrl];
        NSData * uncompressed = [compressed gzipInflate];
        if ( uncompressed == nil ) {
            NSLog( @"failed to uncompress %@", filename );
            [Answers logCustomEventWithName:@"Resource uncompression failed"
                           customAttributes:@{ @"name" : filename }];
            return -1;
        }
        else {
            error = nil;
            [uncompressed writeToFile:fullPath options:NSDataWritingAtomic error:&error];
            if (error != nil) {
                NSLog( @"error writing uncompressed data to file %@: %@", fullPath, error);
            }
            else {
                NSLog( @"saved uncompressed data to file: %@, version: %@", filename, version );
            }
        }
    }

    else {
        // the file is uncompressed, so copy it to the target location
        error = nil;
        NSData * contents = [NSData dataWithContentsOfURL:sourceUrl];
        [contents writeToFile:fullPath options:NSDataWritingAtomic error:&error];
        if (error != nil) {
            NSLog( @"error writing file %@: %@", filename, error);
            return -1;
        }
        else {
            NSLog( @"saved file: %@, version: %@", filename, version );
        }
    }

    [Answers logCustomEventWithName:@"Resource updated"
                   customAttributes:@{ @"name" : filename,
                                       @"version" : version }];

    return version.integerValue;
}

@end
