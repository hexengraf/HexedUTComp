class NewNet_SuperShockBeamEffect extends ShockBeamEffect;

var class<ShockBeamEffect> ExtraBeamClass;

function AimAt(Vector hl, Vector hn)
{
    if(bNetOwner && Level.NetMode == NM_Client)
        return;
    super.AimAt(hl,hn);
}

simulated function PostBeginPlay()
{
    if(bNetOwner && Level.NetMode == NM_Client)
        return;
    super.PostBeginPlay();
}

simulated function PostNetBeginPlay()
{
    local playercontroller pc;
    super.PostNetBeginPlay();
    if(Level.NetMode != NM_Client)
        return;
    PC = Level.GetLocalPlayerController();

    if(PC!=None && PC.Pawn!=None && PC.Pawn == Instigator)
    {
        Destroy();
    }
}

simulated function SpawnEffects()
{
    local ShockBeamCoil Coil;
    local xWeaponAttachment Attachment;
    local playercontroller pc;
    local ShockBeamEffect E;

    if(Level.NetMode == NM_Client)
    {
        PC = Level.GetLocalPlayerController();
        if(PC!=None && PC.Pawn!=None && PC.Pawn == Instigator)
        {
            return;
        }
    }

    if (Instigator != None)
    {
        if ( Instigator.IsFirstPerson() )
        {
			if ( (Instigator.Weapon != None) && (Instigator.Weapon.Instigator == Instigator) )
				SetLocation(Instigator.Weapon.GetEffectStart());
			else
				SetLocation(Instigator.Location);
            Spawn(MuzFlashClass,,, Location);
        }
        else
        {
            Attachment = xPawn(Instigator).WeaponAttachment;
            if (Attachment != None && (Level.TimeSeconds - Attachment.LastRenderTime) < 1)
                SetLocation(Attachment.GetTipLocation());
            else
                SetLocation(Instigator.Location + Instigator.EyeHeight*Vect(0,0,1) + Normal(mSpawnVecA - Instigator.Location) * 25.0);
            Spawn(MuzFlash3Class);
        }
    }

    if ( EffectIsRelevant(mSpawnVecA + HitNormal*2,false) && (HitNormal != Vect(0,0,0)) )
		SpawnImpactEffects(Rotator(HitNormal),mSpawnVecA + HitNormal*2);

    if ( (!Level.bDropDetail && (Level.DetailMode != DM_Low) && (VSize(Location - mSpawnVecA) > 40) && !Level.GetLocalPlayerController().BeyondViewDistance(Location,0))
		|| ((Instigator != None) && Instigator.IsFirstPerson()) )
    {
	    Coil = Spawn(CoilClass,Owner,, Location, Rotation);
	    if (Coil != None)
		    Coil.mSpawnVecA = mSpawnVecA;
    }

    E = Spawn(ExtraBeamClass, Owner);
    if ( E != None )
        E.AimAt(mSpawnVecA, HitNormal);
}


defaultproperties
{
     CoilClass=Class'NewNet_ShockBeamCoilB'
     ExtraBeamClass=class'NewNet_ExtraRedBeam'
     Skins(0)=ColorModifier'InstagibEffects.Effects.RedSuperShockBeam'
}
