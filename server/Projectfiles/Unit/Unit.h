
#import "cocos2d.h"
#import "Definitions.h"
#import "Mission.h"
#import "Weapon.h"
#import "LineOfSightData.h"

@class MissionVisualizer;
@class Organization;
@class AttackResult;

@interface Unit : CCSprite

@property (nonatomic, assign) int                 unitId;
@property (nonatomic, strong) NSString *          name;
@property (nonatomic, weak)   Unit *              headquarter;
@property (nonatomic, strong) Organization *      organization;
@property (nonatomic, assign) PlayerId            owner;
@property (nonatomic, assign) UnitType            type;
@property (nonatomic, assign) ExperienceType      experience;
@property (nonatomic, assign) BOOL                selected;
@property (nonatomic, assign) BOOL                isHeadquarter;
@property (nonatomic, assign) BOOL                isSupport;
@property (nonatomic, assign) float               lastFired;
@property (nonatomic, strong) Mission *           mission;
@property (nonatomic, strong) MissionVisualizer * missionVisualizer;
@property (nonatomic, strong) CCSprite *          unitTypeIcon;
@property (nonatomic, assign) UnitMode            mode;
@property (nonatomic, assign) int                 men;
@property (nonatomic, assign) int                 originalMen;
@property (nonatomic, assign) BOOL                inCommand;
@property (nonatomic, assign) float               morale;
@property (nonatomic, assign) float               fatigue;
@property (nonatomic, strong) Weapon *            weapon;
@property (nonatomic, assign) int                 weaponCount;
@property (nonatomic, assign) BOOL                autoFireEnabled;
@property (nonatomic, strong) CCSprite *          questionMark;
@property (nonatomic, strong) CCSprite *          offmapArrow;
@property (nonatomic, assign) int                 losIndex;
@property (nonatomic, strong) LineOfSightData *   losData;
@property (nonatomic, assign) float               formationWidth;

// attack result visualizations
@property (nonatomic, strong) AttackResult *      attackResult;

// AI data
@property (nonatomic, strong) CCLabelBMFont *     aiDebugging;
@property (nonatomic, assign) int                 aiUpdateCounter;

// readonly properties
@property (nonatomic, readonly) NSString *        modeName;
@property (nonatomic, readonly) float             movementSpeed;
@property (nonatomic, readonly) float             fastMovementSpeed;
@property (nonatomic, readonly) float             scoutingSpeed;
@property (nonatomic, readonly) float             retreatSpeed;
@property (nonatomic, readonly) float             advanceSpeed;
@property (nonatomic, readonly) float             assaultSpeed;
@property (nonatomic, readonly) float             rotationSpeed;
@property (nonatomic, readonly) float             advanceRange;
@property (nonatomic, readonly) float             assaultRange;
@property (nonatomic, readonly) float             visibilityRange;

@property (nonatomic, readonly) float             changeModeTime;
@property (nonatomic, readonly) float             commandRange;
@property (nonatomic, readonly) float             commandDelay;

@property (nonatomic, readonly) float             selectionRadius;

// time the unit is disorganized after a retreat
@property (nonatomic, readonly) float             organizingTime;
@property (nonatomic, readonly) BOOL              destroyed;

- (void) updateIcon;

- (void) smoothMoveTo:(CGPoint)position;
- (void) smoothTurnTo:(float)facing;

//- (BOOL) isHit:(CGPoint)pos;

- (BOOL) isCurrentMission:(MissionType)type;

- (BOOL) canFire;

- (BOOL) canBeGivenMissions;

- (BOOL) isIdle;

- (BOOL) isInsideFiringArc:(CGPoint)pos checkDistance:(BOOL)checkDistance;
- (BOOL) isOutflankedFromPos:(CGPoint)pos;

/**
 * Returns a string representing the unit's current state. The string ends with a newline.
 **/
- (NSString *) save;

// creates a new unit.
+ (Unit *) createUnitType:(UnitType)type
                 forOwner:(PlayerId)player
                     mode:(UnitMode)mode
                      men:(int)men
                   morale:(float)morale
                  fatigue:(float)fatigue
                   weapon:(WeaponType)weapon
               experience:(ExperienceType)experience
                     ammo:(int)ammo;

@end
