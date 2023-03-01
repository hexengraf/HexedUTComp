class MutUTComp extends Mutator;

// #exec OBJ LOAD FILE="Textures\minimegatex.utx" PACKAGE=UTCompOmni
#exec OBJ LOAD FILE="Textures\minimegatex.utx"

var bool bEnableVoting;
var config bool bEnableBrightskinsVoting;
var config bool bEnableHitsoundsVoting;
var config bool bEnableTeamOverlayVoting;
var config bool bEnablePowerupsOverlayVoting;
var config bool bEnableMapVoting;
var config bool bEnableGametypeVoting;
var config bool bEnableTimedOvertimeVoting;
var bool bEnableDoubleDamageVoting;
var config float VotingPercentRequired;
var config float VotingTimeLimit;

var config bool bEnableDoubleDamage;
var config byte EnableBrightSkinsMode;
var config bool bEnableClanSkins;
var config bool bEnableTeamOverlay;
var config bool bEnablePowerupsOverlay;
var config byte EnableHitSoundsMode;

var bool bEnableScoreboard;

var config bool bEnableWeaponStats;
var config bool bEnablePowerupStats;
var config bool bShowTeamScoresInServerBrowser;

var config byte ServerMaxPlayers;
var config bool bEnableAdvancedVotingOptions;
var config array<string> AlwaysUseThisMutator;

var config bool bEnableAutoDemoRec;
var config string AutoDemoRecMask;

var config bool bForceMapVoteMatchPrefix;
var config bool bEnableTimedOvertime;
var config int TimedOverTimeLength;
var config int NumGrenadesOnSpawn;

var bool bDemoStarted;

var config bool bShieldFix;
var config bool  bAllowRestartVoteEvenIfMapVotingIsTurnedOff;

var config int MaxMultiDodges;

var config int MinNetSpeed;
var config int MaxNetSpeed;

// CTF-related
var config int CapBonus, FlagKillBonus, CoverBonus, SealBonus, GrabBonus, MinimalCapBonus;
var config float BaseReturnBonus, MidReturnBonus, EnemyBaseReturnBonus, CloseSaveReturnBonus;

var config byte CoverMsgType;
var config byte CoverSpreeMsgType;
var config byte SealMsgType;
var config byte SavedMsgType;

var config bool bShowSealRewardConsoleMsg;
var config bool bShowAssistConsoleMsg;

var config int SuicideInterval;

var config int NodeIsolateBonusPct;
var config int VehicleHealScore;
var config int VehicleDamagePoints;
var config bool bDebugLogging;  // config flag to turn on debug logging and/or client messages
var config int PowerCoreScore;
var config int PowerNodeScore;
var config int NodeHealBonusPct;
var config bool bNodeHealBonusForLockedNodes;
var config bool bNodeHealBonusForConstructor;

var config int NewNetUpdateFrequency;
var config float PingTweenTime;
var config bool bSilentAdmin;
var config bool bEnableWhitelist;
var config bool bUseWhitelist;
var config string WhitelistBanMessage;


struct MapVotePair
{
    var string GametypeOptions;
    var string GametypeName;
};

var config array<MapVotePair> VotingGametype;

var UTComp_ServerReplicationInfo RepInfo;
var UTComp_OverlayUpdate OverlayClass;
var UTComp_VotingHandler VotingClass;
var bool bHasInteraction;

var string origcontroller;
var class<PlayerController> origcclass;

var float StampArray[256];
var float counter;
var controller countercontroller;
var pawn counterpawn;

var string FriendlyVersionPrefix;
var string FriendlyVersionNumber;

struct PowerupInfoStruct
{
    var xPickupBase PickupBase;
    var int Team;
    var float NextRespawnTime;
    var PlayerReplicationInfo LastTaker;
};

var PowerupInfoStruct PowerupInfo[8];


/*    List Of Features to be completed(see utcomp_v2.txt for details)
========Not Started========
Extra Hud Clock
========In Progress========
Overtime
=========Completed=========
Scoreboard
Onjoin box
Voting
Optional Standard Server Compatibility
Force Models
BrightSkins
Autoscreenshot
Clanskins
Hitsounds
Weapon Stats
Client Console Commands
Spectator Console Commands
Powerup Stats
Various Server Settings
InGame Clock
Coaching
Team Overlay
Autodemorec
Quick Map Restarts
Crosshair Factory
Colored Names
*/

//==========================
//  Begin Enhanced Netcode stuff
//==========================

var PawnCollisionCopy PCC;

var TimeStamp StampInfo;

var float AverDT;
var float ClientTimeStamp;

var array<float> DeltaHistory;
var bool bEnhancedNetCodeEnabledAtStartOfMap;

var config bool bEnableEnhancedNetCode;
var config bool bEnableEnhancedNetCodeVoting;
var config float MinNetUpdateRate;
var config float MaxNetUpdateRate;

var FakeProjectileManager FPM;

const AVERDT_SEND_PERIOD = 4.00;
var float LastReplicatedAverDT;

// newnet 
var class<weapon> WeaponClasses[13];
var string WeaponClassNames[13];

//utcomp
var class<weapon> WeaponClassesUTComp[13];
var string WeaponClassNamesUTComp[13];

var class<Weapon> ReplacedWeaponClasses[13];

var class<WeaponPickup> ReplacedWeaponPickupClasses[13];

//newnet
var class<WeaponPickup> WeaponPickupClasses[13];
var string WeaponPickupClassNames[13];

//utcomp
var class<WeaponPickup> WeaponPickupClassesUTComp[13];
var string WeaponPickupClassNamesUTComp[13];

var bool bDefaultWeaponsChanged;


//==========================
//  End Enhanced Netcode stuff
//==========================

var config array<string> IgnoredHitSounds;

var UTComp_ONSGameRules ONSGameRules;

var config bool bUseDefaultScoreboardColor;
var config float PawnCollisionHistoryLength;
var UTComp_Whitelist Whitelist;

function PreBeginPlay()
{
    bEnhancedNetCodeEnabledAtStartOfMap = bEnableEnhancedNetCode;

    ReplacePawnAndPC();
    SetupVoting();
    SetupColoredDeathMessages();
    StaticSaveConfig();
    SetupFlags();
    SetupPowerupInfo();
    SetupWhitelist();

    super.PreBeginPlay();
}

function SetupPowerupInfo()
{
    local xPickupBase pickupBase;
    local int i;
    local byte shieldPickupCount;
    local byte uDamagePickupCount;
    local byte kegPickupCount;
    local bool forceTeam; // Force finding a team if there's 2 powerups of the same type.

    foreach AllActors(class'xPickupBase', pickupBase)
    {

        if (pickupBase.PowerUp == class'XPickups.SuperShieldPack' || pickupBase.PowerUp == class'XPickups.SuperHealthPack' || pickupBase.PowerUp == class'XPickups.UDamagePack')
        {
            PowerupInfo[i].PickupBase = pickupBase;

            if (pickupBase.myPickUp != None)
                PowerupInfo[i].NextRespawnTime = pickupBase.myPickUp.GetRespawnTime() + pickupBase.myPickup.RespawnEffectTime + Level.GRI.ElapsedTime;

            if (pickupBase.PowerUp == class'XPickups.SuperShieldPack')
                shieldPickupCount++;
            else if (pickupBase.PowerUp == class'XPickups.SuperHealthPack')
                kegPickupCount++;
            else if (pickupBase.PowerUp == class'XPickups.UDamagePack')
                uDamagePickupCount++;

            i++;

            if (i == 8)
            break;
        }
    }

    for (i = 0; i < 8; i++)
    {
        if (PowerupInfo[i].PickupBase == None)
            break;

        forceTeam = false;

        if (PowerupInfo[i].PickupBase.PowerUp == class'XPickups.SuperShieldPack' && shieldPickupCount == 2)
            forceTeam = true;
        else if (PowerupInfo[i].PickupBase.PowerUp == class'XPickups.SuperHealthPack' && kegPickupCount == 2)
            forceTeam = true;
        else if (PowerupInfo[i].PickUpBase.PowerUp == class'XPickups.UDamagePack' && uDamagePickupCount == 2)
            forceTeam = true;

        PowerupInfo[i].Team = GetTeamNum(PowerupInfo[i].PickupBase, forceTeam);
    }

}

function LogPickup(Pawn other, Pickup item)
{
    local int i;

    for (i = 0; i < 8; i++)
    {
        if (PowerupInfo[i].PickupBase == None)
            break;

        if (PowerupInfo[i].PickupBase.myPickup == item)
        {
            PowerupInfo[i].NextRespawnTime = item.GetRespawnTime() - item.RespawnEffectTime + Level.GRI.ElapsedTime;
            PowerupInfo[i].LastTaker = other.PlayerReplicationInfo;
        }
    }

    if (i > 0)
    {
        SortPowerupInfo(0, i - 1);
    }
}

