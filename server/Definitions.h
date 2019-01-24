
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

// load a hardcoded scenario for development?
static const BOOL sLoadHardcodedScenario = NO;

// ****************************************************************************************************
// engine parameters

// ****************************************************************************************************
// AI parameters

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
// Notifications

// globals used for notifications
static NSString * const sNotificationScenarioSelected            = @"ScenarioSelected";
static NSString * const sNotificationSelectedUnitMissionsChanged = @"SelectedUnitMissionsChanged";
static NSString * const sNotificationEngineSimulationDone        = @"EngineSimulationDone";
static NSString * const sNotificationEngineStateChanged          = @"EngineStateChanged";
static NSString * const sNotificationSelectionChanged            = @"SelectionChanged";
static NSString * const sNotificationQuitGame                    = @"GameQuit";
static NSString * const sNotificationGameBackgrounded            = @"GameBackgrounded";


