/*
VIDEO DEMO: https://youtu.be/LSHq2s76vnI

For use with https://github.com/Franc1sco/DevZones/tree/master/DevZones%20(CORE%20PLUGIN)
Create a zone and prefix it with blockarea-
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <devzones>

#pragma newdecls required

#define ZONE_PREFIX "blockarea"

public Plugin myinfo = 
{
	name = "Block Area", 
	author = "Extacy", 
	description = "Block areas of maps using devzones", 
	version = "1.0", 
	url = "https://steamcommunity.com/profiles/76561198183032322"
};

public int Zone_OnClientEntry(int client, char[] zone)
{
	if (!IsValidClient(client))
		return 0;
	
	if (StrContains(zone, ZONE_PREFIX, false) == 0)
	{
		PrintHintText(client, "<font color='#ff3030'>You may not enter here!</font>");
		
		// https://forums.alliedmods.net/showthread.php?t=230885
		float clientPos[3], zonePos[3], velocity[3];
		GetClientAbsOrigin(client, clientPos);
		Zone_GetZonePosition(zone, false, zonePos);
		
		MakeVectorFromPoints(zonePos, clientPos, velocity);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 250.0);
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}
	
	return 1;
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	if (IsFakeClient(client))return false;
	if (IsClientSourceTV(client))return false;
	return IsClientInGame(client);
} 