function SortPowerupInfo(int low, int high)
{
  //  low is the lower index, high is the upper index
  //  of the region of array a that is to be sorted
  local Int i, j;
  local float x;
  Local PowerupInfoStruct Temp;

  i = Low;
  j = High;
  x = PowerupInfo[(Low + High) / 2].NextRespawnTime;

  //  partition
  do
  {
   while (PowerupInfo[i].NextRespawnTime < x)
      i += 1;
    while ((PowerupInfo[j].NextRespawnTime > x) && (x > 0))
     j -= 1;

    if (i <= j)
    {
     // swap array elements, inlined
     Temp = PowerupInfo[i];
      PowerupInfo[i] = PowerupInfo[j];
      PowerupInfo[j] = Temp;
      i += 1;
      j -= 1;
    }
  } until (i > j);

  //  recursion
  if (low < j)
    SortPowerupInfo(low, j);
  if (i < high)
    SortPowerupInfo(i, high);
}

function int GetTeamNum(Actor a, bool forceTeam)
{
    local string locationName;
    local Volume V;
    local Volume Best;
    local CTFBase FlagBase;
    local CTFBase RedFlagBase;
    local CTFBase BlueFlagBase;

    locationName = a.Region.Zone.LocationName;

    if (Instr(Caps(locationName), "RED" ) != -1)
        return 0;

    if (Instr(Caps(locationName), "BLUE" ) != -1)
        return 1;

    // For example the 100 in Citadel, we need to find in what volume it is.
    foreach AllActors( class'Volume', V )
    {
        if( V.LocationName == "" || V.LocationName == class'Volume'.default.LocationName)
            continue;

        if( (Best != None) && (V.LocationPriority <= Best.LocationPriority) )
            continue;

        if( V.Encompasses(a) )
            Best = V;
    }

    if (Best != None)
    {
        Log("BestName"@a@Best.LocationName);
        if (Instr(Caps(Best.LocationName), "RED" ) != -1)
            return 0;
        if (Instr(Caps(Best.LocationName), "BLUE" ) != -1)
            return 1;
    }

    if (forceTeam && Level.Game.IsA('xCTFGame'))
    {
        // Well we will look at the distance from the flag base...


        ForEach DynamicActors(class 'CTFBase', FlagBase)
        {
            if (FlagBase.DefenderTeamIndex == 0)
                RedFlagBase = flagBase;
            else
                BlueFlagBase = flagBase;
        }

        if (RedFlagBase != None && BlueFlagBase != None)
        {
            if (VSize(a.Location - RedFlagBase.Location) < VSize(a.Location - BlueFlagBase.Location))
                return 0;
            else
                return 1;
        }
    }

    return 255;
}

/* Change the flags the the UTComp one so we can track caps and assists. */
function SetupFlags()
{
    local CTFBase FlagBase;

    if (!Level.Game.IsA('xCTFGame'))
        return;

    ForEach DynamicActors(class 'CTFBase', FlagBase)
    {
        if (FlagBase.DefenderTeamIndex == 0)
            FlagBase.FlagType = class'UTComp_xRedFlag';
        else
            FlagBase.FlagType = class'UTComp_xBlueFlag';
    }
}

function SetupColoredDeathMessages()
{
    if(Level.Game.DeathMessageClass==class'xGame.xDeathMessage')
        Level.Game.DeathMessageClass=class'UTComp_xDeathMessage';
    else if(Level.Game.DeathMessageClass==Class'SkaarjPack.InvasionDeathMessage')
        Level.Game.DeathMessageClass=class'UTComp_InvasionDeathMessage';
}


function SetupWhitelist()
{
    if(Role == Role_Authority)
    {
        if (Whitelist == none) {
            Whitelist = new(none, "Whitelist") class'UTComp_Whitelist';
            Whitelist.StaticSaveConfig();
        }
    }
}

function ModifyPlayer(Pawn Other)
{
    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        SpawnCollisionCopy(Other);
        RemoveOldPawns();
    }

    if (UTComp_xPawn(Other) != none) {
        UTComp_xPawn(Other).MultiDodgesRemaining = RepInfo.MaxMultiDodges;
    }

    Super.ModifyPlayer(Other);

    if (ONSOnslaughtGame(Level.Game) != none && Other != none && Other.PlayerReplicationInfo != none && UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo) != none)
	{
		if (UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).MutatorOwner == none)
			UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).MutatorOwner = self;

		if (!UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).bInitializedVSpawnList
			|| UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).LastInitialiseTeam != Other.GetTeamNum())
		{
			ONSGameRules.InitialiseVehicleSpawnList(UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo));
			UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).bInitializedVSpawnList = True;
			UTComp_ONSPlayerReplicationInfo(Other.PlayerReplicationInfo).LastInitialiseTeam = Other.GetTeamNum();
		}
    }
}


/*
function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	SpawnCollisionCopy(V);

    if( NextMutator != none )
		NextMutator.DriverEnteredVehicle(V, P);
}
*/

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
    local PawnCollisionCopy C;
    if(RepInfo != none && RepInfo.bEnableEnhancedNetCode)
    {
        C = PCC;
        while(C != None)
        {
            if(C.CopiedPawn == P)
            {
                C.SetPawn(V);
                break;
            }
            C = C.Next;
        }
    }

    if( NextMutator != none )
		NextMutator.DriverEnteredVehicle(V, P);
}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
    local PawnCollisionCopy C;

    if(RepInfo != None && RepInfo.bEnableEnhancedNetCode)
    {
        C = PCC;
        while(C != None)
        {
            if(C.CopiedPawn == V)
            {
                C.SetPawn(P);
                break;
            }
            C = C.Next;
        }
    }

    if( NextMutator != none )
		NextMutator.DriverLeftVehicle(V, P);
}

function SpawnCollisionCopy(Pawn Other)
{

    if(PCC==None)
    {
        PCC = Spawn(class'PawnCollisionCopy');
        PCC.SetPawn(Other);
    }
    else
        PCC.AddPawnToList(Other);

}

function RemoveOldPawns()
{
    PCC = PCC.RemoveOldPawns();
}

function ListPawns()
{
    local PawnCollisionCopy PCC2;
    for(PCC2=PCC; PCC2!=None; PCC2=PCC2.Next)
       PCC2.Identify();
}

static function bool IsPredicted(actor A)
{
   if(A == none || A.IsA('xPawn'))
       return true;
   //Fix up vehicle a bit, we still wanna predict if its in the list w/o a driver
   if((A.IsA('Vehicle') && Vehicle(A).Driver!=None))
       return true;
   return false;
}


function SetupTeamOverlay()
{
    if((!bEnableTeamOverlay && !bEnablePowerupsOverlay) || !Level.Game.bTeamGame)
        return;
    if (OverlayClass==None)
    {
        OverlayClass=Spawn(class'UTComp_OverlayUpdate', self);
        OverlayClass.UTCompMutator=self;
        OverlayClass.InitializeOverlay();
    }
}

function SetupVoting()
{
    if(!bEnableVoting)
        return;
    if(VotingClass==None)
    {
        VotingClass=Spawn(class'UTComp_VotingHandler', self);
        VotingClass.fVotingTime=VotingTimeLimit;
        VotingClass.fVotingPercent=VotingPercentRequired;
        VotingClass.InitializeVoting();
        VotingClass.UTCompMutator=Self;
    }
}

