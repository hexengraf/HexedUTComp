class MutUTComp extends HxMutator;

#exec AUDIO IMPORT FILE=Sounds\HitSound.wav

const AVERDT_SEND_PERIOD = 4.00;

var config bool bAllowNewNetWeapons;
var config bool bAllowNewEyeHeightAlgorithm;
var config bool bDisableDoubleDamage;
var config bool bColoredDeathMessages;
var config int TimedOvertime;
var config float PingTweenTime;
var config float PawnCollisionHistoryLength;

var float StampArray[256];
var float Counter;
var Controller CounterController;
var PawnCollisionCopy PCC;
var TimeStamp StampInfo;
var float AverDT;
var float ClientTimeStamp;
var array<float> DeltaHistory;
var FakeProjectileManager FPM;
var float LastReplicatedAverDT;

var class<Weapon> WeaponClasses[13];
var class<Weapon> NewNetWeaponClasses[13];
var bool bDefaultWeaponsChanged;

var class<FloatingWindow> MenuClass;

simulated function PreBeginPlay()
{
    Super.PreBeginPlay();
    ServerPreBeginPlay();
    class'UTComp_HxPanel'.static.AddToMenu();
    class'HxSounds'.static.AddHitSound(Sound'HitSound');
}

function ServerPreBeginPlay()
{
    if (bAllowNewNetWeapons || bAllowNewEyeHeightAlgorithm)
    {
        ReplacePawn();
    }
    if (bAllowNewNetWeapons)
    {
        SetupTimeStamps();
        SetupInstagib();
    }
    if (bColoredDeathMessages)
    {
        SetupColoredDeathMessages();
    }
    StaticSaveConfig();
}

function SetupColoredDeathMessages()
{
    if (Level.Game.DeathMessageClass == class'xDeathMessage')
    {
        Level.Game.DeathMessageClass = class'UTComp_xDeathMessage';
    }
    else if (Level.Game.DeathMessageClass == class'InvasionDeathMessage')
    {
        Level.Game.DeathMessageClass = class'UTComp_InvasionDeathMessage';
    }
}

function ReplacePawn()
{
    if (Level.Game.DefaultPlayerClassName ~= "xGame.xPawn")
    {
        Level.Game.DefaultPlayerClassName = String(class'UTComp_xPawn');
    }
    else
    {
        Warn(Name@"failed to replace xPawn class with UTComp_xPawn, disabling features.");
        bAllowNewNetWeapons = False;
        bAllowNewEyeHeightAlgorithm = False;
    }
}

function SetupTimeStamps()
{
    if (StampInfo == None)
    {
        StampInfo = Spawn(class'TimeStamp');
    }
    if (CounterController == None)
    {
        CounterController = Spawn(class'TimeStamp_Controller');
    }
    if (CounterController != None && CounterController.Pawn == None)
    {
        CounterController.Possess(Spawn(CounterController.PawnClass));
    }
}

function SetupInstagib()
{
    local MutInstagib Instagib;

    ForEach DynamicActors(class'MutInstagib', Instagib) break;

    if (Instagib != None)
    {
        Instagib.Default.WeaponName = 'NewNet_SuperShockRifle';
        Instagib.Default.WeaponString = String(class'NewNet_SuperShockRifle');
        Instagib.Default.DefaultWeaponName = String(class'NewNet_SuperShockRifle');
        Instagib.WeaponName = 'NewNet_SuperShockRifle';
        Instagib.WeaponString = String(class'NewNet_SuperShockRifle');
        Instagib.DefaultWeaponName = String(class'NewNet_SuperShockRifle');
    }
}

event PostBeginPlay()
{
    local UTComp_GameRules G;

    Super.PostBeginPlay();

    if (Level.Game.IsA('CTFGame') || Level.Game.IsA('ONSOnslaughtGame')
        || Level.Game.IsA('ASGameInfo') || Level.Game.IsA('xBombingRun')
        || Level.Game.IsA('xMutantGame') || Level.Game.IsA('xLastManStandingGame')
        || Level.Game.IsA('xDoubleDom') || Level.Game.IsA('Invasion'))
    {
       TimedOvertime = 0;
    }
    G = Spawn(class'UTComp_GameRules');
    G.UTComp = Self;
    Level.Game.AddGameModifier(G);
}

function ModifyPlayer(Pawn Other)
{
    if (bAllowNewNetWeapons)
    {
        SpawnCollisionCopy(Other);
        RemoveOldPawns();
    }
    Super.ModifyPlayer(Other);
}

