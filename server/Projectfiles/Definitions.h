
#import "ParameterDefinitions.h"

// ****************************************************************************************************
// Version. The numeric versions come from Info.plist: CFBundleShortVersionString and CFBundleVersion
static NSString *const sVersionString = @"Beta 5";


// terrain types
typedef enum {
    kWoods = 0,
    kField,
    kGrass,
    kRoad,
    kRiver,
    kRoof,
    kSwamp,
    kRocky,
    kBeach,
    kFord,
    kScatteredTrees,
    kNoTerrain
} TerrainType;


// type of units
typedef enum {
    kInfantry,
    kCavalry,
    kArtillery,
    kInfantryHeadquarter,
    kCavalryHeadquarter,
} UnitType;


// the two players in the game
typedef enum {
    kPlayer1 = 0,
    kPlayer2,
} PlayerId;


typedef enum {
    kLocalPlayer,
    kNetworkPlayer,
    kAIPlayer
} PlayerType;

// battle size for multiplayer games
typedef enum {
    kSmallBattle,
    kMediumBattle,
    kLargeBattle,
    kNotIncluded,
} BattleSizeType;

typedef enum {
    kCampaign,
    kTutorial,
    kMultiplayer
} ScenarioType;

typedef enum {
    kAdvanceMission,
    kAssaultMission,
    kFireMission,
    kAreaFireMission,
    kSmokeMission,
    kMeleeMission,
    kMoveMission,
    kMoveFastMission,
    kRetreatMission,
    kRotateMission,
    kScoutMission,
    kChangeModeMission,
    kDisorganizedMission,
    kIdleMission,
    kRoutMission,
    kRallyMission,
} MissionType;


typedef enum {
    kFormation = 0,
    kColumn
} UnitMode;

typedef enum {
    kInProgress,
    kCompleted
} MissionState;


// z levels for stuff on the map layer
typedef enum {
    kAIDebugZ = 180,
    kQuestionPromptZ = 173,
    kQuitPromptZ = 172,
    kEndPromptZ = 171,
    kStartPromptZ = 170,
    kHelpOverlayZ = 165,
    kArmyStatus = 163,
    kGameOptionsZ = 162,
    kGameInfoZ = 161,
    kGameMenuZ = 160,
    kTutorialZ = 155,
    kActionsMenuZ = 151,
    kHudZ = 150,
    kOffmapArrowZ = 140,
    kMessageZ = 120,
    kMessageBackgroundZ = 119,
    kCombatReportZ = 110,
    kCombatReportBackgroundZ = 109,
    kSmokeZ = 107, 
    kExplosionEffectZ = 106, // just above the unit
    kUnitTypeIconZ = 104,
    kPathNodeZ = 103,
    kSelectionMarkerZ = 102,
    kUnitZ = 100,
    kBulletZ = 99,
    kFireEffectZ = 98, // just under the unit
    kUnitSelectionZ = 95,
    kLineOfSightVisualizerZ = 70,
    kRangeVisualizerZ = 55,
    kMissionVisualizerZ = 60,
    kCommandRangeVisualizerZ = 50,
    kObjectiveTitleZ = 31,
    kObjectiveZ = 30,
    kHouseZ = 25,
    kHouseShadowZ = 24,
    kCorpseZ = 22,
    kWoodsZ = 16,
    kScatteredTreesZ = 14,
    kRockyZ = 12,
    kTerrainZ = 10,
    kBackgroundZ = 0
} MapLayerZ;


// music types
typedef enum {
    kMenuMusic = 0,
    kVictoryJingle,
    kDefeatJingle,
    kInGameMusic,
} MusicType;

// sound effects
typedef enum {
    // setup
    kMenuButtonClicked = 0,
    kScenarioSelected,
    kScenarioDeselected,

    // in game
    kInGameMenuClicked,
    kActionClicked,
    kButtonClicked,
    kMapClicked,
    kUnitSelected,
    kUnitDeselected,
    kEnemyUnitSelected,
    kUnitNoActions,
    kMissionCancelled,

    // combat
    kInfantryFiring,
    kCavalryFiring,
    kArtilleryFiring,
    kMachinegunFiring,
    kFlamethrowerFiring,
    kMortarFiring,
    kHowitzerFiring,
    kSniperFiring,

    kAdvanceOrdered,
    kAssaultOrdered,
    kRetreatOrdered,
    kUnitDestroyed,
    kArtilleryExplosion,
} SoundType;