simulated function Tick(float DeltaTime)
{
    local PlayerController PC;
    local Mutator M;
    local int x;

    //if(Level.NetMode==NM_DedicatedServer)
    if(Level.NetMode==NM_DedicatedServer || Level.NetMode == NM_ListenServer)
    {
        if(bEnhancedNetCodeEnabledAtStartOfMap)
        {
            if (bDefaultWeaponsChanged == false) {
                bDefaultWeaponsChanged = true;
                // replace DefaultWeaponName (fix for simple Arena mutators)
                for(M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
                    if (M.DefaultWeaponName != "")
                        for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
                            if (M.DefaultWeaponName ~= WeaponClassNames[x])
                                M.DefaultWeaponName = string(WeaponClasses[x]);
            }

            ClientTimeStamp+=DeltaTime;
            counter+=1;
            StampArray[counter%256] = ClientTimeStamp;
            AverDT = (9.0*AverDT + DeltaTime) * 0.1;
            SetPawnStamp();
            if(ClientTimeStamp > LastReplicatedAverDT + AVERDT_SEND_PERIOD)
            {
                StampInfo.ReplicatedAverDT(AverDT);
                LastReplicatedAverDT = ClientTimeStamp;
            }
        }
        else
        {
            if (bDefaultWeaponsChanged == false) {
                bDefaultWeaponsChanged = true;
                // replace DefaultWeaponName (fix for simple Arena mutators)
                for(M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
                    if (M.DefaultWeaponName != "")
                        for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
                            if (M.DefaultWeaponName ~= WeaponClassNames[x])
                                M.DefaultWeaponName = string(WeaponClassesUTComp[x]);
            }
        }

        if (!bEnableAutoDemoRec || bDemoStarted || Level.Game.bWaitingToStartMatch)
            return;
        else
           AutoDemoRecord();
        return;
    }

    if( FPM==None && Level.NetMode == NM_Client)
        FPM = Spawn(Class'FakeProjectileManager');

    if(bHasInteraction)
        return;
    PC=Level.GetLocalPlayerController();

    if(PC!=None)
    {
        BS_xPlayer(PC).Overlay = UTComp_Overlay(PC.Player.InteractionMaster.AddInteraction(string(class'UTComp_Overlay'), PC.Player));
        bHasInteraction=True;
        class'DamTypeLinkShaft'.default.bSkeletize=false;
    }
}

function SetPawnStamp()
{
   local rotator R;
   local int i;

   if(counterpawn==none)
   {
       if(countercontroller==none)
           countercontroller = spawn(class'TimeStamp_Controller');
       if(countercontroller.pawn!=None)
           counterpawn=countercontroller.pawn;
       return;
   }

   R.Yaw = (counter%256)*256;
   i=counter/256;
   R.Pitch = i*256;

   counterpawn.SetRotation(R);
}

simulated function float GetStamp(int stamp)
{
   return StampArray[stamp%256];
}

function ReplacePawnAndPC()
{
    if(Level.Game.DefaultPlayerClassName~="xGame.xPawn")
        Level.Game.DefaultPlayerClassName=string(class'UTComp_xPawn');
    if(class'xPawn'.default.ControllerClass==class'XGame.XBot') //bots don't skin otherwise
        class'xPawn'.default.ControllerClass=class'UTComp_xBot';

    Level.Game.PlayerControllerClassName=string(class'BS_xPlayer');
}

function SpawnReplicationClass()
{
    local int i;
    if(RepInfo==None)
        RepInfo=Spawn(class'UTComp_ServerReplicationInfo', self);

    RepInfo.bEnableVoting=bEnableVoting;
    RepInfo.EnableBrightSkinsMode=Clamp(EnableBrightSkinsMode,1,3);
    RepInfo.bEnableClanSkins=bEnableClanSkins;
    RepInfo.bEnableTeamOverlay=bEnableTeamOverlay;
    RepInfo.bEnablePowerupsOverlay=bEnablePowerupsOverlay;
    RepInfo.EnableHitSoundsMode=EnableHitSoundsMode;
    RepInfo.bEnableScoreboard=bEnableScoreboard;
    RepInfo.bEnableWeaponStats=bEnableWeaponStats;
    RepInfo.bEnablePowerupStats=bEnablePowerupStats;
    RepInfo.bEnableBrightskinsVoting=bEnableBrightskinsVoting;
    RepInfo.bEnableHitsoundsVoting=bEnableHitsoundsVoting;
    RepInfo.bEnableTeamOverlayVoting=bEnableTeamOverlayVoting;
    RepInfo.bEnablePowerupsOverlayVoting=bEnablePowerupsOverlayVoting;
    RepInfo.bEnableMapVoting=bEnableMapVoting;
    RepInfo.bEnableGametypeVoting=bEnableGametypeVoting;
    RepInfo.ServerMaxPlayers=ServerMaxPlayers;
    RepInfo.bEnableDoubleDamage=bEnableDoubleDamage;
    RepInfo.bEnableDoubleDamageVoting=bEnableDoubleDamageVoting;
    RepInfo.MaxPlayersClone=Level.Game.MaxPlayers;
    RepInfo.bEnableAdvancedVotingOptions=bEnableAdvancedVotingOptions;
    RepInfo.bEnableTimedOvertimeVoting=bEnableTimedOvertimeVoting;
    RepInfo.bEnableTimedOvertime=bEnableTimedOvertime;
    RepInfo.bEnableEnhancedNetcode=bEnableEnhancedNetcode;
    RepInfo.bEnableEnhancedNetcodeVoting=bEnableEnhancedNetcodeVoting;
    RepInfo.MaxMultiDodges = MaxMultiDodges;
    RepInfo.MinNetSpeed = MinNetSpeed;
    RepInfo.MaxNetSpeed = MaxNetSpeed;
    RepInfo.bShieldFix=bShieldFix;
    RepInfo.bAllowRestartVoteEvenIfMapVotingIsTurnedOff = bAllowRestartVoteEvenIfMapVotingIsTurnedOff;

    RepInfo.NewNetUpdateFrequency = NewNetUpdateFrequency;
    RepInfo.PingTweenTime = PingTweenTime;
    RepInfo.NodeIsolateBonusPct=NodeIsolateBonusPct;
    RepInfo.VehicleHealScore=VehicleHealScore;
    RepInfo.VehicleDamagePoints=VehicleDamagePoints;
    RepInfo.PowerCoreScore=PowerCoreScore;
    RepInfo.PowerNodeScore=PowerNodeScore;
    RepInfo.NodeHealBonusPct=NodeHealBonusPct;
    RepInfo.bNodeHealBonusForLockedNodes = bNodeHealBonusForLockedNodes;
    RepInfo.bNodeHealBonusForConstructor = bNodeHealBonusForConstructor;
    RepInfo.bSilentAdmin=bSilentAdmin;
    RepInfo.bEnableWhitelist=bEnableWhitelist;
    RepInfo.bUseWhitelist=bUseWhitelist;
    RepInfo.WhitelistBanMessage=WhitelistBanMessage;
    RepInfo.bUseDefaultScoreboardColor = bUseDefaultScoreboardColor;
    RepInfo.bDebugLogging = bDebugLogging;

    for(i=0; i<VotingGametype.Length && i<ArrayCount(RepInfo.VotingNames); i++)
        RepInfo.VotingNames[i]=VotingGametype[i].GameTypeName;

    for(i=0; i<VotingGametype.Length && i<ArrayCount(RepInfo.VotingOptions); i++)
        RepInfo.VotingOptions[i]=VotingGametype[i].GameTypeOptions;

    if(Level.Game.IsA('CTFGame') || Level.Game.IsA('ONSOnslaughtGame') || Level.Game.IsA('ASGameInfo') || Level.Game.IsA('xBombingRun')
    || Level.Game.IsA('xMutantGame') || Level.Game.IsA('xLastManStandingGame') || Level.Game.IsA('xDoubleDom') || Level.Game.IsA('Invasion'))
    {
       bEnableTimedOvertime=False;
    }

    RepInfo.NetUpdateTime=Level.TimeSeconds-1;
}

function PostBeginPlay()
{
	local UTComp_GameRules G;
	local mutator M;
	local string URL;


	Super.PostBeginPlay();

	URL = Level.GetLocalURL();
	URL = Mid(URL, InStr(URL, "?"));
	ParseURL(URl);
    SetupTeamOverlay();
    SpawnReplicationClass();

    G = spawn(class'UTComp_GameRules');
    G.UTCompMutator=self;
	G.OVERTIMETIME=TimedOverTimeLength;

    Level.Game.AddGameModifier(G);

    if(ONSOnslaughtGame(Level.Game) != none)
    {
        ONSGameRules = Spawn(Class'UTComp_ONSGameRules', self);
        ONSGameRules.OPInitialise();
        Level.Game.AddGameModifier(ONSGameRules);

		ONSOnslaughtGame(Level.Game).GameUMenuType = string(Class'UTComp_ONSLoginMenu');

    }

    if(StampInfo == none && bEnhancedNetCodeEnabledAtStartOfMap)
       StampInfo = Spawn(class'TimeStamp');

    for(M=Level.Game.BaseMutator; M!=None; M=M.NextMutator)
    {
        if(string(M.Class)~="SpawnGrenades.MutSN")
            return;
    }
    class'GrenadeAmmo'.default.InitialAmount = NumGrenadesOnSpawn;
}

simulated function bool InStrNonCaseSensitive(String S, string S2)
{
    local int i;
    for(i=0; i<=(Len(S)-Len(S2)); i++)
    {
        if(Mid(S, i, Len(s2))~=S2)
            return true;
    }
    return false;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local LinkedReplicationInfo lPRI;
    local int x, i;
	local WeaponLocker L;

    bSuperRelevant = 0;

    if (Controller(Other) != None && MessagingSpectator(Other) == None && ONSOnslaughtGame(Level.Game) != none )
		Controller(Other).PlayerReplicationInfoClass = class'UTComp_ONSPlayerReplicationInfo';
    
    if ( GameReplicationInfo(Other) != None )
    {
        GameReplicationInfo(Other).bFastWeaponSwitching = true;
    }

    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        // use NewNet weapons
        if (xWeaponBase(Other) != None)
    	{
	    	for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
	    		if (xWeaponBase(Other).WeaponType == ReplacedWeaponClasses[x])
	    		{
                	xWeaponBase(Other).WeaponType = WeaponClasses[x];
                 }
	    	         	return true;

        }
	    else if (WeaponPickup(Other) != None)
    	{
             for (x = 0; x < ArrayCount(ReplacedWeaponPickupClasses); x++)
		    	if ( Other.Class == ReplacedWeaponPickupClasses[x])
		    	{
                    ReplaceWith(Other, WeaponPickupClassNames[x]);
                    return false;
	     		}
	        //sigh, need this in case we can't change the wep-base
    	}
    	else if (WeaponLocker(Other) != None)
    	{
            L = WeaponLocker(Other);
    		for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
    			for (i = 0; i < L.Weapons.Length; i++)
    				if (L.Weapons[i].WeaponClass == ReplacedWeaponClasses[x])
    					L.Weapons[i].WeaponClass = WeaponClasses[x];
    		return true;
    	}
	}
    else
    {
        // use UTComp weapons
        if (xWeaponBase(Other) != None)
    	{
	    	for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
	    		if (xWeaponBase(Other).WeaponType == ReplacedWeaponClasses[x])
	    		{
                	xWeaponBase(Other).WeaponType = WeaponClassesUTComp[x];
                 }
	    	         	return true;

        }
	    else if (WeaponPickup(Other) != None)
    	{
             for (x = 0; x < ArrayCount(ReplacedWeaponPickupClasses); x++)
		    	if ( Other.Class == ReplacedWeaponPickupClasses[x])
		    	{
                    ReplaceWith(Other, WeaponPickupClassNamesUTComp[x]);
                    return false;
	     		}
	        //sigh, need this in case we can't change the wep-base
    	}
    	else if (WeaponLocker(Other) != None)
    	{
            L = WeaponLocker(Other);
    		for (x = 0; x < ArrayCount(ReplacedWeaponClasses); x++)
    			for (i = 0; i < L.Weapons.Length; i++)
    				if (L.Weapons[i].WeaponClass == ReplacedWeaponClasses[x])
    					L.Weapons[i].WeaponClass = WeaponClassesUTComp[x];
    		return true;
    	}
    }

    if (PlayerReplicationInfo(Other)!=None)
    {
        if(PlayerReplicationInfo(Other).CustomReplicationInfo!=None)
        {
            lPRI=PlayerReplicationInfo(Other).CustomReplicationInfo;
            while(lPRI.NextReplicationInfo!=None)
            {
                 lPRI=lPRI.NextReplicationInfo;
            }
            lPRI.NextReplicationInfo=Spawn(class'UTComp_PRI', Other.Owner);
            if(bEnhancedNetCodeEnabledAtStartOfMap)
                lPRI.NextReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
        }
        else
        {
            PlayerReplicationInfo(Other).CustomReplicationInfo=Spawn(class'UTComp_PRI', Other.Owner);
            if(bEnhancedNetCodeEnabledAtStartOfMap)
                PlayerReplicationInfo(Other).CustomReplicationInfo.NextReplicationInfo = Spawn(class'NewNet_PRI', Other.Owner);
        }
    }

    if (Other.IsA('UDamagePack') && !GetDoubleDamage())
    {
       return false;
    }
    return true;
}

function bool SniperCheckReplacement( Actor Other, out byte bSuperRelevant )
{
	local int i;
	local WeaponLocker L;

	bSuperRelevant = 0;
    if ( xWeaponBase(Other) != None )
    {
		if ( xWeaponBase(Other).WeaponType == class'UTClassic.ClassicSniperRifle' )
			xWeaponBase(Other).WeaponType = class'XWeapons.SniperRifle';
	}
	else if ( ClassicSniperRiflePickup(Other) != None )
		ReplaceWith( Other, "XWeapons.SniperRiflePickup");
	else if ( ClassicSniperAmmoPickup(Other) != None )
		ReplaceWith( Other, "XWeapons.SniperAmmoPickup");
	else if ( WeaponLocker(Other) != None )
	{
		L = WeaponLocker(Other);
		for (i = 0; i < L.Weapons.Length; i++)
			if (L.Weapons[i].WeaponClass == class'ClassicSniperRifle')
				L.Weapons[i].WeaponClass = class'SniperRifle';
		return true;
	}
	else
		return true;
	return false;
}

function bool getDoubleDamage()
{
   return bEnableDoubleDamage;
}


function ModifyLogin(out string Portal, out string Options)
{
    local bool bSeeAll;
	local bool bSpectator;


    if (Level.game == none) {
		Log ("utv2004s: Level.game is none?");
		return;
	}

	if (origcontroller != "") {
		Level.Game.PlayerControllerClassName = origcontroller;
		Level.Game.PlayerControllerClass = origcclass;
		origcontroller = "";
	}

    bSpectator = ( Level.Game.ParseOption( Options, "SpectatorOnly" ) ~= "1" );
    bSeeAll = ( Level.Game.ParseOption( Options, "UTVSeeAll" ) ~= "true" );

	if (bSeeAll && bSpectator) {
		Log ("utv2004s: Creating utv controller");
		origcontroller = Level.Game.PlayerControllerClassName;
		origcclass = Level.Game.PlayerControllerClass;
		Level.Game.PlayerControllerClassName = string(class'UTV_BS_xPlayer');
		Level.Game.PlayerControllerClass = none;
	}

    if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardDeathMatch")
    {
        if(bEnableScoreBoard)
            Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard');
        else
            Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardDM');
    }
    else if(Level.Game.ScoreBoardType~="xInterface.ScoreBoardTeamDeathMatch")
    {
        if(bEnableScoreBoard)
        {
            //TODO: SCOREBOARD
            //if (Level.Game.IsA('xCTFGame'))
            //    Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardCTF');
            //else
                Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard');
        }
        else if(ONSOnslaughtGame(Level.Game) == none) // no custom scoreboard at all for Onslaught 
        {
            //if scoreboard is disabled and NOT and ONS game, then use this scoreboard
            //for ONS game don't touch ScoreBoardType with scoreboard disabled
            Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoardTDM');
        }
    }
    else if(Level.Game.ScoreBoardType~="UT2k4Assault.ScoreBoard_Assault")
    {
        Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard_AS');
    }
    else if(Level.game.scoreboardtype~="BonusPack.MutantScoreboard")
    {
        Level.Game.ScoreBoardType=string(class'UTComp_ScoreBoard_Mutant');
    }

    Super.ModifyLogin(Portal, Options);

    if(level.game.hudtype~="xInterface.HudCTeamDeathmatch")
        Level.Game.HudType=string(class'UTComp_HudCTeamDeathmatch');
    else if(level.game.hudtype~="xInterface.HudCDeathmatch")
        Level.Game.HudType=string(class'UTComp_HudCDeathmatch');
    else if(level.game.hudtype~="xInterface.HudCBombingRun")
        Level.Game.HudType=string(class'UTComp_HudCBombingRun');
    else if(level.game.hudtype~="xInterface.HudCCaptureTheFlag")
        Level.Game.HudType=string(class'UTComp_HudCCaptureTheFlag');
    else if(level.game.hudtype~="xInterface.HudCDoubleDomination")
        Level.Game.HudType=string(class'UTComp_HudCDoubleDomination');
    else if(level.game.hudtype~="Onslaught.ONSHUDOnslaught")
        Level.Game.HudType=string(class'UTComp_ONSHUDOnslaught');
    else if(level.game.hudtype~="SkaarjPack.HUDInvasion")
        Level.Game.HudType=string(class'UTComp_HudInvasion');
    else if(level.game.hudtype~="BonusPack.HudLMS")
        Level.Game.HudType=string(class'UTComp_HudLMS');
    else if(level.game.hudtype~="BonusPack.HudMutant")
        Level.Game.HudType=string(class'UTComp_HudMutant');
    else if(level.game.hudtype~="ut2k4assault.Hud_Assault")
        Level.Game.HudType=string(class'UTComp_Hud_Assault');
}

function GetServerPlayers( out GameInfo.ServerResponseLine ServerState )
{
    local int i;

    if(!Level.Game.bTeamGame)
        return;

    if(bShowTeamScoresInServerBrowser && TeamGame(Level.Game).Teams[0]!=None)
    {
        i = ServerState.PlayerInfo.Length;
        ServerState.PlayerInfo.Length = i+1;
        ServerState.PlayerInfo[i].PlayerName = Chr(0x1B)$chr(10)$chr(245)$chr(10)$"Red Team Score";
        ServerState.PlayerInfo[i].Score = TeamGame(Level.Game).Teams[0].Score;
    }

    if(bShowTeamScoresInServerBrowser && TeamGame(Level.Game).Teams[1]!=None)
    {
        i = ServerState.PlayerInfo.Length;
        ServerState.PlayerInfo.Length = i+1;
        ServerState.PlayerInfo[i].PlayerName =  Chr(0x1B)$chr(10)$chr(245)$chr(10)$"Blue Team Score";
        ServerState.PlayerInfo[i].Score = TeamGame(Level.Game).Teams[1].Score;
    }
}

function ServerTraveling(string URL, bool bItems)
{
   class'xPawn'.default.ControllerClass=class'XGame.XBot';

   class'xWeapons.ShockRifle'.default.FireModeClass[1]=Class'XWeapons.ShockProjFire';
   class'GrenadeAmmo'.default.InitialAmount = 4;

   class'xWeapons.AssaultRifle'.default.FireModeClass[0] = Class'xWeapons.AssaultFire';
   class'xWeapons.AssaultRifle'.default.FireModeClass[1] = Class'xWeapons.AssaultGrenade';

    class'xWeapons.BioRifle'.default.FireModeClass[0] = Class'xWeapons.BioFire';
    class'xWeapons.BioRifle'.default.FireModeClass[1] = Class'xWeapons.BioChargedFire';

    class'xWeapons.ShockRifle'.default.FireModeClass[0] = Class'xWeapons.ShockBeamFire';
    class'xWeapons.ShockRifle'.default.FireModeClass[1] = Class'xWeapons.ShockProjFire';

    class'xWeapons.LinkGun'.default.FireModeClass[0] = Class'xWeapons.LinkAltFire';
    class'xWeapons.LinkGun'.default.FireModeClass[1] = Class'xWeapons.LinkFire';

    class'xWeapons.MiniGun'.default.FireModeClass[0] = Class'xWeapons.MinigunFire';
    class'xWeapons.MiniGun'.default.FireModeClass[1] = Class'xWeapons.MinigunAltFire';

    class'xWeapons.FlakCannon'.default.FireModeClass[0] = Class'xWeapons.FlakFire';
    class'xWeapons.FlakCannon'.default.FireModeClass[1] = Class'xWeapons.FlakAltFire';

    class'xWeapons.RocketLauncher'.default.FireModeClass[0] = Class'xWeapons.RocketFire';
    class'xWeapons.RocketLauncher'.default.FireModeClass[1] = Class'xWeapons.RocketMultiFire';

    class'xWeapons.SniperRifle'.default.FireModeClass[0]= Class'xWeapons.SniperFire';
    class'UTClassic.ClassicSniperRifle'.default.FireModeClass[0]= Class'UTClassic.ClassicSniperFire';

    class'Onslaught.ONSMineLayer'.default.FireModeClass[0] = Class'Onslaught.ONSMineThrowFire';

    class'Onslaught.ONSGrenadeLauncher'.default.FireModeClass[0] =Class'UTComp_ONSGrenadeFire';

    class'Onslaught.ONSAVRiL'.default.FireModeClass[0] =Class'Onslaught.ONSAVRiLFire';

    class'xWeapons.SuperShockRifle'.default.FireModeClass[0]=class'xWeapons.SuperShockBeamFire';
    class'xWeapons.SuperShockRifle'.default.FireModeClass[1]=class'xWeapons.SuperShockBeamFire';

   ParseUrl(Url);

   Super.ServerTraveling(url, bitems);
}

function ParseURL(string Url)
{
   local string Skinz0r, Sounds, overlay, powerupsOverlay, dd, TimedOver
   , TimedOverLength, grenadesonspawn, enableenhancednetcode, suicideIntervalString;
   local array<string> Parts;
   local int i;


    Split(Url, "?", Parts);

   for(i=0; i<Parts.Length; i++)
   {
       if(Parts[i]!="")
       {
           if(Left(Parts[i],Len("BrightSkinsMode"))~= "BrightSkinsMode")
               Skinz0r=Right(Parts[i], Len(Parts[i])-Len("BrightSkinsMode")-1);
           if(Left(Parts[i],Len("HitSoundsMode"))~= "HitSoundsMode")
               Sounds=Right(Parts[i], Len(Parts[i])-Len("HitSoundsMode")-1);
           if(Left(Parts[i],Len("EnableTeamOverlay"))~= "EnableTeamOverlay")
               Overlay=Right(Parts[i], Len(Parts[i])-Len("EnableTeamOverlay")-1);
           if (Left(Parts[i],Len("EnablePowerupsOverlay"))~= "EnablePowerupsOverlay")
               PowerupsOverlay=Right(Parts[i], Len(Parts[i])-Len("EnablePowerupsOverlay")-1);
           if(Left(Parts[i],Len("DoubleDamage"))~= "DoubleDamage")
               DD=Right(Parts[i], Len(Parts[i])-Len("DoubleDamage")-1);
           if(Left(Parts[i],Len("EnableTimedOverTime"))~= "EnableTimedOverTime")
               TimedOver=Right(Parts[i], Len(Parts[i])-Len("EnableTimedOverTime")-1);
           if(Left(Parts[i],Len("TimedOverTimeLength"))~= "TimedOverTimeLength")
               TimedOverLength=Right(Parts[i], Len(Parts[i])-Len("TimedOverTimeLength")-1);
           if(Left(Parts[i],Len("GrenadesOnSpawn"))~= "GrenadesOnSpawn")
               GrenadesOnSpawn=Right(Parts[i], Len(Parts[i])-Len("GrenadesOnSpawn")-1);
           if(Left(Parts[i],Len("EnableEnhancedNetcode"))~= "EnableEnhancedNetcode")
               EnableEnhancedNetcode=Right(Parts[i], Len(Parts[i])-Len("EnableEnhancedNetcode")-1);
           if (Left(Parts[i], Len("SuicideInterval")) ~= "SuicideInterval")
               suicideIntervalString = Right(Parts[i], Len(Parts[i])-Len("SuicideInterval")-1);
       }
   }
   if(Skinz0r !="" && int(Skinz0r)<4 && int(Skinz0r)>0)
   {
       default.EnableBrightskinsMode=Int(Skinz0r);
       EnableBrightskinsMode = default.EnableBrightskinsMode;
   }
   if(Sounds !="" && int(Sounds)<3 && int(Sounds)>=0)
   {
       default.EnableHitsoundsMode=Int(Sounds);
       EnableHitsoundsMode = default.EnableHitsoundsMode;
   }
   if(Overlay !="" && (Overlay~="False" || Overlay~="True"))
   {
       default.bEnableTeamOverlay=Overlay~="True";
       bEnableTeamOverlay = default.bEnableTeamOverlay;
   }
   if(PowerupsOverlay !="" && (PowerupsOverlay~="False" || PowerupsOverlay~="True"))
   {
       default.bEnablePowerupsOverlay=PowerupsOverlay~="True";
       bEnablePowerupsOverlay = default.bEnablePowerupsOverlay;
   }
   if(DD !="" && (DD~="False" || DD~="True"))
   {
       default.bEnableDoubleDamage=(DD~="True");
       bEnableDoubleDamage = default.bEnableDoubleDamage;
   }
 
   if(TimedOverLength !="" && int(TimedOverLength)>=0)
   {
       if(int(TimedOverLength) == 0)
          default.bEnableTimedOverTime=false;
       else
       {
          default.TimedOvertimeLength=60*Int(TimedOverLength);
          default.bEnableTimedOverTime=True;
       }
       bEnableTimedOverTime = default.bEnableTimedOverTime;
       TimedOvertimeLength = default.TimedOvertimeLength;
   }
   if(GrenadesOnSpawn !="" && int(GrenadesOnSpawn)<9 && int(GrenadesOnSpawn)>=0)
   {
       default.NumGrenadesOnSpawn=Int(GrenadesOnSpawn);
       NumGrenadesOnSpawn = default.NumGrenadesOnSpawn;
   }
   if(EnableEnhancedNetcode !="" && (EnableEnhancedNetcode~="false" || EnableEnhancedNetcode~="True"))
   {
       default.bEnableEnhancedNetcode=(EnableEnhancedNetcode~="True");
       bEnhancedNetCodeEnabledAtStartOfMap=default.bEnableEnhancedNetcode;
       bEnableEnhancedNetcode = default.bEnableEnhancedNetCode;
   }
   if (suicideIntervalString != "")
   {
      default.SuicideInterval = Int(suicideIntervalString);
      SuicideInterval = default.SuicideInterval;
   }
   StaticSaveConfig();
}

function AutoDemoRecord()
{
    if(class'MutUTComp'.default.bEnableAutoDemorec)
    {
        ConsoleCommand("Demorec"@CreateAutoDemoRecName());
    }
    bDemoStarted=true;
}

function string CreateAutoDemoRecName()
{
    local string S;
    S=class'MutUTComp'.default.AutoDemoRecMask;
    S=Repl(S, "%p", CreatePlayerString());
    S=Repl(S, "%t", CreateTimeString());
    S=StripIllegalWindowsCharacters(S);
    return S;
}

function string CreatePlayerString()
{
    local controller C;
    local array<string> RedPlayerNames;
    local array<string> BluePlayerNames;
    local string ReturnString;
    local int i;

    for(C=Level.ControllerList; C!=None; C=C.NextController)
    {
        if(PlayerController(C)!=None && C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.PlayerReplicationInfo.PlayerName!="")
        {
            if(C.GetTeamNum()==1)
                BluePlayerNames[BluePlayerNames.Length]=C.PlayerReplicationInfo.PlayerName;
            else
                RedPlayerNames[RedPlayerNames.Length]=C.PlayerReplicationInfo.PlayerName;
        }
    }

    if(BluePlayerNames.Length>0 && RedPlayerNames.Length>0)
    {
         ReturnString=BluePlayerNames[0];
         for(i=1; i<BluePlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$BluePlayerNames[i];
         }
         ReturnString$="-vs-"$RedPlayerNames[0];
         for(i=1; i<RedPlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$RedPlayerNames[i];
         }
    }
    else if(RedPlayerNames.Length>0)
    {
        ReturnString=RedPlayerNames[0];
        for(i=1; i<RedPlayerNames.Length && i<8; i++)
        {
            ReturnString$="-vs-"$RedPlayerNames[i];
        }
    }
    else if(BluePlayerNames.Length>0)
    {
         ReturnString=BluePlayerNames[0];
         for(i=1; i<BluePlayerNames.Length && i<4; i++)
         {
             ReturnString$="-"$BluePlayerNames[i];
         }
         returnString$="-vs-EmptyTeam";
    }
    returnstring=Left(returnstring, 100);
    return ReturnString;
}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    local int i;
    super.GetServerDetails(ServerState);

	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i+2;
	ServerState.ServerInfo[i].Key = FriendlyVersionPrefix;
	ServerState.ServerInfo[i].Value = FriendlyVersionNumber;
	ServerState.ServerInfo[i+1].Key = "Enhanced Netcode";
	ServerState.ServerInfo[i+1].Value = string(bEnhancedNetCodeEnabledAtStartOfMap);
}

