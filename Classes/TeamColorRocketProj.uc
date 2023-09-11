class TeamColorRocketProj extends RocketProj;

var int TeamNum;
var bool bColorSet;

var Emitter RocketTrail;

replication
{
    unreliable if(Role == Role_Authority)
       TeamNum;
}

simulated function bool CanUseColors()
{
   local UTComp_ServerReplicationInfo RepInfo;

    RepInfo = class'UTComp_Util'.static.GetServerReplicationInfo(Instigator);
    if(RepInfo != None)
        return RepInfo.bAllowColorWeapons;

    return false;
}

function SetupTeam()
{
    if(Instigator != None && Instigator.Controller != None)
    {
        TeamNum=class'TeamColorManager'.static.GetTeamNum(Instigator.Controller, Level);
    }
}

simulated function SetupColor()
{
    local Color c;
    local UTComp_Settings Settings;
    if(!bColorSet && Level.NetMode != NM_DedicatedServer)
    {
        Settings = BS_xPlayer(Level.GetLocalPlayerController()).Settings;
        if(Settings.bTeamColorRockets && CanUseColors())
        {
            if(TeamNum == 0 || TeamNum == 1)
            {
                c = class'TeamColorManager'.static.GetColor(TeamNum, Level.GetLocalPlayerController());
                LightHue=class'TeamColorManager'.static.GetHue(c);
                bColorSet=true;
            }
        }
    }
    //other stuff is done by corona and trails
}

//override PostBeginPlay so we can spawn team color effects
simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer)
	{
		SmokeTrail = Spawn(class'RocketTrailSmoke',self);
		Corona = Spawn(class'TeamColorRocketCorona',self);
		RocketTrail = Spawn(class'TeamColorRocketTrail',self);
        if(RocketTrail != None)
            RocketTrail.SetBase(self);
	}

	Dir = vector(Rotation);
	Velocity = speed * Dir;
	if (PhysicsVolume.bWaterVolume)
	{
		bHitWater = True;
		Velocity=0.6*Velocity;
	}

    SetupTeam();

	Super(Projectile).PostBeginPlay();
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if(Level.NetMode == NM_DedicatedServer)
        return;

    SetupTeam();
}

simulated function Destroyed()
{
    if(RocketTrail != None)
        RocketTrail.Destroy();

    super.Destroyed();
}

simulated function Tick(float DT)
{
    super.Tick(DT);
    SetupColor();
}

defaultproperties
{
    TeamNum=255
}