function SpawnCollisionCopy(Pawn Other)
{
    if(PCC == None)
    {
        PCC = Spawn(class'PawnCollisionCopy');
        PCC.SetPawn(Other);
    }
    else
    {
        PCC.AddPawnToList(Other);
    }
}

function RemoveOldPawns()
{
    PCC = PCC.RemoveOldPawns();
}

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
    local PawnCollisionCopy C;
    C = PCC;
    while (C != None)
    {
        if (C.CopiedPawn == P)
        {
            C.SetPawn(V);
            break;
        }
        C = C.Next;
    }
    if (NextMutator != None)
    {
        NextMutator.DriverEnteredVehicle(V, P);
    }
}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
    local PawnCollisionCopy C;

    C = PCC;
    while (C != None)
    {
        if (C.CopiedPawn == V)
        {
            C.SetPawn(P);
            break;
        }
        C = C.Next;
    }
    if (NextMutator != None)
    {
        NextMutator.DriverLeftVehicle(V, P);
    }
}

function ListPawns()
{
    local PawnCollisionCopy PCC2;

    for (PCC2 = PCC; PCC2 != None; PCC2 = PCC2.Next)
    {
       PCC2.Identify();
    }
}

static function bool IsPredicted(Actor A)
{
    // Fix up vehicle a bit, we still wanna predict if its in the list w/o a driver
    return A == None || A.IsA('xPawn') || (A.IsA('Vehicle') && Vehicle(A).Driver != None);
}

function ReplaceOtherMutatorWeapons()
{
    local Mutator M;
    local int x;

    bDefaultWeaponsChanged = True;
    // replace DefaultWeaponName (fix for simple Arena mutators)
    for(M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
    {
        if (M.DefaultWeaponName != "")
        {
            for (x = 0; x < ArrayCount(WeaponClasses); x++)
            {
                if (M.DefaultWeaponName ~= String(WeaponClasses[x]))
                {
                    M.DefaultWeaponName = String(NewNetWeaponClasses[x]);
                }
            }
        }
    }
}

simulated function Tick(float DeltaTime)
{
    if (bAllowNewNetWeapons)
    {
        if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
        {
            if (bDefaultWeaponsChanged == False)
            {
                ReplaceOtherMutatorWeapons();
            }
            ClientTimeStamp += DeltaTime;
            Counter += 1;
            StampArray[Counter % 256] = ClientTimeStamp;
            AverDT = (9.0 * AverDT + DeltaTime) * 0.1;
            SetPawnStamp();

            if (ClientTimeStamp > LastReplicatedAverDT + AVERDT_SEND_PERIOD)
            {
                StampInfo.ReplicatedAverDT(AverDT);
                LastReplicatedAverDT = ClientTimeStamp;
            }
        }
        else if (FPM == None && Level.NetMode == NM_Client)
        {
            FPM = Spawn(Class'FakeProjectileManager');
        }
    }
}

function SetPawnStamp()
{
    local rotator R;
    local int i;

    R.Yaw = (Counter % 256) * 256;
    i = Counter / 256;
    R.Pitch = i * 256;

    if (CounterController.Pawn != None)
    {
        CounterController.Pawn.SetRotation(R);
    }
}

simulated function float GetStamp(int stamp)
{
   return StampArray[stamp % 256];
}

function SpawnNewNet_PRI(PlayerReplicationInfo PRI)
{
    local NewNet_PRI NewNetPRI;

    if (PlayerController(PRI.Owner) != None && MessagingSpectator(PRI.Owner) == None)
    {
        NewNetPRI = NewNet_PRI(SpawnLinkedPRI(PRI, class'NewNet_PRI'));
        NewNetPRI.bAllowNewNetWeapons = bAllowNewNetWeapons;
        NewNetPRI.bAllowNewEyeHeightAlgorithm = bAllowNewEyeHeightAlgorithm;
        NewNetPRI.bDisableDoubleDamage = bDisableDoubleDamage;
        NewNetPRI.bColoredDeathMessages = bColoredDeathMessages;
        NewNetPRI.TimedOvertime = TimedOvertime;
        NewNetPRI.PingTweenTime = PingTweenTime;
        NewNetPRI.PawnCollisionHistoryLength = PawnCollisionHistoryLength;
        NewNetPRI.UTComp = self;
        NewNetPRI.PC = PlayerController(PRI.Owner);
        NewNetPRI.NetUpdateTime = Level.TimeSeconds - 1;
    }
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local int x, i;
    local WeaponLocker L;

    if (PlayerReplicationInfo(Other) != None)
    {
        SpawnNewNet_PRI(PlayerReplicationInfo(Other));
    }
    if (bAllowNewNetWeapons)
    {
        if (xWeaponBase(Other) != None)
        {
            for (x = 0; x < ArrayCount(WeaponClasses); x++)
            {
                if (xWeaponBase(Other).WeaponType == WeaponClasses[x])
                {
                    xWeaponBase(Other).WeaponType = NewNetWeaponClasses[x];
                }
            }
            return True;
        }
        if (WeaponPickup(Other) != None)
        {
            for (x = 0; x < ArrayCount(WeaponClasses); ++x)
            {
                if (WeaponPickup(Other).InventoryType == WeaponClasses[x])
                {
                    WeaponPickup(Other).InventoryType = NewNetWeaponClasses[x];
                }
            }
            return True;
        }
        if (WeaponLocker(Other) != None)
        {
            L = WeaponLocker(Other);
            for (x = 0; x < ArrayCount(WeaponClasses); x++)
            {
                for (i = 0; i < L.Weapons.Length; i++)
                {
                    if (L.Weapons[i].WeaponClass == WeaponClasses[x])
                    {
                        L.Weapons[i].WeaponClass = NewNetWeaponClasses[x];
                    }
                }
            }
            return True;
        }
    }
    if (bDisableDoubleDamage && Other.IsA('UDamagePack'))
    {
        bSuperRelevant = 0;
        return False;
    }
    return True;
}

function ServerTraveling(String URL, bool bItems)
{
    class'GrenadeAmmo'.Default.InitialAmount = 4;
    Super.ServerTraveling(URL, bItems);
}

function String GetInventoryClassOverride(String InventoryClassName)
{
    local String OverrideClassName;
    local int x;

    OverrideClassName = InventoryClassName;

    if (NextMutator != None)
    {
        OverrideClassName = NextMutator.GetInventoryClassOverride(InventoryClassName);
    }
    for (x = 0; x < ArrayCount(WeaponClasses); ++x)
    {
        if (OverrideClassName ~= String(WeaponClasses[x]))
        {
            OverrideClassName = String(NewNetWeaponClasses[x]);
            break;
        }
    }
    return OverrideClassName;
}

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
    local int i;

    super.GetServerDetails(ServerState);

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "NewNet Weapons";
    if (bAllowNewNetWeapons)
    {
        ServerState.ServerInfo[i++].Value = "Allowed";
    }
    else
    {
        ServerState.ServerInfo[i++].Value = "Disabled";
    }
    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "New EyeHeight algorithm";
    if (bAllowNewEyeHeightAlgorithm)
    {
        ServerState.ServerInfo[i++].Value = "Allowed";
    }
    else
    {
        ServerState.ServerInfo[i++].Value = "Disabled";
    }
}

