
#import <Foundation/Foundation.h>

@interface NSData (Compression)

// gzip compression utilities
- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
