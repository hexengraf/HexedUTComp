class UTComp_HxMenuPanel extends HxMenuPanel;

const SECTION_SERVER = 0;
const SECTION_USER = 1;

var automated array<HxMenuOption> ServerOptions;
var automated array<HxMenuOption> UserOptions;
var NewNet_PRI PRI;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;

    super.InitComponent(MyController,MyOwner);

    for (i = 0; i < ServerOptions.Length; ++i)
    {
        Sections[SECTION_SERVER].ManageComponent(ServerOptions[i]);
    }

    for (i = 0; i < UserOptions.Length; ++i)
    {
        Sections[SECTION_USER].ManageComponent(UserOptions[i]);
    }
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
    local int i;

    for (i = 0; i < ServerOptions.Length; ++i)
    {
        ServerOptions[i].GetValueFrom(PRI);
    }
    UserOptions[0].SetComponentValue(class'UTComp_xPawn'.default.bEnhancedNetCode);
    UserOptions[1].SetComponentValue(class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm);
    UserOptions[2].SetComponentValue(class'UTComp_xPawn'.default.bViewSmoothing);
    NewNetWeaponsAfterChange(PRI.bAllowNewNetWeapons);
    NewEyeHeightAlgorithmAfterChange(PRI.bAllowNewEyeHeightAlgorithm);
    HideSection(SECTION_SERVER, !IsAdmin(), HIDE_DUE_ADMIN);
    HideSection(SECTION_USER, false);
}

function NewNetWeaponsAfterChange(coerce bool bEnable)
{
    local int i;

    for (i = 5; i < 7; ++i)
    {
        ServerOptions[i].SetEnable(bEnable);
    }
    UserOptions[0].SetEnable(bEnable);
}

function NewEyeHeightAlgorithmAfterChange(coerce bool bEnable)
{
    UserOptions[1].SetEnable(bEnable);
    UserOptions[2].SetEnable(bEnable && class'UTComp_xPawn'.default.bNewEyeHeightAlgorithm);
}

function RemoteOnChange(GUIComponent C)
{
    local HxMenuOption Option;

    Option = HxMenuOption(C);
    if (PRI != None && Option != None && IsAdmin())
    {
        PRI.RemoteSetProperty(Option.PropertyName, Option.GetComponentValue());
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

function UserOnChange(GUIComponent C)
{
    local HxMenuOption Option;
    local UTComp_xPawn Pawn;

    Option = HxMenuOption(C);
    if (Option == None)
    {
        return;
    }
    Pawn = UTComp_xPawn(PlayerOwner().Pawn);

    if (Pawn != None)
    {
        Option.SetValueOn(Pawn);
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
    class'UTComp_xPawn'.static.StaticSaveConfig();
}

static function AddToMenu()
{
    local int i;
    local int Order;

    for (i = 0; i < default.ServerOptions.Length; ++i)
    {
        default.ServerOptions[i].TabOrder = Order++;
        default.ServerOptions[i].Caption = class'MutUTComp'.default.PropertyInfoEntries[i].Caption;
        default.ServerOptions[i].Hint = class'MutUTComp'.default.PropertyInfoEntries[i].Hint;
        default.ServerOptions[i].PropertyName = class'MutUTComp'.default.PropertyInfoEntries[i].Name;
    }
    for (i = 0; i < default.UserOptions.Length; ++i)
    {
        default.UserOptions[i].TabOrder = Order++;
    }
    class'HxMenu'.static.AddPanel(default.Class, "UTComp", "UTComp Features");
}

defaultproperties
{
    Begin Object class=AltSectionBackground Name=ServerSection
        Caption="Server Options"
        WinHeight=0.56
    End Object

    Begin Object class=AltSectionBackground Name=UserSection
        Caption="User Options"
        WinHeight=0.24
    End Object

    Begin Object Class=HxMenuCheckBox Name=AllowNewNetWeapons
        OnChange=RemoteOnChange
    End Object

    Begin Object Class=HxMenuCheckBox Name=AllowNewEyeHeightAlgorithm
        OnChange=RemoteOnChange
    End Object

    Begin Object Class=HxMenuCheckBox Name=DisableDoubleDamage
        OnChange=RemoteOnChange
    End Object

    Begin Object Class=HxMenuCheckBox Name=ColoredDeathMessages
        OnChange=RemoteOnChange
    End Object

    Begin Object class=HxMenuNumericEdit Name=TimedOvertime
        MinValue=0
        MaxValue=3600
        OnChange=RemoteOnChange
    End Object

    Begin Object class=HxMenuFloatEdit Name=PingTweenTime
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        OnChange=RemoteOnChange
    End Object

    Begin Object class=HxMenuFloatEdit Name=PawnCollisionHistoryLength
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        OnChange=RemoteOnChange
    End Object

    Begin Object Class=HxMenuCheckBox Name=EnhancedNetCode
        Caption="Enable Enhanced Netcode"
        PropertyName="bEnhancedNetCode"
        OnChange=UserOnChange
    End Object

    Begin Object Class=HxMenuCheckBox Name=NewEyeHeightAlgorithm
        Caption="Enable New EyeHeight Algorithm"
        Hint="You want this"
        PropertyName="bNewEyeHeightAlgorithm"
        OnChange=UserOnChange
    End Object

    Begin Object Class=HxMenuCheckBox Name=ViewSmoothing
        Caption="View smoothing"
        Hint="Smooth the view when using new EyeHeight algorithm"
        PropertyName="bViewSmoothing"
        OnChange=UserOnChange
    End Object

    bDoubleColumn=false
    Sections(0)=ServerSection
    Sections(1)=UserSection
    ServerOptions(0)=AllowNewNetWeapons
    ServerOptions(1)=AllowNewEyeHeightAlgorithm
    ServerOptions(2)=DisableDoubleDamage
    ServerOptions(3)=ColoredDeathMessages
    ServerOptions(4)=TimedOvertime
    ServerOptions(5)=PingTweenTime
    ServerOptions(6)=PawnCollisionHistoryLength
    UserOptions(0)=EnhancedNetCode
    UserOptions(1)=NewEyeHeightAlgorithm
    UserOptions(2)=ViewSmoothing
}