function string CreateTimeString()
{
    local string hourdigits, minutedigits;

    if(Len(level.hour)==1)
        hourDigits="0"$Level.Hour;
    else
        hourDigits=Left(level.Hour, 2);
    if(len(level.minute)==1)
        minutedigits="0"$Level.Minute;
    else
        minutedigits=Left(Level.Minute, 2);

   return hourdigits$"-"$minutedigits;
}

simulated function string StripIllegalWindowsCharacters(string S)
{
   S=repl(S, ".", "-");
   S=repl(S, "*", "-");
   S=repl(S, ":", "-");
   S=repl(S, "|", "-");
   S=repl(S, "/", "-");
   S=repl(S, ";", "-");
   S=repl(S, "\\","-");
   S=repl(S, ">", "-");
   S=repl(S, "<", "-");
   S=repl(S, "+", "-");
   S=repl(S, " ", "-");
   S=repl(S, "?", "-");
   return S;
}

static function FillPlayInfo (PlayInfo PlayInfo)
{
	PlayInfo.AddClass(Default.Class);
    PlayInfo.AddSetting("UTComp Settings", "EnableBrightSkinsMode", "Brightskins Mode", 1, 1, "Select", "0;Disabled;1;Epic Style;2;BrighterEpic Style;3;UTComp Style ");
    PlayInfo.AddSetting("UTComp Settings", "EnableHitSoundsMode", "Hitsounds Mode", 1, 1, "Select", "0;Disabled;1;Line Of Sight;2;Everywhere");
    PlayInfo.AddSetting("UTComp Settings", "bEnableDoubleDamage", "Enable Double Damage", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableAutoDemoRec", "Enable Serverside Demo-Recording", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableTeamOverlay", "Enable Team Overlay", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnablePowerupsOverlay", "Enable Powerups Overlay for spectators", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableEnhancedNetcode", "Enable Enhanced Netcode", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "ServerMaxPlayers", "Voting Max Players",255, 1, "Text","2;0:32",,True,True);
    PlayInfo.AddSetting("UTComp Settings", "NumGrenadesOnSpawn", "Number of grenades on spawn",255, 1, "Text","2;0:32",,True,True);
    PlayInfo.AddSetting("UTComp Settings", "MaxMultiDodges", "Number of additional dodges",255, 1, "Text","2;0:99",);
    PlayInfo.AddSetting("UTComp Settings", "MinNetSpeed", "Minimum NetSpeed for Clients",255, 1, "Text","0;0:100000",);
    PlayInfo.AddSetting("UTComp Settings", "MaxNetSpeed", "Maximum NetSpeed for Clients",255, 1, "Text","0;0:100000",);

    PlayInfo.AddSetting("UTComp Settings", "bEnableVoting", "Enable Voting", 1, 1, "Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableBrightskinsVoting", "Allow players to vote on Brightskins settings", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableHitsoundsVoting", "Allow players to vote on Hitsounds settings", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableTeamOverlayVoting", "Allow players to vote on team overlay setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnablePowerupsOverlayVoting", "Allow players to vote on powerups overlay setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableEnhancedNetcodeVoting", "Allow players to vote on enhanced netcode setting", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "bEnableMapVoting", "Allow players to vote for map changes", 1, 1,"Check");
    PlayInfo.AddSetting("UTComp Settings", "SuicideInterval", "Minimum time between two suicides", 1, 1, "Text", "0;0:1800",, True, True);
    PlayInfo.AddSetting("UTComp Settings", "MinNetUpdateRate", "Minimum rate of client updates", 1, 1, "Text", "0;0:999",, True, True);
    PlayInfo.AddSetting("UTComp Settings", "MaxNetUpdateRate", "Maximum rate of client updates", 1, 1, "Text", "0;0:999",, True, True);

    PlayInfo.PopClass();
    super.FillPlayInfo(PlayInfo);
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bEnableDoubleDamage": return "Check this to enable the double damage.";
	    case "EnableBrightSkinsMode": return "Sets the server-forced brightskins mode.";
	    case "EnableHitSoundsMode": return "Sets the server-Forced hitsound mode.";
	    case "bEnableAutoDemoRec": return "Check this to enable a recording of every map.";
        case "ServerMaxPlayers": return "Set this to the maximum number of players you wish for to allow a client to vote for.";
        case "NumGrenadesOnSpawn": return "Set this to the number of Assault Rifle grenades you wish a player to spawn with.";
        case "MaxMultiDodges": return "Additional dodges players can perform without landing.";
        case "bEnableTeamOverlay": return "Check this to enable the team overlay.";
        case "bEnablePowerupsOverlay": return "Check this to enable the powerups overlay for spectators.";
        case "bEnableEnhancedNetcode": return "Check this to enable the enhanced netcode.";
        case "bEnableVoting": return "Check this to enable voting.";
        case "bEnableBrightSkinsVoting": return "Check this to enable voting for brightskins.";
        case "bEnablehitsoundsVoting": return "Check this to enable voting for hitsounds.";
        case "bEnableTeamOverlayVoting": return "Check this to enable voting for Team Overlay.";
        case "bEnablePowerupsOverlayVoting": return "Check this to enable voting for powerups overlay for spectators.";
        case "bEnableEnhancedNetcodeVoting": return "Check this to enable voting for Enhanced Netcode.";
        case "bEnableMapVoting": return "Check this to enable voting for Maps.";
        case "MinNetSpeed": return "Minimum NetSpeed for clients on this server";
        case "MaxNetSpeed": return "Maximum NetSpeed for clients on this server";
        case "SuicideInterval": return "Minimum time between two suicides";
        case "MinNetUpdateRate": return "Minimum Rate at which clients are expected to send updates to the server";
        case "MaxNetUpdateRate": return "Maximum Rate at which clients can send updates to the server";
    }
	return Super.GetDescriptionText(PropName);
}

