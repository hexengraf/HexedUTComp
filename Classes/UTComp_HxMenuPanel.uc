class UTComp_HxMenuPanel extends HxMenuBasePanel;

const SECTION_SERVER = 0;
const SECTION_USER = 1;

var automated array<GUIMenuOption> ServerOptions;
var automated array<GUIMenuOption> UserOptions;
var NewNet_PRI PRI;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;

    for (i = 0; i < ServerOptions.Length; ++i)
    {
        ServerOptions[i].OnLoadINI = RemoteOnLoadINI;
        ServerOptions[i].OnChange = RemoteOnChange;
    }
    for (i = 0; i < UserOptions.Length; ++i)
    {
        UserOptions[i].OnLoadINI = DefaultOnLoadINI;
        UserOptions[i].OnChange = UserOnChange;
    }
    for (i = 0; i < ServerOptions.Length; ++i)
    {
        Sections[SECTION_SERVER].ManageComponent(ServerOptions[i]);
    }

    for (i = 0; i < UserOptions.Length; ++i)
    {
        Sections[SECTION_USER].ManageComponent(UserOptions[i]);
    }
    super.InitComponent(MyController,MyOwner);
    SetVisibility(true);
}

function bool Initialize()
{
    if (PRI != None)
    {
        return true;
    }
    PRI = class'NewNet_PRI'.static.GetPRI(PlayerOwner());
    return PRI != None;
}

function Refresh()
{
    NewNetWeaponsAfterChange(PRI.bAllowNewNetWeapons);
    NewEyeHeightAlgorithmAfterChange(PRI.bAllowNewEyeHeightAlgorithm);
    HideSection(SECTION_SERVER, !IsAdmin(), HIDE_DUE_ADMIN);
    HideSection(SECTION_USER, false);
    Super.Refresh();
}

function NewNetWeaponsAfterChange(coerce bool bEnable)
{
    local int i;

    if (bEnable)
    {
        for (i = 3; i < ServerOptions.Length; ++i)
        {
            EnableComponent(ServerOptions[i]);
        }
        EnableComponent(UserOptions[0]);
    }
    else
    {
        for (i = 3; i < ServerOptions.Length; ++i)
        {
            DisableComponent(ServerOptions[i]);
        }
        DisableComponent(UserOptions[0]);
    }

}

function NewEyeHeightAlgorithmAfterChange(coerce bool bEnable)
{
    if (bEnable)
    {
        EnableComponent(UserOptions[1]);
        if (class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm)
        {
            EnableComponent(UserOptions[2]);
        }
        else
        {
            DisableComponent(UserOptions[2]);
        }
    }
    else
    {
        DisableComponent(UserOptions[1]);
        DisableComponent(UserOptions[2]);
    }
}

function RemoteOnLoadINI(GUIComponent Sender, string s)
{
    local GUIMenuOption Option;

    Option = GUIMenuOption(Sender);
    if (PRI != None && Option != None)
    {
        Option.SetComponentValue(PRI.GetPropertyText(Option.INIOption));
    }
}

function RemoteOnChange(GUIComponent Sender)
{
    local GUIMenuOption Option;

    Option = GUIMenuOption(Sender);
    if (PRI != None && Option != None && IsAdmin())
    {
        PRI.RemoteSetProperty(Option.INIOption, Option.GetComponentValue());
    }
    switch (Option)
    {
        case ServerOptions[0]:
            NewNetWeaponsAfterChange(Option.GetComponentValue());
            break;
        case ServerOptions[1]:
            NewEyeHeightAlgorithmAfterChange(Option.GetComponentValue());
            break;
    }
}

function UserOnChange(GUIComponent Sender)
{
    local GUIMenuOption Option;
    local UTComp_xPawn Pawn;

    Option = GUIMenuOption(Sender);
    if (Option == None)
    {
        return;
    }
    switch (Option)
    {
        case UserOptions[0]:
            class'UTComp_xPawn'.default.bEnhancedNetCode = bool(Option.GetComponentValue());
            break;
        case UserOptions[1]:
            class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm = bool(Option.GetComponentValue());
            NewEyeHeightAlgorithmAfterChange(PRI.bAllowNewEyeHeightAlgorithm);
            break;
        case UserOptions[2]:
            class'UTComp_xPawn'.default.bViewSmoothing =  bool(Option.GetComponentValue());
            break;
    }
    Pawn = UTComp_xPawn(PlayerOwner().Pawn);
    if (Pawn != None)
    {
        Pawn.bEnhancedNetCode = class'UTComp_xPawn'.default.bEnhancedNetCode;
        Pawn.bNewEyeHeightAlgorithm = class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm;
        Pawn.bViewSmoothing = class'UTComp_xPawn'.default.bViewSmoothing;
    }
    class'UTComp_xPawn'.static.StaticSaveConfig();
}

static function bool AddToMenu()
{
    local int i;
    local int Order;

    if (Super.AddToMenu())
    {
        for (i = 0; i < default.ServerOptions.Length; ++i)
        {
            default.ServerOptions[i].TabOrder = Order++;
            default.ServerOptions[i].Caption = class'MutUTComp'.default.PropertyInfoEntries[i].Caption;
            default.ServerOptions[i].Hint = class'MutUTComp'.default.PropertyInfoEntries[i].Hint;
            default.ServerOptions[i].INIOption = class'MutUTComp'.default.PropertyInfoEntries[i].Name;
        }
        for (i = 0; i < default.UserOptions.Length; ++i)
        {
            default.UserOptions[i].TabOrder = Order++;
        }
        return true;
    }
    return false;
}

defaultproperties
{
    Begin Object class=AltSectionBackground Name=ServerSection
        Caption="Server Options"
    End Object

    Begin Object class=AltSectionBackground Name=UserSection
        Caption="User Options"
    End Object

    Begin Object Class=moCheckBox Name=AllowNewNetWeapons
    End Object

    Begin Object Class=moCheckBox Name=AllowNewEyeHeightAlgorithm
    End Object

    Begin Object class=moNumericEdit Name=TimedOvertime
        MinValue=0
        MaxValue=3600
        Step=10
        ComponentWidth=0.25
    End Object

    Begin Object class=moFloatEdit Name=PingTweenTime
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        ComponentWidth=0.25
    End Object

    Begin Object class=moFloatEdit Name=PawnCollisionHistoryLength
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        ComponentWidth=0.25
    End Object

    Begin Object Class=moCheckBox Name=EnhancedNetCode
        Caption="Enable Enhanced Netcode"
        INIOption="UTComp_xPawn bEnhancedNetCode"
    End Object

    Begin Object Class=moCheckBox Name=NewEyeHeightAlgorithm
        Caption="Enable New EyeHeight Algorithm"
        INIOption="UTComp_xPawn bNewEyeHeightAlgorithm"
    End Object

    Begin Object Class=moCheckBox Name=ViewSmoothing
        Caption="View smoothing"
        Hint="Smooth the view when using new EyeHeight algorithm"
        INIOption="UTComp_xPawn bViewSmoothing"
    End Object

    PanelCaption="UTComp"
    PanelHint="UTComp Features"
    bDoubleColumn=false
    Sections(0)=ServerSection
    Sections(1)=UserSection
    ServerOptions(0)=AllowNewNetWeapons
    ServerOptions(1)=AllowNewEyeHeightAlgorithm
    ServerOptions(2)=TimedOvertime
    ServerOptions(3)=PingTweenTime
    ServerOptions(4)=PawnCollisionHistoryLength
    UserOptions(0)=EnhancedNetCode
    UserOptions(1)=NewEyeHeightAlgorithm
    UserOptions(2)=ViewSmoothing
}
