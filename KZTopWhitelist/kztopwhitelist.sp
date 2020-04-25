#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

Database g_dDatabase = null;

ConVar g_MaxRank;
ConVar g_AllowVIP;

public Plugin myinfo = 
{
    name = "KZ Whitelist", 
    author = "Extacy", 
    description = "Whitelist for the top X (cvar) players", 
    version = "1.0", 
    url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
    AutoExecConfig(true, "kzwhitelist");
    g_MaxRank = CreateConVar("sm_kzwhitelist_max", "100", "Players at or above this value are whitelisted");
    g_AllowVIP = CreateConVar("sm_kzwhitelist_vip", "1", "Allow VIPs to join the server regardless of their rank");
}

public void OnConfigsExecuted()
{    
    if (g_dDatabase != null)
    {
        LogError("(KZ Whitelist) Database is already connected!");
        return;
    }

    Database.Connect(SQLConnectCallback, "kztimer");
}

public void SQLConnectCallback(Database db, const char[] error, any data)
{
    if (db == null)
    {
        SetFailState("(KZ Whitelist) Could not connect to database! Error: %s", error);
    }

    g_dDatabase = db;
}

public void OnClientPostAdminCheck(int client)
{
    // Only kick valid players
    if (!IsValidClient(client))
        return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    // Allow admins and if true, VIPs
    if (CheckCommandAccess(client, "", ADMFLAG_GENERIC) || (g_AllowVIP.BoolValue && CheckCommandAccess(client, "", ADMFLAG_RESERVATION)))
        return;

    char query[256];
    Format(query, sizeof(query), "SELECT * FROM (SELECT `steamid`, `points` FROM `playerrank` ORDER BY `points` DESC LIMIT %i) AS subquery WHERE `steamid` = '%s'", g_MaxRank.IntValue, steamid);
   
    g_dDatabase.Query(SQL_QueryCallback, query, GetClientUserId(client));
}

public void SQL_QueryCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        LogError("(KZ Whitelist) Query failed: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (!results.HasResults || !results.FetchRow())
    {
        KickClient(client, "This server is whitelisted for the top %i players of our main KZ server. Join our public server (173.234.30.235:27015) in the mean time!", g_MaxRank.IntValue);
    }
}

bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	if (IsClientSourceTV(client)) return false;
	return IsClientInGame(client);
}