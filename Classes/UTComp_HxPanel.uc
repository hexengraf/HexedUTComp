class UTComp_HxPanel extends HxPanel;

const SECTION_GE = 0;
const SECTION_NW = 2;
const SECTION_EA = 3;

var automated moCheckBox ch_bDisableDoubleDamage;
var automated moCheckBox ch_bColoredDeathMessages;
var automated moNumericEdit nu_NumGrenadesOnSpawn;
var automated moNumericEdit nu_StartingHealth;
var automated moNumericEdit nu_StartingArmor;
var automated moNumericEdit nu_TimedOvertime;

var automated moCheckBox ch_bAllowNewNetWeapons;
var automated moFloatEdit nu_PingTweenTime;
var automated moFloatEdit nu_PawnCollisionHistoryLength;
var automated moCheckBox ch_bEnhancedNetCode;

var automated moCheckBox ch_bAllowNewEyeHeightAlgorithm;
var automated moCheckBox ch_bNewEyeHeightAlgorithm;
var automated moCheckBox ch_bViewSmoothing;

var automated GUILabel l_Asterisk;

var NewNet_PRI PRI;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController,MyOwner);

    Sections[SECTION_GE].ManageComponent(ch_bDisableDoubleDamage);
    Sections[SECTION_GE].ManageComponent(ch_bColoredDeathMessages);
    Sections[SECTION_GE].ManageComponent(nu_NumGrenadesOnSpawn);
    Sections[SECTION_GE].ManageComponent(nu_StartingHealth);
    Sections[SECTION_GE].ManageComponent(nu_StartingArmor);
    Sections[SECTION_GE].ManageComponent(nu_TimedOvertime);

    Sections[SECTION_NW].ManageComponent(ch_bAllowNewNetWeapons);
    Sections[SECTION_NW].ManageComponent(nu_PingTweenTime);
    Sections[SECTION_NW].ManageComponent(nu_PawnCollisionHistoryLength);
    Sections[SECTION_NW].ManageComponent(ch_bEnhancedNetCode);

    Sections[SECTION_EA].ManageComponent(ch_bAllowNewEyeHeightAlgorithm);
    Sections[SECTION_EA].ManageComponent(ch_bNewEyeHeightAlgorithm);
    Sections[SECTION_EA].ManageComponent(ch_bViewSmoothing);
    SetVisibility(true);
}

function ShowPanel(bool bShow)
{
    Super.ShowPanel(bShow);

    if (bShow)
    {
        if (!Initialize())
        {
            HideAllSections(true, HIDE_DUE_INIT);
            SetTimer(0.1, true);
        }
        else
        {
            UpdateAll();
        }
    }
}

event Timer()
{
    if (Initialize() && IsSynchronized())
    {
        KillTimer();
        UpdateAll();
    }
}

function UpdateAll()
{
    local bool bAdmin;

    bAdmin = IsAdmin();
    if (bAdmin)
    {
        EnableComponent(ch_bDisableDoubleDamage);
        EnableComponent(ch_bColoredDeathMessages);
        EnableComponent(nu_NumGrenadesOnSpawn);
        EnableComponent(nu_StartingHealth);
        EnableComponent(nu_StartingArmor);
        EnableComponent(nu_TimedOvertime);
        EnableComponent(ch_bAllowNewNetWeapons);
        if (PRI.bAllowNewNetWeapons)
        {
            EnableComponent(nu_PingTweenTime);
            EnableComponent(nu_PawnCollisionHistoryLength);
        }
        else
        {
            DisableComponent(nu_PingTweenTime);
            DisableComponent(nu_PawnCollisionHistoryLength);
        }
        EnableComponent(ch_bAllowNewEyeHeightAlgorithm);
    }
    else
    {
        DisableComponent(ch_bDisableDoubleDamage);
        DisableComponent(ch_bColoredDeathMessages);
        DisableComponent(nu_NumGrenadesOnSpawn);
        DisableComponent(nu_StartingHealth);
        DisableComponent(nu_StartingArmor);
        DisableComponent(nu_TimedOvertime);
        DisableComponent(ch_bAllowNewNetWeapons);
        DisableComponent(nu_PingTweenTime);
        DisableComponent(nu_PawnCollisionHistoryLength);
        DisableComponent(ch_bAllowNewEyeHeightAlgorithm);
    }
    if (PRI.bAllowNewNetWeapons)
    {
        EnableComponent(ch_bEnhancedNetCode);
    }
    else
    {
        DisableComponent(ch_bEnhancedNetCode);
    }
    UpdateNewEyeHeightAlgorithm();
    HideSection(SECTION_GE, false);
    HideSection(SECTION_NW, !bAdmin && !PRI.bAllowNewNetWeapons, HIDE_DUE_DISABLE);
    HideSection(SECTION_EA, !bAdmin && !PRI.bAllowNewEyeHeightAlgorithm, HIDE_DUE_DISABLE);
}

