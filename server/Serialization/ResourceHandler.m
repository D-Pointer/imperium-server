
#import "ResourceHandler.h"

@implementation ResourceHandler

+ (BOOL) hasResource:(NSString *)name {
    NSString * resourcePath = [ResourceHandler createPath:name];
    return [[NSFileManager defaultManager] fileExistsAtPath:resourcePath];
}


+ (NSString *) loadResource:(NSString *)name {
    NSString * resourcePath = [ResourceHandler createPath:name];

    CCLOG( @"loading resource: %@", name );
    CCLOG( @"path: %@", resourcePath );

    // read everything and split into lines
    NSError * error;
    NSString * contents = [NSString stringWithContentsOfFile:resourcePath encoding:NSUTF8StringEncoding error:&error];
    if ( error != nil ) {
        CCLOG( @"failed to read resource : %@", [error localizedDescription] );
        return nil;
    }

    return contents;
}


+ (BOOL) saveData:(NSString *)data toResource:(NSString *)name {
    NSString * resourcePath = [ResourceHandler createPath:name];

    NSError * error;
    [data writeToFile:resourcePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if ( error != nil ) {
        CCLOG( @"failed to save resource: %@", [error localizedDescription] );
        return NO;
    }

    return YES;
}


+ (BOOL) deleteResource:(NSString *)name {
    NSString * resourcePath = [ResourceHandler createPath:name];

    NSError * error = nil;

    // does it exist?
    if ( ! [[NSFileManager defaultManager] removeItemAtPath:resourcePath error:&error] ) {
        // failed to delete
        CCLOG( @"failed to remove %@, error: %@", name, [error localizedDescription] );
        return NO;
    }

    return YES;
}


+ (NSString *) createPath:(NSString *)name {
    if ( [name characterAtIndex:0] != '/' ) {
        name = [@"/" stringByAppendingString:name];
    }

    // path to the possibly updated scenario files
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingString:name];
}
@end


