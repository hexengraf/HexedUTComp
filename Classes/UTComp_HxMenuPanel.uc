class UTComp_HxMenuPanel extends HxGUIMenuPanel;

const SECTION_USER = 0;
const SECTION_SERVER = 1;

var automated array<GUIMenuOption> ServerOptions;
var automated array<GUIMenuOption> UserOptions;

var private NewNet_Client Client;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;
    local int Order;

    for (i = 0; i < UserOptions.Length; ++i)
    {
        UserOptions[i].TabOrder = Order++;
        UserOptions[i].OnLoadINI = DefaultOnLoadINI;
        UserOptions[i].OnChange = UserOnChange;
    }
    for (i = 0; i < ServerOptions.Length; ++i)
    {
        ServerOptions[i].TabOrder = Order++;
        ServerOptions[i].Caption = class'MutUTComp'.default.PropertyInfoEntries[i].Caption;
        ServerOptions[i].Hint = class'MutUTComp'.default.PropertyInfoEntries[i].Hint;
        ServerOptions[i].INIOption = class'MutUTComp'.default.PropertyInfoEntries[i].Name;
        ServerOptions[i].OnLoadINI = RemoteOnLoadINI;
        ServerOptions[i].OnChange = RemoteOnChange;
    }
    super.InitComponent(MyController,MyOwner);
    for (i = 0; i < ServerOptions.Length; ++i)
    {
        Sections[SECTION_SERVER].Insert(ServerOptions[i]);
    }

    for (i = 0; i < UserOptions.Length; ++i)
    {
        Sections[SECTION_USER].Insert(UserOptions[i]);
    }
}

function bool Initialize()
{
    if (Client != None)
    {
        return true;
    }
    Client = class'NewNet_Client'.static.GetClient();
    return Client != None;
}

function Refresh()
{
    NewNetWeaponsAfterChange(Client.bAllowEnhancedNetcode);
    NewEyeHeightAlgorithmAfterChange(Client.bAllowNewEyeHeightAlgorithm);
    Sections[SECTION_SERVER].SetHide(!IsAdmin(), HideDueAdmin);
    Sections[SECTION_USER].SetHide(false);
    Super.Refresh();
}

function NewNetWeaponsAfterChange(coerce bool bEnable)
{
    local int i;

    for (i = 3; i < ServerOptions.Length; ++i)
    {
        SetEnable(ServerOptions[i], bEnable);
    }
    SetEnable(UserOptions[0], bEnable);
}

function NewEyeHeightAlgorithmAfterChange(coerce bool bEnable)
{
    SetEnable(UserOptions[1], bEnable);
    SetEnable(UserOptions[2], bEnable && class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm);
}

function RemoteOnLoadINI(GUIComponent Sender, string s)
{
    local GUIMenuOption Option;

    Option = GUIMenuOption(Sender);
    if (Client != None && Option != None)
    {
        Option.SetComponentValue(Client.GetPropertyText(Option.INIOption));
    }
}

function RemoteOnChange(GUIComponent Sender)
{
    local GUIMenuOption Option;

    Option = GUIMenuOption(Sender);
    if (Client != None && Option != None && IsAdmin())
    {
        Client.RemoteSetProperty(Option.INIOption, Option.GetComponentValue());
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
            class'NewNet_Client'.static.SetEnhancedNetCode(Option.GetComponentValue());
            break;
        case UserOptions[1]:
            class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm = bool(Option.GetComponentValue());
            NewEyeHeightAlgorithmAfterChange(Client.bAllowNewEyeHeightAlgorithm);
            break;
        case UserOptions[2]:
            class'UTComp_xPawn'.default.bViewSmoothing =  bool(Option.GetComponentValue());
            break;
    }
    Pawn = UTComp_xPawn(PlayerOwner().Pawn);
    if (Pawn != None)
    {
        Pawn.bNewEyeHeightAlgorithm = class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm;
        Pawn.bViewSmoothing = class'UTComp_xPawn'.default.bViewSmoothing;
    }
    class'UTComp_xPawn'.static.StaticSaveConfig();
}

defaultproperties
{
    Begin Object class=HxGUIFramedSection Name=ServerSection
        Caption="Server Options"
        LineSpacing=0.02
        bAutoSpacing=false
    End Object

    Begin Object class=HxGUIFramedSection Name=UserSection
        Caption="User Options"
        LineSpacing=0.02
        bAutoSpacing=false
    End Object

    Begin Object Class=moCheckBox Name=AllowNewNetWeapons
    End Object

    Begin Object Class=moCheckBox Name=AllowNewEyeHeightAlgorithm
    End Object

    Begin Object class=moNumericEdit Name=TimedOvertime
        MinValue=0
        MaxValue=3600
        Step=10
        ComponentWidth=0.2
    End Object

    Begin Object class=moFloatEdit Name=PingTweenTime
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        ComponentWidth=0.2
    End Object

    Begin Object class=moFloatEdit Name=PawnCollisionHistoryLength
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        ComponentWidth=0.2
    End Object

    Begin Object Class=moCheckBox Name=EnhancedNetCode
        Caption="Enable Enhanced Netcode"
        INIOption="NewNet_Client bEnhancedNetCode"
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
    bDoubleColumn=true
    Sections(0)=UserSection
    Sections(1)=ServerSection
    ServerOptions(0)=AllowNewNetWeapons
    ServerOptions(1)=AllowNewEyeHeightAlgorithm
    ServerOptions(2)=TimedOvertime
    ServerOptions(3)=PingTweenTime
    ServerOptions(4)=PawnCollisionHistoryLength
    UserOptions(0)=EnhancedNetCode
    UserOptions(1)=NewEyeHeightAlgorithm
    UserOptions(2)=ViewSmoothing
}