function bool ReplaceWith(actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if ( aClassName == "" )
		return true;

	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if ( aClass != None )
		A = Spawn(aClass,Other.Owner,Other.tag,Other.Location, Other.Rotation);
	if ( Other.IsA('Pickup') )
	{
		if ( Pickup(Other).MyMarker != None )
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if ( Pickup(A) != None )
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location
					+ (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		else if ( A.IsA('Pickup') && !A.IsA('WeaponPickup') )
			Pickup(A).Respawntime = 0.0;
	}
	if ( A != None )
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return true;
	}
	return false;
}

function string GetInventoryClassOverride(string InventoryClassName)
{
    local int x;

    if(bEnhancedNetCodeEnabledAtStartOfMap)
    {
        for(x=0; x<ArrayCount(WeaponClassNames); x++)
           if(InventoryClassName ~= WeaponClassNames[x])
               return string(WeaponClasses[x]);
    }
    else
    {
         for(x=0; x<ArrayCount(WeaponClassNames); x++)
           if(InventoryClassName ~= WeaponClassNames[x])
               return string(WeaponClassesUTComp[x]);
    }

    if ( NextMutator != None )
		return NextMutator.GetInventoryClassOverride(InventoryClassName);

	return InventoryClassName;
}

defaultproperties
{
     bAddToServerPackages=True
     bEnableVoting=False
     bEnableBrightskinsVoting=True
     bEnableHitsoundsVoting=True
     bEnableTeamOverlayVoting=True
     bEnablePowerupsOverlayVoting=True
     bEnableMapVoting=True
     bEnableGametypeVoting=True
     VotingPercentRequired=51.000000
     VotingTimeLimit=30.000000
     benableDoubleDamage=True
     EnableBrightSkinsMode=3
     bEnableClanSkins=True
     bEnablePowerupsOverlay=True
     EnableHitSoundsMode=1
     bEnableScoreboard=True
     bEnableWeaponStats=True
     bEnablePowerupStats=True

     bShowTeamScoresInServerBrowser=True
     ServerMaxPlayers=12
     AlwaysUseThisMutator(0)="UTCompOmni.MutUTComp"
     AutoDemoRecMask="%d-(%t)-%m-%p"

     VotingGametype(0)=(GametypeOptions="?game=XGame.xDeathMatch?timelimit=15?minplayers=0?goalscore=0?Mutator=XWeapons.MutNoSuperWeapon,XGame.MutNoAdrenaline?weaponstay=false?DoubleDamage=false?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="1v1")
     VotingGametype(1)=(GametypeOptions="?game=XGame.xDeathMatch?timelimit=15?minplayers=0?goalscore=50?weaponstay=True?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="FFA")
     VotingGametype(2)=(GametypeOptions="?game=XGame.xTeamGame?timelimit=20?goalscore=0?minplayers=0?Mutator=XWeapons.MutNoSuperWeapon?FriendlyfireScale=1.00?weaponstay=False?DoubleDamage=True?GrenadesOnSpawn=1?TimedOverTimeLength=5",GametypeName="Team Deathmatch")
     VotingGametype(3)=(GametypeOptions="?game=XGame.xCTFGame?timelimit=20?goalscore=0?minplayers=0?mutator=XGame.MutNoAdrenaline,XWeapons.MutNoSuperWeapon?friendlyfirescale=0?weaponstay=true?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Capture the Flag")
     VotingGametype(4)=(GametypeOptions="?game=Onslaught.ONSOnslaughtGame?timelimit=20?goalscore=1?mutator=XWeapons.MutNoSuperWeapon?minplayers=0?friendlyfirescale=0?weaponstay=True?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Onslaught")
     VotingGametype(5)=(GametypeOptions="?game=UT2k4Assault.ASGameInfo?timelimit=20?goalscore=1?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Assault")
     VotingGametype(6)=(GametypeOptions="?game=XGame.xDoubleDom?timelimit=20?goalscore=0?FriendlyFireScale=0,WeaponStay=true?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=true?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Double Domination")
     VotingGametype(7)=(GametypeOptions="?game=XGame.xBombingRun?timelimit=20?goalscore=0?FriendlyFireScale=0,WeaponStay=True?mutator=XWeapons.MutNoSuperWeapon?DoubleDamage=True?GrenadesOnSpawn=4?TimedOverTimeLength=0",GametypeName="Bombing Run")

     MinNetSpeed=15000
     MaxNetSpeed=25000

     //ONS
     NodeIsolateBonusPct=20
     VehicleHealScore=500
     VehicleDamagePoints=400
     PowerCoreScore=10
     PowerNodeScore=5
     NodeHealBonusPct=60
     bNodeHealBonusForLockedNodes=false
     bNodeHealBonusForConstructor=false
		 bDebugLogging = false


     NewNetUpdateFrequency=200
     PingTweenTime=3.0

     FriendlyName="UTComp Version 1.40 (Omni)"
     FriendlyVersionPrefix="UTComp Version"
     FriendlyVersionNumber=")o(mni 1.40"
     Description="A mutator for brightskins, hitsounds, and various other features."
     bNetTemporary=True
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bEnableAdvancedVotingOptions=True
     bForceMapVoteMatchPrefix=True
     TimedOverTimeLength=300
     bEnableTimedOvertimeVoting=True
     NumGrenadesOnSpawn=4
     bEnableEnhancedNetCode=true
     bEnableEnhancedNetCodeVoting=false
     MinNetUpdateRate=60
     MaxNetUpdateRate=250
     PawnCollisionHistoryLength=0.35

     //original weapons
     WeaponClassNames(0)="xWeapons.ShockRifle"
     WeaponClassNames(1)="xWeapons.LinkGun"
     WeaponClassNames(2)="xWeapons.MiniGun"
     WeaponClassNames(3)="xWeapons.FlakCannon"
     WeaponClassNames(4)="xWeapons.RocketLauncher"
     WeaponClassNames(5)="xWeapons.SniperRifle"
     WeaponClassNames(6)="xWeapons.BioRifle"
     WeaponClassNames(7)="xWeapons.AssaultRifle"
     WeaponClassNames(8)="UTClassic.ClassicSniperRifle"
     WeaponClassNames(9)="Onslaught.ONSAVRiL"
     WeaponClassNames(10)="Onslaught.ONSMineLayer"
     WeaponClassNames(11)="Onslaught.ONSGrenadeLauncher"
     WeaponClassNames(12)="xWeapons.SuperShockRifle"
     ReplacedWeaponClasses(0)=Class'XWeapons.ShockRifle'
     ReplacedWeaponClasses(1)=Class'XWeapons.LinkGun'
     ReplacedWeaponClasses(2)=Class'XWeapons.Minigun'
     ReplacedWeaponClasses(3)=Class'XWeapons.FlakCannon'
     ReplacedWeaponClasses(4)=Class'XWeapons.RocketLauncher'
     ReplacedWeaponClasses(5)=Class'XWeapons.SniperRifle'
     ReplacedWeaponClasses(6)=Class'XWeapons.BioRifle'
     ReplacedWeaponClasses(7)=Class'XWeapons.AssaultRifle'
     ReplacedWeaponClasses(8)=Class'UTClassic.ClassicSniperRifle'
     ReplacedWeaponClasses(9)=Class'Onslaught.ONSAVRiL'
     ReplacedWeaponClasses(10)=Class'Onslaught.ONSMineLayer'
     ReplacedWeaponClasses(11)=Class'Onslaught.ONSGrenadeLauncher'
     ReplacedWeaponClasses(12)=Class'xWeapons.SuperShockRifle'
     ReplacedWeaponPickupClasses(0)=Class'XWeapons.ShockRiflePickup'
     ReplacedWeaponPickupClasses(1)=Class'XWeapons.LinkGunPickup'
     ReplacedWeaponPickupClasses(2)=Class'XWeapons.MinigunPickup'
     ReplacedWeaponPickupClasses(3)=Class'XWeapons.FlakCannonPickup'
     ReplacedWeaponPickupClasses(4)=Class'XWeapons.RocketLauncherPickup'
     ReplacedWeaponPickupClasses(5)=Class'XWeapons.SniperRiflePickup'
     ReplacedWeaponPickupClasses(6)=Class'XWeapons.BioRiflePickup'
     ReplacedWeaponPickupClasses(7)=Class'XWeapons.AssaultRiflePickup'
     ReplacedWeaponPickupClasses(8)=Class'UTClassic.ClassicSniperRiflePickup'
     ReplacedWeaponPickupClasses(9)=Class'Onslaught.ONSAVRiLPickup'
     ReplacedWeaponPickupClasses(10)=Class'Onslaught.ONSMineLayerPickup'
     ReplacedWeaponPickupClasses(11)=Class'Onslaught.ONSGrenadePickup'
     ReplacedWeaponPickupClasses(12)=Class'XWeapons.SuperShockRiflePickup'

     // replaced NewNet classes
     WeaponClasses(0)=Class'NewNet_ShockRifle'
     WeaponClasses(1)=Class'NewNet_LinkGun'
     WeaponClasses(2)=Class'NewNet_MiniGun'
     WeaponClasses(3)=Class'NewNet_FlakCannon'
     WeaponClasses(4)=Class'NewNet_RocketLauncher'
     WeaponClasses(5)=Class'NewNet_SniperRifle'
     WeaponClasses(6)=Class'NewNet_BioRifle'
     WeaponClasses(7)=Class'NewNet_AssaultRifle'
     WeaponClasses(8)=Class'NewNet_ClassicSniperRifle'
     WeaponClasses(9)=Class'NewNet_ONSAVRiL'
     WeaponClasses(10)=Class'NewNet_ONSMineLayer'
     WeaponClasses(11)=Class'NewNet_ONSGrenadeLauncher'
     WeaponClasses(12)=Class'NewNet_SuperShockRifle'
     WeaponPickupClasses(0)=Class'NewNet_ShockRiflePickup'
     WeaponPickupClasses(1)=Class'NewNet_LinkGunPickup'
     WeaponPickupClasses(2)=Class'NewNet_MiniGunPickup'
     WeaponPickupClasses(3)=Class'NewNet_FlakCannonPickup'
     WeaponPickupClasses(4)=Class'NewNet_RocketLauncherPickup'
     WeaponPickupClasses(5)=Class'NewNet_SniperRiflePickup'
     WeaponPickupClasses(6)=Class'NewNet_BioRiflePickup'
     WeaponPickupClasses(7)=Class'NewNet_AssaultRiflePickup'
     WeaponPickupClasses(8)=Class'NewNet_ClassicSniperRiflePickup'
     WeaponPickupClasses(9)=Class'NewNet_ONSAVRiLPickup'
     WeaponPickupClasses(10)=Class'NewNet_ONSMineLayerPickup'
     WeaponPickupClasses(11)=Class'NewNet_ONSGrenadePickup'
     WeaponPickupClasses(12)=Class'NewNet_SuperShockRiflePickup'
     WeaponPickupClassNames(0)="UTCompOmni.NewNet_ShockRiflePickup"
     WeaponPickupClassNames(1)="UTCompOmni.NewNet_LinkGunPickup"
     WeaponPickupClassNames(2)="UTCompOmni.NewNet_MiniGunPickup"
     WeaponPickupClassNames(3)="UTCompOmni.NewNet_FlakCannonPickup"
     WeaponPickupClassNames(4)="UTCompOmni.NewNet_RocketLauncherPickup"
     WeaponPickupClassNames(5)="UTCompOmni.NewNet_SniperRiflePickup"
     WeaponPickupClassNames(6)="UTCompOmni.NewNet_BioRiflePickup"
     WeaponPickupClassNames(7)="UTCompOmni.NewNet_AssaultRiflePickup"
     WeaponPickupClassNames(8)="UTCompOmni.NewNet_ClassicSniperRiflePickup"
     WeaponPickupClassNames(9)="UTCompOmni.NewNet_ONSAVRiLPickup"
     WeaponPickupClassNames(10)="UTCompOmni.NewNet_ONSMineLayerPickup"
     WeaponPickupClassNames(11)="UTCompOmni.NewNet_ONSGrenadePickup"
     WeaponPickupClassNames(12)="UTCompOmni.NewNet_SuperShockRiflePickup"

    // replaced UTComp classes
     WeaponClassesUTComp(0)=Class'UTComp_ShockRifle'
     WeaponClassesUTComp(1)=Class'UTComp_LinkGun'
     WeaponClassesUTComp(2)=Class'UTComp_MiniGun'
     WeaponClassesUTComp(3)=Class'UTComp_FlakCannon'
     WeaponClassesUTComp(4)=Class'UTComp_RocketLauncher'
     WeaponClassesUTComp(5)=Class'UTComp_SniperRifle'
     WeaponClassesUTComp(6)=Class'UTComp_BioRifle'
     WeaponClassesUTComp(7)=Class'UTComp_AssaultRifle'
     WeaponClassesUTComp(8)=Class'UTComp_ClassicSniperRifle'
     WeaponClassesUTComp(9)=Class'UTComp_ONSAVRiL'
     WeaponClassesUTComp(10)=Class'UTComp_ONSMineLayer'
     WeaponClassesUTComp(11)=Class'UTComp_ONSGrenadeLauncher'
     WeaponClassesUTComp(12)=Class'UTComp_SuperShockRifle'
     WeaponPickupClassesUTComp(0)=Class'UTComp_ShockRiflePickup'
     WeaponPickupClassesUTComp(1)=Class'UTComp_LinkGunPickup'
     WeaponPickupClassesUTComp(2)=Class'UTComp_MiniGunPickup'
     WeaponPickupClassesUTComp(3)=Class'UTComp_FlakCannonPickup'
     WeaponPickupClassesUTComp(4)=Class'UTComp_RocketLauncherPickup'
     WeaponPickupClassesUTComp(5)=Class'UTComp_SniperRiflePickup'
     WeaponPickupClassesUTComp(6)=Class'UTComp_BioRiflePickup'
     WeaponPickupClassesUTComp(7)=Class'UTComp_AssaultRiflePickup'
     WeaponPickupClassesUTComp(8)=Class'UTComp_ClassicSniperRiflePickup'
     WeaponPickupClassesUTComp(9)=Class'UTComp_ONSAVRiLPickup'
     WeaponPickupClassesUTComp(10)=Class'UTComp_ONSMineLayerPickup'
     WeaponPickupClassesUTComp(11)=Class'UTComp_ONSGrenadePickup'
     WeaponPickupClassesUTComp(12)=Class'UTComp_SuperShockRiflePickup'
     WeaponPickupClassNamesUTComp(0)="UTCompOmni.UTComp_ShockRiflePickup"
     WeaponPickupClassNamesUTComp(1)="UTCompOmni.UTComp_LinkGunPickup"
     WeaponPickupClassNamesUTComp(2)="UTCompOmni.UTComp_MiniGunPickup"
     WeaponPickupClassNamesUTComp(3)="UTCompOmni.UTComp_FlakCannonPickup"
     WeaponPickupClassNamesUTComp(4)="UTCompOmni.UTComp_RocketLauncherPickup"
     WeaponPickupClassNamesUTComp(5)="UTCompOmni.UTComp_SniperRiflePickup"
     WeaponPickupClassNamesUTComp(6)="UTCompOmni.UTComp_BioRiflePickup"
     WeaponPickupClassNamesUTComp(7)="UTCompOmni.UTComp_AssaultRiflePickup"
     WeaponPickupClassNamesUTComp(8)="UTCompOmni.UTComp_ClassicSniperRiflePickup"
     WeaponPickupClassNamesUTComp(9)="UTCompOmni.UTComp_ONSAVRiLPickup"
     WeaponPickupClassNamesUTComp(10)="UTCompOmni.UTComp_ONSMineLayerPickup"
     WeaponPickupClassNamesUTComp(11)="UTCompOmni.UTComp_ONSGrenadePickup"
     WeaponPickupClassNamesUTComp(12)="UTCompOmni.UTComp_SuperShockRiflePickup"

     bShieldFix=true

     bAllowRestartVoteEvenIfMapVotingIsTurnedOff=false

     CapBonus = 5
     FlagKillBonus = 3
     CoverBonus = 4
     SealBonus = 4
     GrabBonus = 0
     MinimalCapBonus = 5
     BaseReturnBonus = 0.500000
     MidReturnBonus = 2.000000
     EnemyBaseReturnBonus = 5.000000
     CloseSaveReturnBonus = 10.000000


     CoverMsgType = 3
     CoverSpreeMsgType = 3
     SealMsgType = 3
     SavedMsgType = 3

     bShowSealRewardConsoleMsg = true
     bShowAssistConsoleMsg = true

     bSilentAdmin=true
     bEnableWhitelist=false
     bUseWhitelist=false
     WhitelistBanMessage="Not allowed.  Contact the server administrator to gain access"
     bUseDefaultScoreboardColor=false

     SuicideInterval = 3

     IgnoredHitSounds(0)="FireKill"
     
     
}
 