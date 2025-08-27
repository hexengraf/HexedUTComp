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
class NewNet_PRI extends LinkedReplicationInfo;

var bool bAllowNewNetWeapons;
var bool bAllowNewEyeHeightAlgorithm;
var bool bDisableDoubleDamage;
var bool bColoredDeathMessages;
var int NumGrenadesOnSpawn;
var int StartingHealth;
var int StartingArmor;
var int TimedOvertime;
var float PingTweenTime;
var float PawnCollisionHistoryLength;
var MutUTComp UTComp;
var PlayerController PC;

var float PredictedPing;
var float PingSendTime;
var bool bPingReceived;
var int numPings;

replication
{
    reliable if (Role < ROLE_Authority)
        Ping;

    reliable if (Role == ROLE_Authority && bNetOwner)
        Pong;

    reliable if (Role == ROLE_Authority)
        bAllowNewNetWeapons, bAllowNewEyeHeightAlgorithm, bDisableDoubleDamage,
        bColoredDeathMessages, NumGrenadesOnSpawn, StartingHealth, StartingArmor,
        TimedOvertime, PingTweenTime, PawnCollisionHistoryLength;

    reliable if (Role < ROLE_Authority)
        ServerSetAllowNewNetWeapons, ServerSetAllowNewEyeHeightAlgorithm,
        ServerSetDisableDoubleDamage, ServerSetColoredDeathMessages, ServerSetNumGrenadesOnSpawn,
        ServerSetStartingHealth, ServerSetStartingArmor, ServerSetTimedOvertime,
        ServerSetPingTweenTime, ServerSetPawnCollisionHistoryLength;
}

function ServerSetAllowNewNetWeapons(bool bValue)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        bAllowNewNetWeapons = bValue;
        class'MutUTComp'.default.bAllowNewNetWeapons = bValue;
        class'MutUTComp'.static.StaticSaveConfig();
    }
}

function ServerSetAllowNewEyeHeightAlgorithm(bool bValue)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        bAllowNewEyeHeightAlgorithm = bValue;
        class'MutUTComp'.default.bAllowNewEyeHeightAlgorithm = bValue;
        class'MutUTComp'.static.StaticSaveConfig();
    }
}

function ServerSetDisableDoubleDamage(bool bValue)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        bDisableDoubleDamage = bValue;
        UTComp.bDisableDoubleDamage = bValue;
        UTComp.SaveConfig();
    }
}

function ServerSetColoredDeathMessages(bool bValue)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        bColoredDeathMessages = bValue;
        class'MutUTComp'.default.bColoredDeathMessages = bValue;
        class'MutUTComp'.static.StaticSaveConfig();
    }
}

function ServerSetNumGrenadesOnSpawn(int Value)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        NumGrenadesOnSpawn = Value;
        UTComp.NumGrenadesOnSpawn = Value;
        UTComp.SaveConfig();
    }
}

function ServerSetStartingHealth(int Value)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        StartingHealth = Value;
        UTComp.StartingHealth = Value;
        UTComp.SaveConfig();
    }
}

function ServerSetStartingArmor(int Value)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        StartingArmor = Value;
        UTComp.StartingArmor = Value;
        UTComp.SaveConfig();
    }
}

function ServerSetTimedOvertime(int Value)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        TimedOvertime = Value;
        UTComp.TimedOvertime = Value;
        UTComp.SaveConfig();
    }
}

function ServerSetPingTweenTime(float Value)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        PingTweenTime = Value;
        UTComp.PingTweenTime = Value;
        UTComp.SaveConfig();
    }
}

function ServerSetPawnCollisionHistoryLength(float Value)
{
    if (PC.PlayerReplicationInfo.bAdmin)
    {
        PawnCollisionHistoryLength = Value;
        class'MutUTComp'.default.PawnCollisionHistoryLength = Value;
        class'MutUTComp'.static.StaticSaveConfig();
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

static simulated function NewNet_PRI GetPRI(Controller C)
{
    local LinkedReplicationInfo LinkedPRI;

    if (C.PlayerReplicationInfo != None)
    {
        LinkedPRI = C.PlayerReplicationInfo.CustomReplicationInfo;
        while (LinkedPRI != None && NewNet_PRI(LinkedPRI) == None)
        {
            LinkedPRI = LinkedPRI.NextReplicationInfo;
        }
    }
    return NewNet_PRI(LinkedPRI);
}

defaultproperties
{
    NetUpdateFrequency=10
    NetPriority=5
    PingTweenTime=3.0
    bPingReceived=True
}
