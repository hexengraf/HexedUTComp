class UTComp_xDeathMessage extends xDeathMessage;

static function string GetString(optional int Switch,
	                             optional PlayerReplicationInfo RelatedPRI_1,
	                             optional PlayerReplicationInfo RelatedPRI_2,
	                             optional Object OptionalObject)
{
	if (Class<DamageType>(OptionalObject) == None)
    {
		return "";
    }
	if (Switch == 1)
	{
		return class'GameInfo'.Static.ParseKillMessage(
			"",
			GetColoredName(RelatedPRI_2),
			Class<DamageType>(OptionalObject).Static.SuicideMessage(RelatedPRI_2));
	}
	return class'GameInfo'.Static.ParseKillMessage(
		GetColoredName(RelatedPRI_1),
		GetColoredName(RelatedPRI_2),
		Class<DamageType>(OptionalObject).Static.DeathMessage(RelatedPRI_1, RelatedPRI_2));
}

static function string GetColoredName(PlayerReplicationInfo PRI)
{
    if (PRI == None)
    {
        return Default.SomeoneString;
    }
    if (PRI.Team.TeamIndex < 2)
    {
        return GetColorCode(class'HudCDeathMatch'.Static.GetTeamColor(PRI.Team.TeamIndex))$PRI.PlayerName$GetColorCode(class'HUD'.Default.GreenColor);
    }
    return PRI.PlayerName;
}

static function string GetColorCode(Color C)
{
    if(C.R == 0)
    {
        C.R = 1;
    }
    if(C.G == 0)
    {
        C.G = 1;
    }
    if(C.B == 0)
    {
        C.B = 1;
    }
    return Chr(0x1B)$Chr(C.R)$Chr(C.G)$Chr(C.B);
}

defaultproperties
{
}
