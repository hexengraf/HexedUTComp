class MutUTComp extends HxMutator;

const AVERDT_SEND_PERIOD = 4.00;

var config bool bAllowEnhancedNetcode;
var config bool bAllowNewEyeHeightAlgorithm;
var config int TimedOvertime;
var config float TimeBetweenPings;
var config float PawnCollisionTimeWindow;

var PawnCollisionCopy PCC;
var float ClientTimeStamp;
var float AverDT;

var private Controller CounterController;
var private FakeProjectileManager FPM;
var private TimeStamp StampInfo;
var private float StampArray[256];
var private float Counter;
var private float LastReplicatedAverDT;

var private class<Weapon> WeaponClasses[13];
var private class<Weapon> NewNetWeaponClasses[13];
var private bool bEnhancedNetcodeActive;
var private bool bPawnClassReplaced;
var private bool bDefaultWeaponsChanged;

event PreBeginPlay()
{
    Super.PreBeginPlay();
    if (Level.NetMode != NM_Standalone)
    {
        SetupNewEyeHeightAlgorithm();
        SetupEnhancedNetcode();
    }
}

function SetupNewEyeHeightAlgorithm()
{
    if (bAllowNewEyeHeightAlgorithm)
    {
        if (Level.Game.DefaultPlayerClassName ~= "xGame.xPawn")
        {
            Level.Game.DefaultPlayerClassName = String(class'UTComp_xPawn');
            bPawnClassReplaced = True;
        }
        else
        {
            Warn(Name@"failed to replace xPawn class, disabling new eye height algorithm.");
            bAllowNewEyeHeightAlgorithm = False;
        }
    }
}

function SetupEnhancedNetcode()
{
    if (bAllowEnhancedNetcode)
    {
        StampInfo = Spawn(class'TimeStamp');
        CounterController = Spawn(class'TimeStamp_Controller');
        if (CounterController.Pawn == None)
        {
            CounterController.Possess(Spawn(CounterController.PawnClass));
        }
        SetupInstagib();
        bEnhancedNetcodeActive = True;
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
    if (bEnhancedNetcodeActive)
    {
        SpawnCollisionCopy(Other);
    }
    if (UTComp_xPawn(Other) != None)
    {
        UTComp_xPawn(Other).bAllowNewEyeHeightAlgorithm = bAllowNewEyeHeightAlgorithm;
    }
    Super.ModifyPlayer(Other);
}

function SpawnCollisionCopy(Pawn Other)
{
    if (PCC == None)
    {
        PCC = Spawn(class'PawnCollisionCopy');
        PCC.SetPawn(Other);
    }
    else
    {
        PCC.AddPawnToList(Other);
    }
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
    Super.DriverEnteredVehicle(V, P);
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
    Super.DriverLeftVehicle(V, P);
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
    if (bEnhancedNetcodeActive)
    {
        if (Level.NetMode == NM_Client)
        {
            if (FPM == None)
            {
                FPM = Spawn(Class'FakeProjectileManager');
            }
        }
        else
        {
            if (!bDefaultWeaponsChanged)
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

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local WeaponLocker L;
    local int x;
    local int i;

    if (bEnhancedNetcodeActive)
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
        }
        else if (WeaponPickup(Other) != None)
        {
            for (x = 0; x < ArrayCount(WeaponClasses); ++x)
            {
                if (WeaponPickup(Other).InventoryType == WeaponClasses[x])
                {
                    WeaponPickup(Other).InventoryType = NewNetWeaponClasses[x];
                }
            }
        }
        else if (WeaponLocker(Other) != None)
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
        }
    }
    return Super.CheckReplacement(Other, bSuperRelevant);
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

    Super.GetServerDetails(ServerState);
    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "Enhanced netcode";
    ServerState.ServerInfo[i++].Value = Eval(bEnhancedNetcodeActive, "Enabled", "Disabled");
    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "New EyeHeight algorithm";
    ServerState.ServerInfo[i++].Value = Eval(bPawnClassReplaced, "Enabled", "Disabled");
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
    local int i;

    if (Level.NetMode != NM_Client)
    {
        // remove all Timestamp_pawn from clients
        for (i = 0; i < CRIs.Length; ++i)
        {
            if(NewNet_Client(CRIs[i]) != None)
            {
                NewNet_Client(CRIs[i]).ClientResetNetcode();
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
    FriendlyName="HexedUTComp v6dev"
    Description="Cutdown version of UTComp providing new eye height algorithm, enhanced netcode, and timed overtime."
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
    bAddToServerPackages=True

    MutatorGroup="HexedUTComp"
    CRIClass=class'NewNet_Client'
    Properties(0)=(Name="bAllowEnhancedNetcode",Section="Enhanced Netcode",Caption="Allow enhanced netcode",Hint="Allow clients to enable/disable the enhanced netcode.",Type="Check",bMPOnly=true,bAdvanced=true)
    Properties(1)=(Name="TimeBetweenPings",Section="Enhanced Netcode",Caption="Time between pings",Hint="Time to wait between pings (in seconds).",Type="Text",Data="4;0.0:360.0",bMPOnly=true,bAdvanced=true)
    Properties(2)=(Name="PawnCollisionTimeWindow",Section="Enhanced Netcode",Caption="Pawn collision time window",Hint="Time window (in seconds) to look back for pawn collisions.",Type="Text",Data="4;0.0:360.0",bMPOnly=true,bAdvanced=true)
    Properties(3)=(Name="bAllowNewEyeHeightAlgorithm",Section="EyeHeight Algorithm",Caption="Allow new EyeHeight algorithm",Hint="Allow clients to enable/disable the new EyeHeight algorithm.",Type="Check",bMPOnly=true)
    Properties(4)=(Name="TimedOvertime",Section="Miscellaneous",Caption="Timed overtime duration",Type="Text",Hint="Duration of timed overtime (in seconds).",Data="4;0:3600")

    // configs
    bAllowEnhancedNetcode=True
    bAllowNewEyeHeightAlgorithm=True
    TimeBetweenPings=3.0
    PawnCollisionTimeWindow=0.35
    TimedOvertime=0
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
}
