
#import "Definitions.h"

/**
 * A modifier that reduces movement speed for a unit entering the terrain.
 **/
static float terrainMovementModifiers[][5] = {
    // infantry, cavalry, artillery, infantry hq, cavalry hq

    { 0.5f, 0.4f, 0.2f, 0.5f, 0.4f },    // woods
    { 0.8f, 0.8f, 0.8f, 0.8f, 0.8f },    // Field
    { 1.0f, 1.0f, 1.0f, 1.0f, 1.0f },    // Grass
    { 1.5f, 1.8f, 1.5f, 1.5f, 1.8f },    // Road
    { -1.0f, -1.0f, -1.0f, -1.0f, -1.0f }, // River
    { 0.5f, 0.5f, 0.3f, 0.5f, 0.5f },    // Roof
    { 0.2f, 0.1f, -1.0f, 0.2f, 0.1f },   // Swamp
    { 0.8f, 0.6f, -1.0f, 0.8f, 0.6f },   // Rocky
    { 0.9f, 0.8f, 0.3f, 0.9f, 0.8f },    // Beach
    { 0.3f, 0.3f, 0.2f, 0.3f, 0.3f },    // ford
    { 0.8f, 0.5f, 0.7f, 0.8f, 0.5f }     // scattered trees
};

/**
 * Costs used when doing pathfinding.
 **/
static int terrainPathFindingCosts[][5] = {
    // infantry, cavalry, artillery, infantry hq, cavalry hq

    { 4, 5, 0, 4, 5 },    // woods
    { 3, 2, 3, 3, 2 },    // Field
    { 2, 2, 2, 2, 2 },    // Grass
    { 1, 1, 1, 1, 1 },    // Road
    { 0, 0, 0, 0, 0 },    // River
    { 0, 0, 0, 0, 0 },    // Roof
    { 6, 6, 0, 6, 6 },    // Swamp
    { 3, 4, 0, 3, 4 },    // Rocky
    { 2, 3, 5, 2, 3 },    // Beach
    { 6, 5, 6, 6, 5 },    // ford
    { 3, 3, 4, 3, 3 }     // scattered trees
};


/**
 * A modifier that reduces damage to a unit that stands on the terrain.
 **/
static float terrainDefensiveModifiers[] = {
    0.6f, // woods
    1.0f, // field
    0.9f, // grass
    1.0f, // road
    1.0f, // river
    0.6f, // roof
    0.8f, // swamp
    0.5f, // rocky
    1.0f, // beach
    1.0f, // ford
    0.8f  // scattered trees
};


/**
 * A modifier that reduces firepower for a unit that stands on the terrain.
 **/
static float terrainOffensiveModifiers[][5] = {
    // infantry, cavalry, artillery, infantry hq, cavalry hq
    
    { 0.8f, 0.8f, 0.6f, 0.8f, 0.8f }, // woods
    { 1.0f, 1.0f, 1.0f, 0.8f, 1.0f }, // field
    { 1.0f, 1.0f, 1.0f, 0.8f, 1.0f }, // grass
    { 1.0f, 1.0f, 1.0f, 0.8f, 1.0f }, // road
    { 1.0f, 1.0f, 0.6f, 0.8f, 1.0f }, // river
    { 0.9f, 0.9f, 0.9f, 0.9f, 0.9f }, // roof
    { 0.7f, 0.6f, 0.7f, 0.7f, 0.6f }, // swamp
    { 0.9f, 0.8f, 0.6f, 0.9f, 0.8f }, // rocky
    { 1.0f, 1.0f, 1.0f, 1.0f, 1.0f }, // beach
    { 0.8f, 0.7f, 0.2f, 0.8f, 0.7f }, // ford
    { 0.9f, 0.8f, 0.7f, 0.9f, 0.8f }, // scattered trees
};

/**
 * Returns a value that modifies the unit movement speed for the given terrain type.
 **/
static float getTerrainMovementModifier (Unit * unit, TerrainType terrain_type) {
    return terrainMovementModifiers[ terrain_type ][ unit.type ];
}

/**
 * Returns a value that modifies a defenders combat value.
 **/
static float getTerrainDefensiveModifier (TerrainType terrain_type) {
    return terrainDefensiveModifiers[ terrain_type ];
}

/**
 * Returns a value that modifies an attackers combat value.
 **/
static float getTerrainOffensiveModifier (Unit * attacker, TerrainType terrain_type) {
    return terrainOffensiveModifiers[ terrain_type ][ attacker.type ];;
}

/**
 * Returns a value that modifies the unit movement speed for the given terrain type.
 **/
static int getTerrainPathFindingCost (Unit * unit, TerrainType terrain_type) {
    return terrainPathFindingCosts[ terrain_type ][ unit.type ];
}
