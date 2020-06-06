#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

Database g_Database;

ConVar g_RewardAmount;
ConVar g_RewardCooldown;
ConVar g_Streak;
ConVar g_StreakAmount;

bool g_bRedeemingReward[MAXPLAYERS + 1] = { false, ... }; // Disable redeeming rewards while the plugin is querying the DB. (Fixes exploiting)

#include "dailyrewards/sql.sp"
#include "dailyrewards/stocks.sp"

public Plugin myinfo = 
{
	name = "Daily Rewards", 
	author = "Extacy", 
	description = "Gift store credits to reward daily logins", 
	version = "1.0", 
	url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_dailyreward", CMD_DailyReward);
	RegConsoleCmd("sm_daily", CMD_DailyReward);
	RegConsoleCmd("sm_reward", CMD_DailyReward);

	AutoExecConfig(true, "dailyrewards");
	g_RewardAmount = CreateConVar("sm_dailyrewards_amount", "200", "Amount of credits to be gifted when reward redeemed");
	g_RewardCooldown = CreateConVar("sm_dailyrewards_cooldown", "86400", "Cooldown in seconds");
	g_Streak = CreateConVar("sm_dailyrewards_streak", "5", "Days in a row to earn a bonus amount of credits");
	g_StreakAmount = CreateConVar("sm_dailyrewards_streak_amount", "500", "Amount of bonus credits to be gifted");

	g_Database = null;
	Database.Connect(SQL_OnDBConnected, "dailyrewards");
}

public void OnClientPostAdminCheck(int client)
{
	g_bRedeemingReward[client] = false;
	// CreateTimer(5.0, Timer_RedeemReward, GetClientUserId(client));
}

public Action Timer_RedeemReward(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (g_bRedeemingReward[client])
		PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 Please wait before using this command again!");
	else
		SQL_CheckLastRedeemed(client);
	
	return Plugin_Stop;
}

public Action CMD_DailyReward(int client, int args)
{
	if (g_bRedeemingReward[client])
		PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 Please wait before using this command again!");
	else
		SQL_CheckLastRedeemed(client);
	
	return Plugin_Handled;
}