function UpdateNewEyeHeightAlgorithm()
{
    if (PRI.bAllowNewEyeHeightAlgorithm)
    {
        EnableComponent(ch_bNewEyeHeightAlgorithm);
        if (class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm)
        {
            EnableComponent(ch_bViewSmoothing);
        }
        else
        {
            DisableComponent(ch_bViewSmoothing);
        }
    }
    else
    {
        DisableComponent(ch_bNewEyeHeightAlgorithm);
        DisableComponent(ch_bViewSmoothing);
    }
}

function InternalOnChange(GUIComponent C)
{
    local UTComp_xPawn Pawn;

    Pawn = UTComp_xPawn(PlayerOwner().Pawn);
    switch (C)
    {
        case ch_bDisableDoubleDamage:
            if (IsAdmin())
            {
                PRI.ServerSetDisableDoubleDamage(ch_bDisableDoubleDamage.IsChecked());
                SetTimer(0.1, true);
            }
            break;
        case ch_bColoredDeathMessages:
            if (IsAdmin())
            {
                PRI.ServerSetColoredDeathMessages(ch_bColoredDeathMessages.IsChecked());
                SetTimer(0.1, true);
            }
            break;
        case nu_NumGrenadesOnSpawn:
            if (IsAdmin())
            {
                PRI.ServerSetNumGrenadesOnSpawn(nu_NumGrenadesOnSpawn.GetValue());
                SetTimer(0.1, true);
            }
            break;
        case nu_StartingHealth:
            if (IsAdmin())
            {
                PRI.ServerSetStartingHealth(nu_StartingHealth.GetValue());
                SetTimer(0.1, true);
            }
            break;
        case nu_StartingArmor:
            if (IsAdmin())
            {
                PRI.ServerSetStartingArmor(nu_StartingArmor.GetValue());
                SetTimer(0.1, true);
            }
            break;
        case nu_TimedOvertime:
            if (IsAdmin())
            {
                PRI.ServerSetTimedOvertime(nu_TimedOvertime.GetValue());
                SetTimer(0.1, true);
            }
            break;
        case ch_bAllowNewNetWeapons:
            if (IsAdmin())
            {
                PRI.ServerSetAllowNewNetWeapons(ch_bAllowNewNetWeapons.IsChecked());
                SetTimer(0.1, true);
            }
            break;
        case nu_PingTweenTime:
            if (IsAdmin())
            {
                PRI.ServerSetPingTweenTime(nu_PingTweenTime.GetValue());
                SetTimer(0.1, true);
            }
            break;
        case nu_PawnCollisionHistoryLength:
            if (IsAdmin())
            {
                PRI.ServerSetPawnCollisionHistoryLength(nu_PawnCollisionHistoryLength.GetValue());
                SetTimer(0.1, true);
            }
            break;
        case ch_bEnhancedNetCode:
            if (Pawn != None)
            {
                Pawn.SetEnhancedNetCode(ch_bEnhancedNetCode.IsChecked());
            }
            else
            {
                class'UTComp_xPawn'.Default.bEnhancedNetCode = ch_bEnhancedNetCode.IsChecked();
            }
            break;
        case ch_bAllowNewEyeHeightAlgorithm:
            if (IsAdmin())
            {
                PRI.ServerSetAllowNewEyeHeightAlgorithm(ch_bAllowNewEyeHeightAlgorithm.IsChecked());
                SetTimer(0.1, true);
            }
            break;
        case ch_bNewEyeHeightAlgorithm:
            class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm = ch_bNewEyeHeightAlgorithm.IsChecked();
            if (Pawn != None)
            {
                Pawn.bNewEyeHeightAlgorithm = class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm;
            }
            UpdateNewEyeHeightAlgorithm();
            break;
        case ch_bViewSmoothing:
            class'UTComp_xPawn'.Default.bViewSmoothing =  ch_bViewSmoothing.IsChecked();
            if (Pawn != None)
            {
                Pawn.bViewSmoothing = class'UTComp_xPawn'.Default.bViewSmoothing;
            }
            break;
    }
    class'UTComp_xPawn'.static.StaticSaveConfig();
}

