class UTComp_HxGUIPanel extends HxGUIPanel;

const SECTION_NW = 0;
const SECTION_EA = 1;

var automated moCheckBox ch_bEnhancedNetCode;
var automated moCheckBox ch_bNewEyeHeightAlgorithm;
var automated moCheckBox ch_bViewSmoothing;

var MutUTComp Mutator;
var class<Pawn> PawnClass;
var int Index;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController,MyOwner);

    Sections[SECTION_NW].ManageComponent(ch_bEnhancedNetCode);
    Sections[SECTION_EA].ManageComponent(ch_bNewEyeHeightAlgorithm);
    Sections[SECTION_EA].ManageComponent(ch_bViewSmoothing);

    ch_bEnhancedNetCode.Checked(class'UTComp_xPawn'.Default.bEnhancedNetCode);
    ch_bNewEyeHeightAlgorithm.Checked(class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm);
    ch_bViewSmoothing.Checked(class'UTComp_xPawn'.Default.bViewSmoothing);
}

function ShowPanel(bool bShow)
{
    Super.ShowPanel(bShow);
    if (bShow)
    {
        UpdateAvailableOptions();
    }
}

function UpdateAvailableOptions()
{
    if (!Initialize())
    {
        HideAllSections(True, HIDE_DUE_INIT);
    }
    else
    {
        HideSection(SECTION_NW, !Mutator.bAllowNewNetWeapons, HIDE_DUE_DISABLE);
        HideSection(SECTION_EA, !Mutator.bAllowNewEyeHeightAlgorithm, HIDE_DUE_DISABLE);
    }
}

function InternalOnChange(GUIComponent C)
{
    local UTComp_xPawn Pawn;

    Pawn = UTComp_xPawn(PlayerOwner().Pawn);
    switch (C)
    {
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
        case ch_bNewEyeHeightAlgorithm:
            class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm = ch_bNewEyeHeightAlgorithm.IsChecked();
            if (Pawn != None)
            {
                Pawn.bNewEyeHeightAlgorithm = class'UTComp_xPawn'.Default.bNewEyeHeightAlgorithm;
            }
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
    if (Mutator == None)
    {
        ForEach PlayerOwner().DynamicActors(class'MutUTComp', Mutator) break;
    }
    return Mutator != None;
}

static function AddToMenu()
{
    class'HxGUIMenu'.static.AddPanel(Default.Class, "UTComp", "UTComp Features");
}

defaultproperties
{
    Begin Object class=AltSectionBackground Name=NewNetWeaponsSection
        Caption="NewNet Weapons"
        WinHeight=0.15
    End Object
    Sections(0)=NewNetWeaponsSection

    Begin Object class=AltSectionBackground Name=EyeHeightSection
        Caption="EyeHeight Algorithm"
        WinHeight=0.15
    End Object
    Sections(1)=EyeHeightSection

    Begin Object Class=moCheckBox Name=UseEnhancedNetCode
        Caption="Enable Enhanced Netcode"
        bBoundToParent=True
        bScaleToParent=True
        TabOrder=4
        OnChange=InternalOnChange
    End Object
    ch_bEnhancedNetCode=UseEnhancedNetCode

    Begin Object Class=moCheckBox Name=NewEyeHeightAlgorithm
        Caption="New EyeHeight Algorithm"
        Hint="You want this"
        bBoundToParent=True
        bScaleToParent=True
        TabOrder=5
        OnChange=InternalOnChange
    End Object
    ch_bNewEyeHeightAlgorithm=NewEyeHeightAlgorithm

    Begin Object Class=moCheckBox Name=ViewSmoothing
        Caption="View smoothing"
        Hint="Smooth the view when using new EyeHeight algorithm"
        bBoundToParent=True
        bScaleToParent=True
        TabOrder=6
        OnChange=InternalOnChange
    End Object
    ch_bViewSmoothing=ViewSmoothing

    Index=0
}
