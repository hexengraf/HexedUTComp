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

var MutUTComp UTComp;
var private PlayerController PC;

var float PredictedPing;
var float PingSendTime;
var bool bPingReceived;
var int numPings;

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
        Ping, RemoteSetProperty, TurnOffNetCode;
}

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();
    if (Level.NetMode != NM_DedicatedServer)
    {
        class'UTComp_HxMenuPanel'.static.AddToMenu();
    }
    PC = PlayerController(Owner);
}

function RemoteSetProperty(string PropertyName, string PropertyValue)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        UTComp.SetProperty(PropertyName, PropertyValue);
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
    if (Level.NetMode != NM_Client)
    {
        return;
    }
    if (bPingReceived && Level.TimeSeconds > PingSendTime + PingTweenTime)
    {
        PingSendTime = Level.TimeSeconds;
        bPingReceived = False;
        Ping();
    }
}

simulated function ClientResetNetcode()
{
    local Timestamp_Pawn P;

    ForEach PC.DynamicActors(class'Timestamp_Pawn', P)
    {
        P.Destroy();
    }
}

function Update()
{
    bAllowEnhancedNetcode = UTComp.bAllowEnhancedNetcode;
    bAllowNewEyeHeightAlgorithm = UTComp.bAllowNewEyeHeightAlgorithm;
    TimedOvertime = UTComp.TimedOvertime;
    PingTweenTime = UTComp.PingTweenTime;
    PawnCollisionHistoryLength = UTComp.PawnCollisionHistoryLength;
    NetUpdateTime = Level.TimeSeconds - 1;
}

function TurnOffNetCode()
{
    local inventory Inv;

    if (PC.Pawn != None)
    {
        for (Inv = PC.Pawn.Inventory; Inv != None; Inv = Inv.inventory)
        {
            if (Weapon(Inv) != None)
            {
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
}

static function SetEnhancedNetCode(bool bEnable)
{
    if (!bEnable && default.CRIs.Length > 0)
    {
        NewNet_Client(default.CRIs[0]).TurnOffNetCode();
    }
    default.bEnhancedNetCode = bEnable;
    StaticSaveConfig();
}

static function NewNet_Client SpawnPRI(PlayerController PC, MutUTComp UTComp)
{
    local NewNet_Client Client;

    Client = NewNet_Client(SpawnClientReplicationInfo(PC));
    if (Client != None)
    {
        Client.UTComp = UTComp;
        Client.Update();
    }
    return Client;
}

static function bool DestroyPRI(PlayerController PC)
{
    return DestroyClientReplicationInfo(PC);
}

static function NewNet_Client GetPRI(PlayerController PC)
{
    return NewNet_Client(GetClientReplicationInfo(PC));
}

static function bool IsEnhancedNetcodeEnabled()
{
    return default.bEnhancedNetCode
        && default.CRIs.Length > 0
        && NewNet_Client(default.CRIs[0]).bAllowEnhancedNetcode;
}

defaultproperties
{
    NetUpdateFrequency=10
    NetPriority=5
    PingTweenTime=3.0
    bPingReceived=True
    bEnhancedNetCode=True
}
