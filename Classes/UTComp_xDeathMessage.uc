class UTComp_xDeathMessage extends xDeathMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local string KillerName, VictimName;

    if (Class<DamageType>(OptionalObject) == None)
        return "";

    if (RelatedPRI_2 == None)
        VictimName = Default.SomeoneString;
    else
    {
        if(RelatedPRI_2.Team!=None && RelatedPRI_2.Team.TeamIndex == 0)
            VictimName = MakeColorCode(class'HUD'.default.RedColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else if(RelatedPRI_2.Team!=None && RelatedPRI_2.Team.TeamIndex == 1)
            VictimName = MakeColorCode(class'HUD'.default.BlueColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else
            VictimName = MakeColorCode(class'HUD'.default.WhiteColor)$RelatedPRI_2.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
    }
    if ( Switch == 1 )
    {
        // suicide
        return class'GameInfo'.Static.ParseKillMessage(
            KillerName,
            VictimName,
            Class<DamageType>(OptionalObject).Static.SuicideMessage(RelatedPRI_2) );
    }

    if (RelatedPRI_1 == None)
        KillerName = Default.SomeoneString;
    else
    {
        if(RelatedPRI_1.Team!=None && RelatedPRI_1.Team.TeamIndex == 0)
            KillerName = MakeColorCode(class'HUD'.default.RedColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else if(RelatedPRI_1.Team!=None && RelatedPRI_1.Team.TeamIndex == 1)
            KillerName = MakeColorCode(class'HUD'.default.BlueColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'HUD'.Default.GreenColor);
        else
            KillerName = MakeColorCode(class'HUD'.default.WhiteColor)$RelatedPRI_1.PlayerName$MakeColorCode(class'Hud'.default.GreenColor);
    }

    return class'GameInfo'.Static.ParseKillMessage(
        KillerName,
        VictimName,
        Class<DamageType>(OptionalObject).Static.DeathMessage(RelatedPRI_1, RelatedPRI_2) );
}

static function string MakeColorCode(color NewColor)
{
    // Text colours use 1 as 0.
    if(NewColor.R == 0)
        NewColor.R = 1;

    if(NewColor.G == 0)
        NewColor.G = 1;

    if(NewColor.B == 0)
        NewColor.B = 1;

    return Chr(0x1B)$Chr(NewColor.R)$Chr(NewColor.G)$Chr(NewColor.B);
}

defaultproperties
{
}
