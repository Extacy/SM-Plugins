#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <skynetjailbreak-bans>
#include <sourcebanspp>
#include <sourcecomms>

#pragma semicolon 1
#pragma newdecls required

Database g_ChatboxDatabase;

public Plugin myinfo = 
{
    name = "Chatbox Banlogs", 
    author = "Extacy", 
    description = "Logs Sourcebans/CT Bans to IPS forum chatbox", 
    version = "1.0", 
    url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
    g_ChatboxDatabase = null;
    Database.Connect(OnDBConnected, "forum");
}

public void OnDBConnected(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Could not connect to chatbox database: %s", error);
	}
	else
	{
		g_ChatboxDatabase = db;
		g_ChatboxDatabase.SetCharset("utf8mb4");
	}
}

public Action SNGJailbreak_Bans_OnCTBanClient(int admin, int target, int length, const char[] reason)
{
	SendChatboxMessage(admin, target, length, "CT Banned", reason);
}

public void SBPP_OnBanPlayer(int admin, int target, int length, const char[] reason)
{
	SendChatboxMessage(admin, target, length, "banned", reason);
}

public void SourceComms_OnBlockAdded(int admin, int target, int length, int type, char[] reason)
{
	char banType[32];

	switch(type)
	{
		case 1:
			banType = "muted";
		case 2:
			banType = "gagged";
		case 3:
			banType = "silenced";
	}

	SendChatboxMessage(admin, target, length, banType, reason);
}

void SendChatboxMessage(int admin, int target, int length, const char[] banType, const char[] reason)
{
	if (g_ChatboxDatabase == null)
	{
		LogError("Could not insert chatbox message! (Database is not connected)");
		return;
	}

	char targetName[32];
	GetClientName(target, targetName, sizeof(targetName));

	char targetSteamID[32];
	GetClientAuthId(target, AuthId_Steam2, targetSteamID, sizeof(targetSteamID));

	char adminName[32];
	if (admin == 0)
		adminName = "CONSOLE";
	else
		GetClientName(admin, adminName, sizeof(adminName));
		
	char message[400]; // max chatbox chars
	Format(message, sizeof(message), "%s [%s] was %s by %s for %i minutes! Reason: %s", targetName, targetSteamID, banType, adminName, length, reason);

	char[] messageEscaped = new char[strlen(message) * 2 + 1];
	SQL_EscapeString(g_ChatboxDatabase, message, messageEscaped, strlen(message) * 2 + 1);

	char szQuery[2048];
	Format(szQuery, sizeof(szQuery), "INSERT INTO `ipb_chatbox_messages` (`chat_member_id`, `chat_content`, `chat_time`, `chat_room`) VALUES (8761, '%s', %i, 1)", messageEscaped, GetTime());  
		
	g_ChatboxDatabase.Query(SQLCallback_Void, szQuery);
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || strlen(error) > 0)
	{
		LogError("Query failed: %s", error);
	}
}