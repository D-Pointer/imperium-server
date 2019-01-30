
#import "ParameterHandler.h"
#import "Definitions.h"

@implementation ParameterHandler

- (instancetype)init {
    self = [super init];
    if (self) {
    }

    return self;
}


- (BOOL) readParameters {
//    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *parametersPath = [NSString stringWithFormat:@"%@/Engine/Parameters.txt", paths[0]];

    NSString * name = @"/Engine/Parameters.txt";
    NSLog( @"reading game parameters from: %@", name );

    // do we have any parameters?
    // read everything from text
    NSString *contents = nil;//[ResourceHandler loadResource:name];
//    [NSString stringWithContentsOfFile:parametersPath
//                                                   encoding:NSUTF8StringEncoding error:nil];
    if ( contents == nil ) {
        NSLog( @"failed to load parameters from: %@", name );
        return NO;
    }

    // split into lines
    NSArray * lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for ( int index = 0; index < kParameterCount; ++index ) {
        NSString * line = lines[ index];

        if (line.length == 0) {
            NSLog( @"invalid empty line %d", index );
            return NO;
        }

        // trim the line
        NSString * trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *parts = [trimmedLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        // normal parameter line
        if (parts.count != 2) {
            NSLog( @"invalid parameters line: %d: parts: %lu, %@", index, (unsigned long)parts.count, trimmedLine );
            continue;
        }

        NSString * name = parts[ 0 ];
        NSString * value = parts[ 1 ];

        Parameter param;

        switch ( [name characterAtIndex:name.length - 1] ) {
            case 'F':
                param.floatValue = [value floatValue];
                sParameters[ index ] = param;
                break;

            case 'I':
                sParameters[ index ].intValue = [value intValue];
                break;

            case 'B':
                sParameters[ index ].boolValue = [value intValue] == 0 ? NO : YES;
                break;

            default:
                NSLog( @"invalid parameter type: %@", name );
        }
    }

    for ( int index = 0; index < kParameterCount; ++index ) {
        NSLog( @"%d %.1f %d", index, sParameters[index].floatValue, sParameters[index].intValue );
    }

    NSLog( @"parsed parameters" );
    return YES;
}

@end
