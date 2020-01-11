#include <sourcemod>
#include <sdktools>
#include <redie_beta>

#pragma semicolon 1
#pragma newdecls required

bool g_bQueueSlay[MAXPLAYERS + 1] = { false, ... };

public Plugin myinfo = 
{
	name = "lslay", 
	author = "Extacy", 
	description = "Mark a player to be slayed next round.", 
	version = "1.0", 
	url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	RegAdminCmd("sm_lslay", CMD_LSlay, ADMFLAG_SLAY);
}

public Action CMD_LSlay(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "  Usage: \x0Fsm_lslay <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	int target = FindTarget(client, arg);
	if (target != -1)
	{
		g_bQueueSlay[target] = !g_bQueueSlay[target];

		if (g_bQueueSlay[target])
			PrintToChatAll(" \x0C➤➤➤\x0B \x0F%N \x0Bhas marked \x0F%N \x0Bto be slayed next round!", client, target);
		else
			PrintToChatAll(" \x0C➤➤➤\x0B \x0F%N \x0Bhas unmarked \x0F%N \x0Bto be slayed next round!", client, target);
	}

	return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (g_bQueueSlay[client] && !Redie_IsGhost(client))
	{
		ForcePlayerSuicide(client);
		PrintToChat(client, " \x0C➤➤➤\x0B You were slain by an admin!");
		g_bQueueSlay[client] = false;
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	if (IsClientSourceTV(client)) return false;
	return IsClientInGame(client);
}