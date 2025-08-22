class UTComp_xPawn extends xPawn;

var config bool bEnhancedNetCode;
var config bool bNewEyeHeightAlgorithm;
var config bool bViewSmoothing;

var bool bAllowNewEyeHeightAlgorithm;
// UpdateEyeHeight related
var EPhysics OldPhysics2;
var vector OldLocation;
var float OldBaseEyeHeight;
var int IgnoreZChangeTicks;
var float EyeHeightOffset;

replication
{
    reliable if (Role < Role_Authority)
        TurnOffNetCode;

    reliable if(Role == ROLE_Authority)
        ClientResetNetcode;

    reliable if (Role == ROLE_Authority)
        bAllowNewEyeHeightAlgorithm;
}

simulated event PostNetBeginPlay()
{
    Super.PostNetBeginPlay();
    OldBaseEyeHeight = Default.BaseEyeHeight;
    OldLocation = Location;
}

simulated function ClientRestart()
{
    Super.ClientRestart();
    IgnoreZChangeTicks = 1;
}

simulated function Touch(Actor Other)
{
    Super.Touch(Other);
    if (Other != None && Other.IsA('Teleporter'))
    {
        IgnoreZChangeTicks = 2;
    }
}

event UpdateEyeHeight(float DeltaTime)
{
    local vector Delta;

    if (Controller == None || Level.NetMode == NM_DedicatedServer || bTearOff
        || !bAllowNewEyeHeightAlgorithm || !bNewEyeHeightAlgorithm)
    {
        Super.UpdateEyeHeight(DeltaTime);
        return;
    }
    if (WantsSmoothedView())
    {
        Delta = Location - OldLocation;
        // remove lifts from the equation.
        if (Base != None)
        {
            Delta -= DeltaTime * Base.Velocity;
        }
        // Step detection heuristic
        if (IgnoreZChangeTicks == 0 && Abs(Delta.Z) > DeltaTime * GroundSpeed)
        {
            EyeHeightOffset += FClamp(Delta.Z, -MAXSTEPHEIGHT, MAXSTEPHEIGHT);
        }
    }
    OldLocation = Location;
    OldPhysics2 = Physics;
    if (IgnoreZChangeTicks > 0)
    {
        IgnoreZChangeTicks--;
    }
    if (WantsSmoothedView())
    {
        EyeHeightOffset += BaseEyeHeight - OldBaseEyeHeight;
    }
    OldBaseEyeHeight = BaseEyeHeight;
    EyeHeightOffset *= Exp(-9.0 * DeltaTime);
    EyeHeight = BaseEyeHeight - EyeHeightOffset;
    Controller.AdjustView(DeltaTime);
}

function bool WantsSmoothedView()
{
    if (Controller.IsInState('PlayerSwimming'))
    {
        return !bJustLanded;
    }
    return ((Physics == PHYS_Walking || Physics == PHYS_Spider)
            && (bViewSmoothing || !bJustLanded))
        || (Physics == PHYS_Falling && OldPhysics2 == PHYS_Walking);
}

// override to fix None access
function ServerChangedWeapon(Weapon OldWeapon, Weapon NewWeapon)
{
	local float InvisTime;

	if ( bInvis )
	{
	    if ( (OldWeapon != None) && (OldWeapon.OverlayMaterial == InvisMaterial) )
		    InvisTime = OldWeapon.ClientOverlayCounter;
	    else
		    InvisTime = 20000;
	}
    if (HasUDamage() || bInvis)
        SetWeaponOverlay(None, 0.f, true);

    Super(UnrealPawn).ServerChangedWeapon(OldWeapon, NewWeapon);

    if (bInvis)
        SetWeaponOverlay(InvisMaterial, InvisTime, true);
    else if (HasUDamage())
        SetWeaponOverlay(UDamageWeaponMaterial, UDamageTime - Level.TimeSeconds, false);

    // check for none here
    if(Weapon != None)
    {
        if (bBerserk)
            Weapon.StartBerserk();
        else if ( Weapon.bBerserk )
            Weapon.StopBerserk();
    }
}

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);
    // fix annoying bug where sometimes weapon instigator gets set to none
    // due to race condition in replication
    if(Level.NetMode == NM_Client && Weapon != None && Weapon.Instigator != Self)
    {
        Weapon.Instigator = Self;
    }
}

function TurnOffNetCode()
{
    local inventory Inv;

    for (Inv = Inventory; Inv != None; Inv = Inv.inventory)
    {
        if (Weapon(Inv) != None)
        {
            if (NewNet_AssaultRifle(Inv) != None)
            {
                NewNet_AssaultRifle(Inv).DisableNet();
            }
            else if (NewNet_BioRifle(Inv) != None)
            {
                NewNet_BioRifle(Inv).DisableNet();
            }
            else if (NewNet_ShockRifle(Inv) != None)
            {
                NewNet_ShockRifle(Inv).DisableNet();
            }
            else if (NewNet_MiniGun(Inv) != None)
            {
                NewNet_MiniGun(Inv).DisableNet();
            }
            else if (NewNet_LinkGun(Inv) != None)
            {
                NewNet_LinkGun(Inv).DisableNet();
            }
            else if (NewNet_RocketLauncher(Inv) != None)
            {
                NewNet_RocketLauncher(Inv).DisableNet();
            }
            else if (NewNet_FlakCannon(Inv) != None)
            {
                NewNet_FlakCannon(Inv).DisableNet();
            }
            else if (NewNet_SniperRifle(Inv) != None)
            {
                NewNet_SniperRifle(Inv).DisableNet();
            }
            else if (NewNet_ClassicSniperRifle(Inv) != None)
            {
                NewNet_ClassicSniperRifle(Inv).DisableNet();
            }
        }
    }
}

simulated function SetEnhancedNetCode(bool bEnable)
{
    bEnhancedNetCode = bEnable;
    Default.bEnhancedNetCode = bEnable;
    if (!bEnable)
    {
        TurnOffNetCode();
    }
}

simulated function ClientResetNetcode()
{
    local Timestamp_Pawn P;

    ForEach DynamicActors(class'Timestamp_Pawn', P)
    {
        if(P != None)
        {
            P.Destroy();
        }
    }
}

defaultproperties
{
    bAlwaysRelevant=True
    bEnhancedNetCode=True
    bNewEyeHeightAlgorithm=True
    bViewSmoothing=True
    bAllowNewEyeHeightAlgorithm=False
}