function bool Initialize()
{
    if (PRI != None)
    {
        return true;
    }
    PRI = class'NewNet_PRI'.static.GetPRI(PlayerOwner());
    if (PRI != None)
    {
        ch_bDisableDoubleDamage.Checked(PRI.bDisableDoubleDamage);
        ch_bColoredDeathMessages.Checked(PRI.bColoredDeathMessages);
        nu_NumGrenadesOnSpawn.SetComponentValue(PRI.NumGrenadesOnSpawn);
        nu_StartingHealth.SetComponentValue(PRI.StartingHealth);
        nu_StartingArmor.SetComponentValue(PRI.StartingArmor);
        nu_TimedOvertime.SetComponentValue(PRI.TimedOvertime);
        ch_bAllowNewNetWeapons.Checked(PRI.bAllowNewNetWeapons);
        nu_PingTweenTime.SetComponentValue(PRI.PingTweenTime);
        nu_PawnCollisionHistoryLength.SetComponentValue(PRI.PawnCollisionHistoryLength);
        ch_bEnhancedNetCode.Checked(class'UTComp_xPawn'.Default.bEnhancedNetCode);
        ch_bAllowNewEyeHeightAlgorithm.Checked(PRI.bAllowNewEyeHeightAlgorithm);
        ch_bNewEyeHeightAlgorithm.Checked(class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm);
        ch_bViewSmoothing.Checked(class'UTComp_xPawn'.Default.bViewSmoothing);
        return true;
    }
    return false;
}

function bool IsSynchronized()
{
    return PRI.bDisableDoubleDamage == ch_bDisableDoubleDamage.IsChecked()
        && PRI.bColoredDeathMessages == ch_bColoredDeathMessages.IsChecked()
        && PRI.NumGrenadesOnSpawn == nu_NumGrenadesOnSpawn.GetValue()
        && PRI.StartingHealth == nu_StartingHealth.GetValue()
        && PRI.StartingArmor == nu_StartingArmor.GetValue()
        && PRI.TimedOvertime == nu_TimedOvertime.GetValue()
        && PRI.bAllowNewNetWeapons == ch_bAllowNewNetWeapons.IsChecked()
        && PRI.PingTweenTime == nu_PingTweenTime.GetValue()
        && PRI.PawnCollisionHistoryLength == nu_PawnCollisionHistoryLength.GetValue()
        && PRI.bAllowNewEyeHeightAlgorithm == ch_bAllowNewEyeHeightAlgorithm.IsChecked();
}

static function AddToMenu()
{
    class'HxMenu'.static.AddPanel(Default.Class, "UTComp", "UTComp Features");
}