// looping sound effects
typedef enum {
    kMeleeCombat,
    kArtilleryMarching,
    kCavalryCharge,
    kCavalryMarching,
    kTroopsMarching,
    kTroopsAssaulting,
} LoopingSoundType;

typedef enum {
    kDisabled,
    kEnabled
} AudioState;

typedef enum {
    kSinglePlayerGame,
    kMultiplayerGame
} GameType;

// state of the scenario
typedef enum {
    kGameInProgress,
    kGameFinished
} ScenarioState;

// hints for the AI about the game type
typedef enum {
    kPlayer1Attacks = 0,
    kMeetingEngagement,
    kPlayer2Attacks
} AIHint;


// type of attack visualization
typedef enum {
    kDefenderDestroyed = 0x1,
    kDefenderLostMen = 0x2,
    kDefenderRouted = 0x4,
    kDefenderOutflanked = 0x8,
    kMeleeAttack = 0x10,
} AttackMessageType;

// type of messages
typedef enum {
    kNoStackingAllowed,
    kNewEnemySpotted,
    kNewEnemySpottedStopping,
    kNoMissions,
} MessageType;

// states for objectives
typedef enum {
    kOwnerPlayer1 = kPlayer1,
    kOwnerPlayer2 = kPlayer2,
    kContested,
    kNeutral
} ObjectiveState;

// weapon types
typedef enum {
    kRifle,
    kLightCannon,
    kHeavyCannon,
    kMachineGun,
    kFlamethrower,
    kRifleMk2,
    kSubmachineGun,
    kMortar,
    kHowitzer,
    kSniperRifle
} WeaponType;

// unit experience
typedef enum {
    kGreen,
    kRegular,
    kVeteran,
    kElite,
} ExperienceType;

// influence maps
typedef enum {
    kHumanUnitsMapType = 0,
    kAIUnitsMapType,
    kInfluenceMapType,
    kFrontlineMapType,
    kTensionMapType,
    kVulnerabilityMapType,
    kObjectivesMapType,
    kResultMapType,
    kMapTypeCount
} AIMapType;


// ****************************************************************************************************
// path finder debugging
static const BOOL sPathFinderDebugging = NO;

// force reload all updates again?
static const BOOL sReloadAllScenarios = NO;

// debug AI
static const BOOL sAIDebugging = YES;

// show all units
static const BOOL sShowAllUnitsDebugging = NO;

// debug AI potential fields
static const BOOL sPotentialFieldDebugging = NO;

// show all scenarios
static const BOOL sDebugAllScenarios = NO;

// disable AI entirely
static const BOOL sAIDisabled = NO;

// show FPS debugging info
static const BOOL sFpsDebugging = NO;

// is the online part enabled for multiplayer games?
static const BOOL sOnlineEnabled = YES;

// no Game Center
static const BOOL sDisableGameCenter = NO;

// should the scenario editor be enabled?
static const BOOL sEnableEditor = YES;

// load a hardcoded scenario for development?
static const BOOL sLoadHardcodedScenario = NO;

// ****************************************************************************************************
// engine parameters

// should we run any possible scripts
static const BOOL sRunScripts = NO;

// ****************************************************************************************************
// AI parameters

// the different forms of AI
typedef enum {
    kDefensive,
    kCautiousAttacking,
    kAggressiveAttacking
} AIAggressiveness;

// orders for AI organizations
typedef enum {
    kTakeObjective,
    kAdvanceTowardsEnemy,
    kHold
} AIOrganizationOrder;

// behavior tree result types
typedef enum {
    kRunning,
    kSucceeded,
    kFailed
} BehaviorTreeResult;

// ****************************************************************************************************
// Map parameters

// various line colors, see http://cloford.com/resources/colours/500col.htm

static const ccColor3B sFiringRangeLineColor = {200, 200, 200};
static const ccColor4B sCommandRangeLineColorNear = {255, 255, 0, 60};
static const ccColor4B sCommandRangeLineColorFar = {255, 255, 0, 160};
static const ccColor3B sSubordinateLineColor1 = {154, 205, 50};
static const ccColor3B sSubordinateLineColor2 = {205, 0, 0};

// mission line colors. moving
static const ccColor4B sMoveLineColor = {200, 200, 200, 200};
static const ccColor4B sMoveFastLineColor = {255, 255, 255, 200};
static const ccColor4B sRotateLineColor = {80, 255, 80, 200};

// scouting
static const ccColor4B sScoutLineColor = {58, 95, 205, 200}; // royalblue 3

// firing
static const ccColor4B sFireLineColor = {240, 240, 0, 160}; // yellow
static const ccColor4B sAreaFireLineColor = {255, 255, 200, 160}; // light yellow
static const ccColor4B sSmokeLineColor = {180, 180, 0, 160}; // dark, greenish yellow

