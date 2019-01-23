
#import <Foundation/Foundation.h>

#import "Definitions.h"

@interface Audio : NSObject

@property (nonatomic, assign) BOOL musicEnabled;
@property (nonatomic, assign) BOOL soundsEnabled;

- (void) playSound:(SoundType)sound;

- (void) playMusic:(MusicType)music;

- (void) stopMusic;

/**
 * Starts looping the given sound until stopped.
 **/
- (void) startSound:(LoopingSoundType)sound;
- (void) stopSound:(LoopingSoundType)sound;

@end