simulated function Mutate(string Command, PlayerController Sender)
{
    if (Command ~= "HexedUT")
    {
        Sender.ClientOpenMenu(string(MenuClass));
    }
	else if (NextMutator != None)
    {
		NextMutator.Mutate(Command, Sender);
    }
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    PlayInfo.AddClass(Default.Class);
    PlayInfo.AddSetting(
        Default.RulesGroup, "bAllowNewNetWeapons", "Allow NewNet Weapons", 0, 10, "Check",,, True, True);
    PlayInfo.AddSetting(
        Default.RulesGroup, "bAllowNewEyeHeightAlgorithm", "Allow new EyeHeight algorithm", 0, 20, "Check");
    PlayInfo.AddSetting(
        Default.RulesGroup, "bDisableDoubleDamage", "Disable double damage", 0, 30, "Check");
    PlayInfo.AddSetting(
        Default.RulesGroup, "bColoredDeathMessages", "Enable colored names in death messages", 0, 40, "Check");
    PlayInfo.AddSetting(
        Default.RulesGroup, "TimedOvertime", "Timed overtime duration", 0, 80, "Text","0;0:3600");
    PlayInfo.AddSetting(
        Default.RulesGroup, "PingTweenTime", "NewNet Ping Tween Time (3.0)", 0, 100, "Text","0;0.0:1000",, True, True);
    PlayInfo.AddSetting(
        Default.RulesGroup, "PawnCollisionHistoryLength", "NewNet Pawn Collision History Length (0.35)", 0, 110, "Text","0;0.0:1000",, True, True);
    PlayInfo.PopClass();
    super.FillPlayInfo(PlayInfo);
}

