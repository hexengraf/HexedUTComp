class TimeStamp_Pawn extends Pawn;

var int Timestamp;
var int NewTimestamp;
var float DT;

simulated event Tick(float DeltaTime)
{
   Super.Tick(DeltaTime);
   NewTimestamp = (Rotation.Yaw + Rotation.Pitch * 256) / 256;
   DT += DeltaTime;
   if(NewTimestamp > Timestamp || Timestamp - NewTimestamp > 5000)
   {
       Timestamp = NewTimestamp;
       DT = 0.00;
   }
}

function Reset()
{
    // skip Pawn.Reset() to prevent self-destroy
    Super(Actor).Reset();
}

DefaultProperties
{
    ControllerClass=None
    bAlwaysRelevant=true
    NetPriority=50
    bCollideActors=false
    bCollideWorld=false
    bBlockActors=false
    bProjTarget=false
    bCanBeDamaged=false
    bAcceptsProjectors=false
    bCanTeleport=false
    bBlockPlayers=false
    bDisturbFluidSurface=false
    Physics=Phys_None
    bStasis=false
}
