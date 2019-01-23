
// all parameters
typedef enum {
    kParamCommandRangeGreenF = 0,           // max command ranges in meters for units of various experience
    kParamCommandRangeRegularF,
    kParamCommandRangeVeteranF,
    kParamCommandRangeEliteF,
    kParamMaxTotalVisibilityF,              // max unobstructed distance an idle unit can see
    kParamMaxActiveVisibilityF,             // max unobstructed distance an unit can see when doing something
    kParamMaxVisibilityIntoWoodsF,          // max distance a unit can see into woods or out of woods
    kParamCommandDelayInCommandF,           // command delays when in command
    kParamCommandDelayNotInCommandF,        // command delays when not in command
    kParamMinMoraleForMissionsF,            // minimum morale for giving units missions
    kParamMaxFatigueForMissionsF,           // maximum fatigue for giving units missions
    kParamMinStackingDistanceF,             // min distance for two units that are stacking
    kParamMaxStackingRetriesI,              // max number of times that a unit will try to move to a position when there's another unit there
    kParamMaxPathLengthF,                   // max distance in meters for a mission path
    kParamMeleeMaxDistanceF,                // max distance for the unit to be from the target when meleeing
    kParamMinOutflankingDistanceF,          // min distance for outflanking positions
    kParamMaxTurnDeviationF,                // max angle for the unit to be from the target angle for it to have turned
    kParamMaxDistanceFromAssaultEndPointF,  // max distance for a unit to be from another unit's assault destination for it to be considered assaulting towards that unit

    kParamAdvanceRangeInfantryHeadquarterF, // max advance ranges in meters for unit types
    kParamAdvanceRangeInfantryF,
    kParamAdvanceRangeCavalryF,
    kParamAdvanceRangeCavalryHeadquarterF,
    kParamAdvanceRangeArtilleryF,
    kParamAssaultRangeInfantryHeadquarterF, // max assault ranges in meters for unit types
    kParamAssaultRangeInfantryF,
    kParamAssaultRangeCavalryF,
    kParamAssaultRangeCavalryHeadquarterF,
    kParamAssaultRangeArtilleryF,
    kParamEngineUpdateIntervalF,            // how often is the engine updated (seconds)
    kParamTimeMultiplierF,                  // the number of seconds in each step
    kParamLosUpdateIntervalF,               // how many seconds between a full engine LOS update
    kParamObjectiveOwnerUpdateIntervalF,    // how many simulation seconds between checking for objective owners
    kParamGameEndLingerUpdatesI,            // how many more updates after the game has ended

    // TODO: not yet in the parameter file
    kParamAdvanceReloadingMultiplierF,      // multiplier for the reloading time when advancing. Realoading while advancing is slower

    // ****************************************************************************************************
    // Objectives
    kParamObjectiveMaxDistanceF,            // max distance from an objective where a unit is considered to still own/contest it
    kParamObjectiveFullValueF,              // score values of objectives
    kParamObjectiveSharedValueF,            // score values of objectives
    kParamObjectiveRadiusF,                 // radius of an objective

    kParamEscortTargetRadiusF,              // target position radius for the escorting victory condition. anything inside the radius has arrived

    // ****************************************************************************************************
    // AI
    kParamMaxAIEngagedDistanceF,            // max distance for the unit to be angaged to a target
    kParamPathMapTileSizeI,                 // size of the tiles in the path finding mini map
    kParamPotentialFieldTileSizeI,          // tile size of the potential field
    kParamPotentialFieldPixelSizeI,         // pixel size of each tile in the potential field when debugging
    kParamUpdatePotentialFieldIntervalI,    // how often (in updates) is the potential field data updated?
    kParamUpdateStrategicPlannerIntervalI,  // how often (in updates) is the strategic planner executed?
    kParamAiExecutionIntervalI,             // how often (in updates) are the unit specific conditions updated?

    // ****************************************************************************************************
    // Map parameters
    kParamMaxBodiesI,                       // max number of bodies to show on the map
    kParamShowUnitTypeIconsB,               // show the unit type icons?
    kParamCommandRangeLineWidthF,           // width of command range line

    // Audio parameters
    kParamLoopingSoundGainF,                // gain for the looping sounds. 0..1, logarithmic scale?

    // ****************************************************************************************************
    // morale
    kParamMoraleRecoveryRallyingHqF,   // morale recovery per second while rallying
    kParamMoraleRecoveryInCommandF,    // morale recovery per second while in command
    kParamMoraleRecoveryNotInCommandF, // morale recovery per second while not in command
    kParamMoraleBoostDestroyEnemyF,    // morale boosts when an attacker destroys an enemy
    kParamMoraleBoostRoutEnemyF,       // morale boosts when an attacker routs an enemy
    kParamMoraleBoostDamageEnemyF,     // morale boosts when an attacker damages an enemy
    kParamMoraleLossDisorganizedF,
    kParamMoraleLossNotInCommandF,
    kParamMoraleLossAttackerArtilleryF,
    kParamMoraleLossUnitDestroyedF,    // morale loss in % for other units when a unit in an organization is destroyed
    kParamOutflankingMoraleModifierF,  // morale loss modifier when a unit is fired at by an outflanking unit
    kParamMaxMoraleRoutedF,            // limits for morale
    kParamMaxMoraleShakenF,            // limits for morale
    kParamMaxMoraleWorriedF,           // limits for morale
    kParamMaxMoraleCalmF,              // limits for morale

    // ****************************************************************************************************
    // mission fatigue effect in fatigue per minute
    kParamAdvanceFatigueEffectF,
    kParamAssaultFatigueEffectF,
    kParamChangeModeFatigueEffectF,
    kParamDisorganizedFatigueEffectF,
    kParamFireFatigueEffectF,
    kParamIdleFatigueEffectF,
    kParamMeleeFatigueEffectF,
    kParamMoveFatigueEffectF,
    kParamMoveFastFatigueEffectF,
    kParamRetreatFatigueEffectF,
    kParamRotateFatigueEffectF,
    kParamRoutMovingFatigueEffectF,
    kParamRoutStandingFatigueEffectF,
    kParamScoutFatigueEffectF,
    kParamRallyFatigueEffectF,


    // ****************************************************************************************************
    // last element is a count
    kParameterCount
} ParameterType;


// ****************************************************************************************************
// Global configurable parameters
typedef struct {
    int intValue;
    float floatValue;
    BOOL boolValue;
} Parameter;

// a global static array of all parameters
extern Parameter sParameters[kParameterCount];
