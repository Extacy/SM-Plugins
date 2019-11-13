#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define	CS_TEAM_T	2
#define	CS_TEAM_CT	3

bool g_bInCombat[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "No Weapon Drop On Slay", 
	author = "Extacy", 
	description = "Deletes weapons from a CT if they suicide. Does not drop if they were in recent combat", 
	version = "1.0", 
	url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
	RegConsoleCmd("kill", BlockKill);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	g_bInCombat[client] = false;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	int attackerClient = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!client || !IsClientInGame(client) || !attackerClient || !IsClientInGame(attackerClient))
		return Plugin_Continue;
	
	if (GetClientTeam(client) == CS_TEAM_CT && GetClientTeam(attackerClient) == CS_TEAM_T)
	{
		g_bInCombat[client] = true;
		CreateTimer(5.0, Timer_HurtDelay, userid);
	}
	
	return Plugin_Continue;
}

public Action Timer_HurtDelay(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (client && IsClientInGame(client))
		g_bInCombat[client] = false;

	return Plugin_Stop;
}

public Action BlockKill(int client, int args)
{
	if (!g_bInCombat[client] && GetClientTeam(client) == CS_TEAM_CT)
		RemoveWeapon(client);
	
	return Plugin_Continue;
}

public void RemoveWeapon(int client)
{
	int weapon;
	
	for (int i = 0; i <= 1; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
		}
	}
}
