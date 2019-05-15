#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Spam Crouch Fix", 
	author = "Extacy", 
	description = "Fixes the cooldown/slow crouch when you spammed crouch", 
	version = "1.0", 
	url = "https://steamcommunity.com/profiles/76561198183032322"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	float CrouchSpeed = GetEntPropFloat(client, Prop_Data, "m_flDuckSpeed");
		
	if (CrouchSpeed < 7.0)
		SetEntPropFloat(client, Prop_Data, "m_flDuckSpeed", 7.0);
		
	return Plugin_Continue;
}