static event String GetDescriptionText(String PropName)
{
    switch (PropName)
    {
        case "bAllowNewNetWeapons":
            return "Allow clients to enable/disable the NewNet Weapons";
        case "bAllowNewEyeHeightAlgorithm":
            return "Allow clients to enable/disable the new EyeHeight algorithm";
        case "bDisableDoubleDamage":
            return "Disable double damage pickups on maps.";
        case "bColoredDeathMessages":
            return "Use team colors for the player names in the death messages.";
        case "TimedOvertime":
            return "Duration of timed overtime (in seconds).";
        case "PingTweenTime":
            return "NewNet Ping Tween Time (3.0)";
        case "PawnCollisionHistoryLength":
            return "NewNet Pawn Collision History Length (0.35)";
    }
    return Super.GetDescriptionText(PropName);
}

/*
 fix for netcode not working in second round in assault and ons game modes
 reset is called bewteen rounds, clean up timestamp pawn and controller and recreate
 ONS and AS round end code calls

    for(C = Level.ControllerList;C != None; C = C.NextController)
    {
        ...
        C.RoundHasEnded();
    }

   RoundHasEnded in Timestamp_Controller breaks the timestamp mechanism.

   For whatever reason (engine bug?) we cannot override RoundHasEnded() function in
   Timestamp_Controller.  It never gets called, instead the base method gets called
   which unpossesses the pawn and destroys itself.  Not good.  Since we can't override
   RoundHasEnded, we fix what gets broken in the Reset() function that gets called for
   all actors (including this mutator) during round changes.
*/
simulated function Reset()
{
    local Controller C;

    if (Level.NetMode != NM_Client)
    {
        // remove all Timestamp_pawn from clients
        for(C = Level.ControllerList;C != None;C = C.NextController)
        {
            if(UTComp_xPawn(C.Pawn) != None)
            {
                UTComp_xPawn(C.Pawn).ClientResetNetcode();
            }
        }
        // delete these server side, the get recreated in SetPawnStamp function
        if(CounterController != None)
        {
            if(CounterController.Pawn != None)
            {
                CounterController.Pawn.Unpossessed();
                CounterController.Pawn.Destroy();
                CounterController.Pawn = None;
            }

            CounterController.Destroy();
            CounterController = None;
        }
    }
}

defaultproperties
{
    FriendlyName="Hexed UTComp v2dev"
    Description="A minimalist fork of UTComp compatible with HexedUT."
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
    bAddToServerPackages=True
    // configs
    bDisableDoubleDamage=False
    bColoredDeathMessages=True
    bAllowNewNetWeapons=True
    bAllowNewEyeHeightAlgorithm=True
    TimedOvertime=0
    PingTweenTime=3.0
    PawnCollisionHistoryLength=0.35
    //original weapons
    WeaponClasses(0)=class'ShockRifle'
    WeaponClasses(1)=class'LinkGun'
    WeaponClasses(2)=class'Minigun'
    WeaponClasses(3)=class'FlakCannon'
    WeaponClasses(4)=class'RocketLauncher'
    WeaponClasses(5)=class'SniperRifle'
    WeaponClasses(6)=class'BioRifle'
    WeaponClasses(7)=class'AssaultRifle'
    WeaponClasses(8)=class'ClassicSniperRifle'
    WeaponClasses(9)=class'ONSAVRiL'
    WeaponClasses(10)=class'ONSMineLayer'
    WeaponClasses(11)=class'ONSGrenadeLauncher'
    WeaponClasses(12)=class'SuperShockRifle'
    // replaced NewNet classes
    NewNetWeaponClasses(0)=class'NewNet_ShockRifle'
    NewNetWeaponClasses(1)=class'NewNet_LinkGun'
    NewNetWeaponClasses(2)=class'NewNet_MiniGun'
    NewNetWeaponClasses(3)=class'NewNet_FlakCannon'
    NewNetWeaponClasses(4)=class'NewNet_RocketLauncher'
    NewNetWeaponClasses(5)=class'NewNet_SniperRifle'
    NewNetWeaponClasses(6)=class'NewNet_BioRifle'
    NewNetWeaponClasses(7)=class'NewNet_AssaultRifle'
    NewNetWeaponClasses(8)=class'NewNet_ClassicSniperRifle'
    NewNetWeaponClasses(9)=class'NewNet_ONSAVRiL'
    NewNetWeaponClasses(10)=class'NewNet_ONSMineLayer'
    NewNetWeaponClasses(11)=class'NewNet_ONSGrenadeLauncher'
    NewNetWeaponClasses(12)=class'NewNet_SuperShockRifle'
    MenuClass=class'HxMenu'
}
