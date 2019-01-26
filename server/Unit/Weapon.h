
#import <Foundation/Foundation.h>
#import "Definitions.h"

@interface Weapon : NSObject

@property (nonatomic, readonly) WeaponType type;
@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) float      firepower;
@property (nonatomic, readonly) float      firingRange;
@property (nonatomic, readonly) float      firingAngle;
@property (nonatomic, readonly) float      reloadingTime;
@property (nonatomic, readonly) float      movementSpeedModifier;
@property (nonatomic, readonly) float      projectileSpeed;
@property (nonatomic, readonly) int        menRequired;
@property (nonatomic, readonly) BOOL       canFireSmoke;
@property (nonatomic, assign)   int        ammo;

- (id) initWithType:(WeaponType)type;

- (float) getFirepowerModifierForRange:(float)range;

- (float) getScatterForRange:(float)range;

@end