// combat
static const ccColor4B sAdvanceLineColor = {139, 0, 0, 200};
static const ccColor4B sAssaultLineColor = {238, 0, 0, 200};
static const ccColor4B sMeleeLineColor = {255, 69, 0, 200};

// retreat, rout
static const ccColor4B sRetreatLineColor = {255, 100, 100, 200};
static const ccColor4B sRoutLineColor = {160, 32, 32, 200};

static const ccColor4B sChangeModeLineColor = {100, 100, 255, 200};
static const ccColor4B sIdleLineColor = {255, 255, 255, 200}; // white
static const ccColor4B sRallyLineColor = {135, 206, 255, 200}; // skyblue 1

// ****************************************************************************************************
// TcpNetworkHandler parameters

// the host to connect to
static NSString *const sServerHost = @"localhost";
//static NSString *const sServerHost = @"imperium.d-pointer.com";

// port on above host
static const unsigned short sServerPort = 11000;

// password. This must be synced with whatever the server is using
static NSString *const sServerPassword = @"1234567890";

// run online against an unsecure server
static const BOOL sUnsecureOnline = YES;

// new Python server
static const unsigned short sProtocolVersion = 1;
//static const unsigned short sProtocolVersion = 0;

// how often should the network connection try to reconnect on error
static const unsigned short sReconnectDelay = 5;

typedef enum {
    kLoginPacket = 0, // in
    kLoginOkPacket, // out
    kInvalidProtocolPacket,
    kAlreadyLoggedInPacket,
    kInvalidNamePacket, // error out
    kNameTakenPacket, // error out
    kServerFullPacket, // error out
    kAnnounceGamePacket, // in
    kAnnounceOkPacket, // out
    kAlreadyAnnouncedPacket, // error out
    kGameAddedPacket, // out
    kGameRemovedPacket, // 10
    kLeaveGamePacket, // in
    kNoGamePacket, // error out
    kJoinGamePacket, // in
    kGameJoinedPacket, // out
    kInvalidGamePacket, // error out
    kAlreadyHasGamePacket, // error out
    kGameFullPacket, // error out
    kGameEndedPacket, // out
    kDataPacket, // 20 out
    kReadyToStartPacket, // out

    kKeepAlivePacket,
    kPlayerCountPacket,

    kInvalidPasswordPacket,
} TcpNetworkPacketType;

// TCP data packets
typedef enum {
    kSetupUnitsPacket = 0,
    kGameResultPacket,
    kWindPacket,
} TcpNetworkPacketSubType;


typedef enum {
    kUdpPingPacket, // UDP in
    kUdpPongPacket, // UDP out
    kUdpDataPacket,
    kStartActionPacket,
} UdpNetworkPacketType;

// UDP data packets
typedef enum {
    kMissionPacket = 0,
    kUnitStatsPacket,
    kFirePacket,
    kMeleePacket,
    kSetMissionPacket,
    kPlayerPingPacket,
    kPlayerPongPacket,
    kSmokePacket,
} UdpNetworkPacketSubType;


// network login error reasons
typedef enum {
    kInvalidProtocolError,
    kAlreadyLoggedInError,
    kInvalidNameError,
    kNameTakenError,
    kServerFullError,
    kInvalidPasswordError
} NetworkLoginErrorReason;

// length of a TCP packet header (1 * unsigned short)
static const unsigned short sTcpPacketHeaderLength = 2;

typedef enum {
    kPlayer1Destroyed,
    kPlayer2Destroyed,
    kBothPlayersDestroyed,
    kTimeOut
} MultiplayerEndType;

// ****************************************************************************************************
// Serialization

// globals used for save file names
static NSString *const sSaveFileNameSingle = @"resume-single-%d.dat";
static NSString *const sSaveFileNameMulti = @"resume-multi.dat";

// globals used for notifications
static NSString * const sNotificationScenarioSelected            = @"ScenarioSelected";
static NSString * const sNotificationSelectedUnitMissionsChanged = @"SelectedUnitMissionsChanged";
static NSString * const sNotificationEngineSimulationDone        = @"EngineSimulationDone";
static NSString * const sNotificationEngineStateChanged          = @"EngineStateChanged";
static NSString * const sNotificationSelectionChanged            = @"SelectionChanged";
static NSString * const sNotificationQuitGame                    = @"GameQuit";
static NSString * const sNotificationGameBackgrounded            = @"GameBackgrounded";


