#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

Database g_dDatabase = null;

ArrayList g_WhitelistExceptions;
int g_iExceptionCount;

ConVar g_MinRank;
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
    RegAdminCmd("sm_kzwhitelist_reload_exceptions", CMD_ReloadExceptions, ADMFLAG_ROOT);
    g_WhitelistExceptions = new ArrayList(256);
    LoadWhitelistExceptions();

    AutoExecConfig(true, "kzwhitelist");
    g_MinRank = CreateConVar("sm_kzwhitelist_max", "100", "Players at or above this value are whitelisted");
    g_AllowVIP = CreateConVar("sm_kzwhitelist_vip", "1", "Allow VIPs to join the server regardless of their rank");
}

public Action CMD_ReloadExceptions(int client, int args)
{
    LoadWhitelistExceptions();
    ReplyToCommand(client, "[KZ Top Whitelist] Reloaded exception list!");
}

public void LoadWhitelistExceptions()
{
    g_iExceptionCount = 0;
    g_WhitelistExceptions.Clear();

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/kztopwhitelist/exceptions.txt");

    if (!FileExists(path))
        SetFailState("[kztopwhitelist.smx] Could not load %s", path);

    File file = OpenFile(path, "rt");

    if (!file)
        SetFailState("[kztopwhitelist.smx] Could not load %s", path);

    char buffer[64];
    while (!IsEndOfFile(file))
    {
        ReadFileLine(file, buffer, sizeof(buffer));
        TrimString(buffer);

        if (buffer[0] == '\0' || strncmp(buffer, "//", 2) == 0)
            continue;
        
        g_WhitelistExceptions.PushString(buffer);
        g_iExceptionCount++;
    }
}

public void OnConfigsExecuted()
{    
    if (g_dDatabase != null)
    {
        LogError("[KZ Whitelist] Database is already connected!");
        return;
    }

    Database.Connect(SQLConnectCallback, "kztimer");
}

public void SQLConnectCallback(Database db, const char[] error, any data)
{
    if (db == null)
    {
        SetFailState("[KZ Whitelist] Could not connect to database! Error: %s", error);
    }

    g_dDatabase = db;
}

public void OnClientPostAdminCheck(int client)
{
    IsPlayerWhitelisted(client);
}

void IsPlayerWhitelisted(int client)
{
    if (!IsValidClient(client))
        return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    for (int i = 0; i < g_iExceptionCount; i++)
    {
        char buffer[32];
        g_WhitelistExceptions.GetString(i, buffer, sizeof(buffer));
        if (StrEqual(steamid, buffer))
        {
            PrintToServer("[KZ Whitelist] Whitelisted %N. (Player is on exception list)", client);
            return;
        }
    }

    // Allow admins
    if (CheckCommandAccess(client, "", ADMFLAG_GENERIC))
    {
        PrintToServer("[KZ Whitelist] Whitelisted %N. (Player is admin)", client);
        return;
    }

    if (g_AllowVIP.BoolValue && CheckCommandAccess(client, "", ADMFLAG_RESERVATION))
    {
        PrintToServer("[KZ Whitelist] Whitelisted %N. (Player is VIP)", client);
        return;
    }

    char query[256];
    Format(query, sizeof(query), "SELECT * FROM (SELECT `steamid`, `points` FROM `playerrank` ORDER BY `points` DESC LIMIT %i) AS subquery WHERE `steamid` = '%s'", g_MinRank.IntValue, steamid);
   
    g_dDatabase.Query(SQL_QueryCallback, query, GetClientUserId(client));
}

public void SQL_QueryCallback(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("[KZ Whitelist] Query failed: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (!results.HasResults || !results.FetchRow())
    {
        KickClient(client, "This server is whitelisted for the top %i players of our main KZ server. Join our public server (173.234.30.235:27015) in the mean time!", g_MinRank.IntValue);
    }
    else
    {
        PrintToServer("[KZ Whitelist] Whitelisted %N. (Player is in top %i)", client, g_MinRank.IntValue);
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