/*
UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Jo�l Moffatt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
class NewNet_Client extends HxClientReplicationInfo
    config(User);

var config bool bEnhancedNetCode;

var bool bAllowEnhancedNetcode;
var bool bAllowNewEyeHeightAlgorithm;
var int TimedOvertime;
var float PingTweenTime;
var float PawnCollisionHistoryLength;

var float PredictedPing;

var private NewNet_Client LocalClient;
var private float PingSendTime;
var private bool bPingReceived;
var private int numPings;
var private bool bInitializeClient;

replication
{
    reliable if (Role == ROLE_Authority)
        bAllowEnhancedNetcode,
        bAllowNewEyeHeightAlgorithm,
        TimedOvertime,
        PingTweenTime,
        PawnCollisionHistoryLength;

    reliable if (Role == ROLE_Authority)
        Pong, ClientResetNetcode;

    reliable if (Role < ROLE_Authority)
        Ping, TurnOffNetCode;
}

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();
    if (Level.NetMode != NM_DedicatedServer)
    {
        class'UTComp_HxMenuPanel'.static.AddToMenu();
        bInitializeClient = true;
    }
}

simulated function Ping()
{
    Pong();
}

simulated function Pong()
{
    bPingReceived = True;
    PredictedPing = (2.0 * PredictedPing + (Level.TimeSeconds - PingSendTime)) / PingTweenTime;
    Default.PredictedPing = PredictedPing;
    numPings++;
    if(NumPings < 8)
    {
        Default.PredictedPing = (Level.TimeSeconds - PingSendTime);
    }
}

simulated function Tick(float DeltaTime)
{
    if (bInitializeClient)
    {
        InitializeClient();
    }
    if (Level.NetMode == NM_Client)
    {
        if (bPingReceived && Level.TimeSeconds > PingSendTime + PingTweenTime)
        {
            PingSendTime = Level.TimeSeconds;
            bPingReceived = False;
            Ping();
        }
    }
}

simulated function InitializeClient()
{
    local PlayerController PC;
    local NewNet_Client Client;

    PC = Level.GetLocalPlayerController();
    if (PC != None && (default.LocalClient == None || default.LocalClient.Owner != PC))
    {
        ForEach Level.DynamicActors(class'NewNet_Client', Client)
        {
            if (Client.Owner == PC)
            {
                default.LocalClient = Client;
                bInitializeClient = false;
                break;
            }
        }
    }
}

simulated function ClientResetNetcode()
{
    local PlayerController PC;
    local Timestamp_Pawn P;

    PC = Level.GetLocalPlayerController();
    ForEach PC.DynamicActors(class'Timestamp_Pawn', P)
    {
        P.Destroy();
    }
}

function UpdateAll()
{
    local MutUTComp UTComp;

    UTComp = MutUTComp(MutatorOwner);
    bAllowEnhancedNetcode = UTComp.bAllowEnhancedNetcode;
    bAllowNewEyeHeightAlgorithm = UTComp.bAllowNewEyeHeightAlgorithm;
    TimedOvertime = UTComp.TimedOvertime;
    PingTweenTime = UTComp.PingTweenTime;
    PawnCollisionHistoryLength = UTComp.PawnCollisionHistoryLength;
    NetUpdateTime = Level.TimeSeconds - 1;
}

function UpdateProperty(string PropertyName, String PropertyValue)
{
    UpdateAll();
}

function TurnOffNetCode()
{
    local PlayerController PC;
    local inventory Inv;

    PC = PlayerController(Owner);
    if (PC.Pawn != None)
    {
        for (Inv = PC.Pawn.Inventory; Inv != None; Inv = Inv.inventory)
        {
            if (Weapon(Inv) == None)
            {
                continue;
            }
            if (NewNet_AssaultRifle(Inv) != None)
            {
                NewNet_AssaultRifle(Inv).DisableNet();
            }
            else if (NewNet_BioRifle(Inv) != None)
            {
                NewNet_BioRifle(Inv).DisableNet();
            }
            else if (NewNet_ShockRifle(Inv) != None)
            {
                NewNet_ShockRifle(Inv).DisableNet();
            }
            else if (NewNet_MiniGun(Inv) != None)
            {
                NewNet_MiniGun(Inv).DisableNet();
            }
            else if (NewNet_LinkGun(Inv) != None)
            {
                NewNet_LinkGun(Inv).DisableNet();
            }
            else if (NewNet_RocketLauncher(Inv) != None)
            {
                NewNet_RocketLauncher(Inv).DisableNet();
            }
            else if (NewNet_FlakCannon(Inv) != None)
            {
                NewNet_FlakCannon(Inv).DisableNet();
            }
            else if (NewNet_SniperRifle(Inv) != None)
            {
                NewNet_SniperRifle(Inv).DisableNet();
            }
            else if (NewNet_ClassicSniperRifle(Inv) != None)
            {
                NewNet_ClassicSniperRifle(Inv).DisableNet();
            }
        }
    }
}

static function SetEnhancedNetCode(coerce bool bEnable)
{
    if (!bEnable && default.LocalClient != None)
    {
        default.LocalClient.TurnOffNetCode();
    }
    default.bEnhancedNetCode = bEnable;
    StaticSaveConfig();
}

static function NewNet_Client GetClient()
{
    return default.LocalClient;
}

static function bool IsEnhancedNetcodeEnabled()
{
    return default.bEnhancedNetCode
        && default.LocalClient != None
        && default.LocalClient.bAllowEnhancedNetcode;
}

defaultproperties
{
    NetUpdateFrequency=10
    NetPriority=5
    PingTweenTime=3.0
    bPingReceived=True
    bEnhancedNetCode=True
}
