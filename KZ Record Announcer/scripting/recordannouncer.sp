#include <sourcemod>
#include <kztimer>
#include <discord>

#pragma semicolon 1
#pragma newdecls required

#define TP_RECORD_MSG "{\"embeds\":[{\"title\":\"A New Record (TP) was set on {SERVERNAME}!\",\"color\":3269647,\"fields\":[{\"name\":\"Player\",\"value\":\"{PLAYERNAME}\",\"inline\":true},{\"name\":\"Map\",\"value\":\"{MAPNAME}\",\"inline\":true},{\"name\":\"Teleports\",\"value\":\"{TELEPORTS}\",\"inline\":true},{\"name\":\"Time\",\"value\":\"{TIME}\"}],\"footer\":{\"text\":\"Record Set\",\"icon_url\":\"https://i.imgur.com/a2njRa3.png\"},\"timestamp\":\"{TIMESTAMP}\",\"thumbnail\":{\"url\":\"https://raw.githubusercontent.com/KZGlobalTeam/map-images/public/images/{MAPNAME}.jpg\"}}]}"
#define PRO_RECORD_MSG "{\"embeds\":[{\"title\":\"A New Record (PRO) was set on {SERVERNAME}!\",\"color\":1016785,\"fields\":[{\"name\":\"Player\",\"value\":\"{PLAYERNAME}\",\"inline\":true},{\"name\":\"Map\",\"value\":\"{MAPNAME}\",\"inline\":true},{\"name\":\"Time\",\"value\":\"{TIME}\",\"inline\":true}],\"footer\":{\"text\":\"Record Set\",\"icon_url\":\"https://i.imgur.com/a2njRa3.png\"},\"timestamp\":\"{TIMESTAMP}\",\"thumbnail\":{\"url\":\"https://raw.githubusercontent.com/KZGlobalTeam/map-images/public/images/{MAPNAME}.jpg\"}}]}"


public Plugin myinfo = 
{
    name = "Record Announcer", 
    author = "Extacy", 
    description = "", 
    version = "1.0", 
    url = "https://steamcommunity.com/profiles/76561198183032322"
};

public int KZTimer_TimerStopped(int client, int teleports, float time, int record)
{
    if (!record) return;

    char message[4096];
    if (teleports == 0)
        message = PRO_RECORD_MSG;
    else
        message = TP_RECORD_MSG;

    char playerName[MAX_NAME_LENGTH];
    GetClientName(client, playerName, sizeof(playerName));

    char playerAuthId[64];
    GetClientAuthId(client, AuthId_SteamID64, playerAuthId, sizeof(playerAuthId));

    char playerNameString[256];
    Format(playerNameString, sizeof(playerNameString), "[%s](https://steamcommunity.com/profiles/%s)", playerName, playerAuthId);
    ReplaceString(message, sizeof(message), "{PLAYERNAME}", playerNameString);

    char mapName[PLATFORM_MAX_PATH];
    GetCurrentMap(mapName, sizeof(mapName));
    ReplaceString(message, sizeof(message), "{MAPNAME}", mapName);

    char teleportsString[8];
    IntToString(teleports, teleportsString, sizeof(teleportsString));
    ReplaceString(message, sizeof(message), "{TELEPORTS}", teleportsString);

    char timeString[12];
    ShowTime(time, timeString, sizeof(timeString));
    ReplaceString(message, sizeof(message), "{TIME}", timeString);

    char timestamp[32];
    FormatTime(timestamp, sizeof(timestamp), "%FT%TZ"); // ISO 8601
    ReplaceString(message, sizeof(message), "{TIMESTAMP}", timestamp);

    char serverName[32];
    GetConVarString(FindConVar("hostname"), serverName, sizeof(serverName));
    SplitString(serverName, " |", serverName, sizeof(serverName)); // remove tags from hostname
    ReplaceString(message, sizeof(message), "{SERVERNAME}", serverName);

    Discord_SendMessage("recordannouncer", message);
}

// Credit: http://0x0.st/ZHcQ
char[] ShowTime(float time, char[] buffer, int maxlength)
{
    int roundedTime = RoundFloat(time * 100); // Time rounded to number of centiseconds
    
    int centiseconds = roundedTime % 100;
    roundedTime = (roundedTime - centiseconds) / 100;
    int seconds = roundedTime % 60;
    roundedTime = (roundedTime - seconds) / 60;
    int minutes = roundedTime % 60;
    roundedTime = (roundedTime - minutes) / 60;
    int hours = roundedTime;

    if (hours > 0)
        Format(buffer, maxlength, "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds);
    else
        Format(buffer, maxlength, "%02d:%02d.%02d", minutes, seconds, centiseconds);
}