defaultproperties
{
    bDoubleColumn=true

    Begin Object class=AltSectionBackground Name=General
        Caption="General"
        WinHeight=0.32
        NumColumns=2
    End Object
    Sections(0)=General
    Sections(1)=None

    Begin Object class=AltSectionBackground Name=NewNetWeaponsSection
        Caption="NewNet Weapons"
        WinHeight=0.42
    End Object
    Sections(2)=NewNetWeaponsSection

    Begin Object class=AltSectionBackground Name=EyeHeightSection
        Caption="EyeHeight Algorithm"
        WinHeight=0.42
    End Object
    Sections(3)=EyeHeightSection

    Begin Object Class=moCheckBox Name=DisableDoubleDamage
        Caption="Disable double damage"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=0
        OnChange=InternalOnChange
    End Object
    ch_bDisableDoubleDamage=DisableDoubleDamage

    Begin Object Class=moCheckBox Name=ColoredDeathMessages
        Caption="Colored death messages(*)"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=1
        OnChange=InternalOnChange
    End Object
    ch_bColoredDeathMessages=ColoredDeathMessages

    Begin Object class=moNumericEdit Name=NumGrenadesOnSpawn
        Caption="Grenades on spawn"
        MinValue=0
        MaxValue=10
        LabelJustification=TXTA_Left
        ComponentJustification=TXTA_Right
        ComponentWidth=0.25
        bAutoSizeCaption=true
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=2
        OnChange=InternalOnChange
    End Object
    nu_NumGrenadesOnSpawn=NumGrenadesOnSpawn

    Begin Object class=moNumericEdit Name=StartingHealth
        Caption="Starting health"
        MinValue=1
        MaxValue=199
        LabelJustification=TXTA_Left
        ComponentJustification=TXTA_Right
        ComponentWidth=0.25
        bAutoSizeCaption=true
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=3
        OnChange=InternalOnChange
    End Object
    nu_StartingHealth=StartingHealth

    Begin Object class=moNumericEdit Name=StartingArmor
        Caption="Starting armor"
        MinValue=0
        MaxValue=150
        LabelJustification=TXTA_Left
        ComponentJustification=TXTA_Right
        ComponentWidth=0.25
        bAutoSizeCaption=true
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=4
        OnChange=InternalOnChange
    End Object
    nu_StartingArmor=StartingArmor

    Begin Object class=moNumericEdit Name=TimedOvertime
        Caption="Timed overtime"
        MinValue=0
        MaxValue=3600
        LabelJustification=TXTA_Left
        ComponentJustification=TXTA_Right
        ComponentWidth=0.25
        bAutoSizeCaption=true
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=5
        OnChange=InternalOnChange
    End Object
    nu_TimedOvertime=TimedOvertime

    Begin Object Class=moCheckBox Name=AllowNewNetWeapons
        Caption="Allow Enhanced Netcode(*)"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=6
        OnChange=InternalOnChange
    End Object
    ch_bAllowNewNetWeapons=AllowNewNetWeapons

    Begin Object class=moFloatEdit Name=PingTweenTime
        Caption="Ping Tween Time"
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        LabelJustification=TXTA_Left
        ComponentJustification=TXTA_Right
        ComponentWidth=0.25
        bAutoSizeCaption=true
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=7
        OnChange=InternalOnChange
    End Object
    nu_PingTweenTime=PingTweenTime

    Begin Object class=moFloatEdit Name=PawnCollisionHistoryLength
        Caption="Collision History Length(*)"
        MinValue=0.0
        MaxValue=10.0
        Step=0.1
        LabelJustification=TXTA_Left
        ComponentJustification=TXTA_Right
        ComponentWidth=0.25
        bAutoSizeCaption=true
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=7
        OnChange=InternalOnChange
    End Object
    nu_PawnCollisionHistoryLength=PawnCollisionHistoryLength

    Begin Object Class=moCheckBox Name=EnhancedNetCode
        Caption="Enable Enhanced Netcode"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=8
        OnChange=InternalOnChange
    End Object
    ch_bEnhancedNetCode=EnhancedNetCode

    Begin Object Class=moCheckBox Name=AllowNewEyeHeightAlgorithm
        Caption="Allow New EyeHeight Algorithm(*)"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=9
        OnChange=InternalOnChange
    End Object
    ch_bAllowNewEyeHeightAlgorithm=AllowNewEyeHeightAlgorithm

    Begin Object Class=moCheckBox Name=NewEyeHeightAlgorithm
        Caption="Enable New EyeHeight Algorithm"
        Hint="You want this"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=10
        OnChange=InternalOnChange
    End Object
    ch_bNewEyeHeightAlgorithm=NewEyeHeightAlgorithm

    Begin Object Class=moCheckBox Name=ViewSmoothing
        Caption="View smoothing"
        Hint="Smooth the view when using new EyeHeight algorithm"
        bBoundToParent=true
        bScaleToParent=true
        TabOrder=11
        OnChange=InternalOnChange
    End Object
    ch_bViewSmoothing=ViewSmoothing

    Begin Object Class=GUILabel Name=Asterisk
        Caption="(*) Requires restart or map change to take effect"
        WinTop=0.75
        WinLeft=0.00002
        TextColor=(R=255,G=255,B=255,A=255)
        bBoundToParent=true
        bScaleToParent=true
    End Object
    l_Asterisk=Asterisk
}
