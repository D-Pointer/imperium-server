
#import <objc/runtime.h>
#import "Settings.h"
#import "ResourceHandler.h"

@implementation Settings

+ (Settings *) sharedInstance {
    static Settings * instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
        instance = [[Settings alloc] init];
    });

    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        // set up default values for all properties
        self.onlineName = nil;
        self.soundsEnabled = kEnabled;
        self.musicEnabled = kEnabled;
        self.showAllMissions = YES;
        self.showCommandControl = YES;
        self.showFiringRange = YES;
        self.tutorialsCompleted = NO;
        self.lastDownload = -1;

        // load any saved data
        [self load];

        // register KVO for all properties
        unsigned int count;
        objc_property_t* properties = class_copyPropertyList([self class], &count);
        for (unsigned int index = 0; index < count ; index++) {
            const char* propertyName = property_getName(properties[index]);
            NSString *stringPropertyName = [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding];
            [self addObserver:self forKeyPath:stringPropertyName options:NSKeyValueObservingOptionNew context:nil];
        }
    }

    return self;
}


- (void)didChangeValueForKey:(NSString *)key {
    CCLOG( @"changed value for: %@", key );
    [self save];
}


- (void) load {
    // read everything and split into lines
    NSString * contents = [ResourceHandler loadResource:@"Settings.txt"];
    if ( contents == nil ) {
        return;
    }

    NSArray * lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    CCLOG( @"read %lu lines", (unsigned long)lines.count );

    for ( NSString * line in lines ) {
        NSArray *parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        // precautions in case there are empty lines
        if ( parts.count == 0 ) {
            continue;
        }

        CCLOG( @"line: %@", line );

        NSString *type = parts[0];

        if ([type isEqualToString:@"onlineName"]) {
            self.onlineName = [line substringFromIndex:type.length + 1];
            CCLOG( @"online name: '%@'", self.onlineName );
        }
        else if ([type isEqualToString:@"soundsEnabled"]) {
            self.soundsEnabled = [parts[1] intValue] == 1 ? kEnabled : kDisabled;
        }
        else if ([type isEqualToString:@"musicEnabled"]) {
            self.musicEnabled = [parts[1] intValue] == 1 ? kEnabled : kDisabled;
        }
        else if ([type isEqualToString:@"showAllMissions"]) {
            self.showAllMissions = [parts[1] intValue] == 1 ? YES : NO;
        }
        else if ([type isEqualToString:@"showCommandControl"]) {
            self.showCommandControl = [parts[1] intValue] == 1 ? YES : NO;
        }
        else if ([type isEqualToString:@"showFiringRange"]) {
            self.showFiringRange = [parts[1] intValue] == 1 ? YES : NO;
        }
        else if ([type isEqualToString:@"tutorialsCompleted"]) {
            self.tutorialsCompleted = [parts[1] intValue] == 1 ? YES : NO;
        }
        else if ([type isEqualToString:@"lastDownload"]) {
            self.lastDownload = [parts[1] intValue];
        }
    }
}


- (void) save {
    NSString * data = @"";

    if ( self.onlineName ) {
        data = [data stringByAppendingFormat:@"onlineName %@\n",     self.onlineName];
    }

    data = [data stringByAppendingFormat:@"soundsEnabled %d\n",      self.soundsEnabled == kEnabled ? 1 : 0];
    data = [data stringByAppendingFormat:@"musicEnabled %d\n",       self.musicEnabled == kEnabled ? 1 : 0];
    data = [data stringByAppendingFormat:@"showAllMissions %d\n",    self.showAllMissions ? 1 : 0];
    data = [data stringByAppendingFormat:@"showCommandControl %d\n", self.showCommandControl ? 1 : 0];
    data = [data stringByAppendingFormat:@"showFiringRange %d\n",    self.showFiringRange ? 1 : 0];
    data = [data stringByAppendingFormat:@"tutorialsCompleted %d\n", self.tutorialsCompleted ? 1 : 0];
    data = [data stringByAppendingFormat:@"lastDownload %d\n",       self.lastDownload];

    // write to file
    if ( ! [ResourceHandler saveData:data toResource:@"Settings.txt"] ) {
        CCLOG( @"failed to write settings file: %@", @"Settings.txt");
    }
    else {
        CCLOG( @"settings saved ok" );
    }
}

@end
