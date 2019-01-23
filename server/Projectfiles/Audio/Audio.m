
#import "SimpleAudioEngine.h"
#import "Audio.h"
#import "Settings.h"

@interface Audio ()

@property (nonatomic, strong) NSArray * loopingSounds;

@end


@implementation Audio

- (id)init {
    self = [super init];
    if (self) {
        Settings * settings = [Settings sharedInstance];

        _soundsEnabled = settings.soundsEnabled == kDisabled ? NO : YES;
        _musicEnabled  = settings.musicEnabled == kDisabled ? NO : YES;

        CCLOG( @"sounds: %d, music: %d", self.soundsEnabled, self.musicEnabled );

        // set up all the looping sounds
        self.loopingSounds = @[ [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"Audio/melee.wav"],
                                [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"Audio/artillery_marching.wav"],
                                [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"Audio/cavalry_charge.wav"],
                                [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"Audio/cavalry_march.wav"],
                                [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"Audio/troops_marching.wav"],
                                [[SimpleAudioEngine sharedEngine] soundSourceForFile:@"Audio/troops_assaulting.wav"]];
        
        // make all looping sounds loop and set a default gain/volume
        for ( CDSoundSource * source in self.loopingSounds ) {
            source.looping = YES;
            source.gain = sParameters[kParamLoopingSoundGainF].floatValue;
        }

        // some custom volumes
        CDSoundSource * melee = self.loopingSounds[ 0 ];
        melee.gain = 1.0f;
    }
    
    return self;
}


- (void) setSoundsEnabled:(BOOL)soundsEnabled {
    _soundsEnabled = soundsEnabled;

    [Settings sharedInstance].soundsEnabled = soundsEnabled ? kEnabled : kDisabled;
}


- (void) setMusicEnabled:(BOOL)musicEnabled {
    _musicEnabled = musicEnabled;

    [Settings sharedInstance].musicEnabled = musicEnabled ? kEnabled : kDisabled;

    // should we stop music?
    if ( ! musicEnabled ) {
        [self stopMusic];
    }
}


- (void) playSound:(SoundType)sound {
    // check if sounds should be played at all
    if ( ! self.soundsEnabled ) {
        return;
    }

    switch ( sound ) {
        case kMenuButtonClicked:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button.wav"];
            break;
            
        case kScenarioSelected:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/scenario_select.wav"];
            break;
            
        case kScenarioDeselected:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/scenario_deselect.wav"];
            break;

            // in game
        case kInGameMenuClicked:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button.wav"];
            break;

        case kActionClicked:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button_action.wav"];
            break;

        case kButtonClicked:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button.wav"];
            break;

        case kMapClicked:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/Real_obj.wav"];
            break;
            
        case kUnitSelected:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/Unit_select.wav"];
            break;

        case kUnitDeselected:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/Unit_deselect.wav"];
            break;

        case kEnemyUnitSelected:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button_map_unit_enemy_tap.wav"];
            break;

        case kUnitNoActions:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button_no_acitons.wav"];
            break;
            
        case kMissionCancelled:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/button_cancel_orders.wav"];
            break;

            // combat
        case kCavalryFiring:
        case kInfantryFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/infrantry_fire_%d.wav", 1 + arc4random_uniform( 3 )]];
            break;

        case kArtilleryFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/artillery_%d.wav", 1 + arc4random_uniform( 5 )]];
            break;

        case kArtilleryExplosion:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/cannon_explosion%d.wav", 1 + arc4random_uniform( 3 )]];
            CCLOG( @"playing explosion");
            break;

        case kMachinegunFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/machinegun_%d.wav", 1 + arc4random_uniform( 3 )]];
            break;

        case kFlamethrowerFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/flame_thrower_%d.wav", 1 + arc4random_uniform( 3 )]];
            break;

        case kMortarFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/mortar_%d.wav", 1 + arc4random_uniform( 2 )]];
            break;

        case kHowitzerFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"Audio/artillery_%d.wav", 1 + arc4random_uniform( 5 )]];
            break;

        case kSniperFiring:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/sniper_rifle.wav"];
            break;

        case kAdvanceOrdered:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/charge.wav"];
            break;

        case kAssaultOrdered:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/charge.wav"];
            break;

        case kRetreatOrdered:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/retreat.wav"];
            break;

        case kUnitDestroyed:
            [[SimpleAudioEngine sharedEngine] playEffect:@"Audio/unit_destroyed.wav"];
            break;

    }
}


- (void) playMusic:(MusicType)music {
    // check if sounds should be played at all
    if ( ! self.musicEnabled ) {
        return;
    }

    switch ( music ) {
        case kMenuMusic:
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"Audio/Main_Menu_loop.mp3"];
            break;

        case kVictoryJingle:
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"Audio/victory_sting.mp3" loop:NO];
            break;

        case kDefeatJingle:
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"Audio/defeat_sting.mp3" loop:NO];
            break;

        case kInGameMusic:
            [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"Audio/ambience_loop.mp3"];
            break;
    }
}


- (void) stopMusic {
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
}


- (void) startSound:(LoopingSoundType)sound {
    // check if sounds should be played at all
    if ( ! self.soundsEnabled ) {
        return;
    }

    // get the sound in question
    CDSoundSource * source = self.loopingSounds[ sound ];

    // already playing?
    if ( source.isPlaying ) {
        return;
    }

    if ( ! [source play] ) {
        CCLOG( @"failed to play sound: %d", sound );
    }
}


- (void) stopSound:(LoopingSoundType)sound {
    // get the sound in question
    CDSoundSource * source = self.loopingSounds[ sound ];

    // is it playing?
    if ( source.isPlaying ) {
        [source stop];
    }
}

@end
