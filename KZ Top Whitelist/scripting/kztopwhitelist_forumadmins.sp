#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

Database g_dbKZTimer = null;
Database g_dbForum = null;

ArrayList g_WhitelistExceptions;
int g_iExceptionCount;

int g_iAdminIdCount;
int g_iAdminIDs[128];

ConVar g_MinRank;
ConVar g_AllowVIP;

public Plugin myinfo = 
{
    name = "KZ Whitelist Forum Admins", 
    author = "Extacy", 
    description = "Whitelist for the top X (cvar) players - Allow admins (using Bara's forum_admins)", 
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

    LoadAdminIDs();
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

    char steamid[32];
    while (!IsEndOfFile(file))
    {
        ReadFileLine(file, steamid, sizeof(steamid));
        TrimString(steamid);

        if (steamid[0] == '\0' || strncmp(steamid, "//", 2) == 0)
            continue;
        
        g_WhitelistExceptions.PushString(steamid);
        g_iExceptionCount++;
    }
}

public void LoadAdminIDs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/forum_admins.cfg");
    
    KeyValues kv = new KeyValues("forum_admins");
    kv.ImportFromFile(path);
    kv.Rewind();
    kv.GotoFirstSubKey(false);
    
    g_iAdminIdCount = 0;

    do
    {
        char id[10];
        kv.GetSectionName(id, sizeof(id));
        g_iAdminIDs[g_iAdminIdCount] = StringToInt(id);
        g_iAdminIdCount++;

    } while (kv.GotoNextKey(true));

    delete kv;
}

public void OnConfigsExecuted()
{    
    if (g_dbKZTimer != null)
    {
        LogError("[KZ Whitelist] KZTimer Database is already connected!");
        return;
    }

    Database.Connect(OnKZTImerDBConnected, "kztimer");
   
    if (g_dbForum != null)
    {
        LogError("[KZ Whitelist] Forum Database is already connected!");
        return;
    }

    Database.Connect(OnForumDBConnected, "forum");
}

public void OnKZTImerDBConnected(Database db, const char[] error, any data)
{
    if (db == null)
    {
        SetFailState("[KZ Whitelist] Could not connect to KZTimer database! Error: %s", error);
    }

    g_dbKZTimer = db;
}

public void OnForumDBConnected(Database db, const char[] error, any data)
{
    if (db == null)
    {
        SetFailState("[KZ Whitelist] Could not connect to Forum database! Error: %s", error);
    }

    g_dbForum = db;
}

public void OnClientPostAdminCheck(int client)
{
    IsPlayerAdmin(client);
}

void IsPlayerAdmin(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

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

    char query[256];
    Format(query, sizeof(query), "SELECT `member_group_id` FROM `ipb_core_members` WHERE `steamid` = '%s' LIMIT 1", steamid);
   
    g_dbForum.Query(SQL_OnAdminCheck, query, GetClientUserId(client));
}

public void SQL_OnAdminCheck(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        SetFailState("[KZ Whitelist] SQL_OnAdminCheck Query failed: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        LogError("[KZ Whitelist] SQL_OnAdminCheck Error: Player is invalid");
        return;
    }

    if (results.FetchRow())
    {
        if (results.IsFieldNull(0))
        {
            LogError("[KZ Whitelist] SQL_OnAdminCheck Error retrieving `member_group_id`: (Field is null)");
            return;
        }

        int groupID = results.FetchInt(0);
        for (int i = 0; i < g_iAdminIdCount; i++)
        {
            if (groupID == g_iAdminIDs[i])
            {
                PrintToServer("[KZ Whitelist] Whitelisted %N. (Player is admin)", client);
                return;
            }
        }

    }

    IsPlayerWhitelisted(client);
}

void IsPlayerWhitelisted(int client)
{
    if (!IsValidClient(client))
        return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    // TODO, use SAVM (or just never do bc we don't have it enabled lul)
    // if (g_AllowVIP.BoolValue && CheckCommandAccess(client, "", ADMFLAG_RESERVATION))
    // {
    //     PrintToServer("[KZ Whitelist] Whitelisted %N. (Player is VIP)", client);
    //     return;
    // }

    char query[256];
    Format(query, sizeof(query), "SELECT * FROM (SELECT `steamid`, `points` FROM `playerrank` ORDER BY `points` DESC LIMIT %i) AS subquery WHERE `steamid` = '%s'", g_MinRank.IntValue, steamid);
   
    g_dbKZTimer.Query(SQL_OnWhitelistCheck, query, GetClientUserId(client));
}

public void SQL_OnWhitelistCheck(Database db, DBResultSet results, const char[] error, int userid)
{
    if (db == null || strlen(error) > 0)
    {
        LogError("[KZ Whitelist] SQL_OnWhitelistCheck Query failed: %s", error);
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