#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle g_hTimer = null;
ConVar mp_timelimit;
bool g_bChangeMap = true;


public Plugin myinfo = 
{
    name = "Force Map End", 
    author = "Extacy", 
    description = "Forces a map to end when mp_timelimit runs out", 
    version = "1.0", 
    url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
    mp_timelimit = FindConVar("mp_timelimit");
    mp_timelimit.AddChangeHook(OnTimelimitChanged);
}

public void OnMapStart()
{
    if (mp_timelimit.IntValue == 0)
        g_bChangeMap = false;

    StartTimer();
}

public void OnMapEnd()
{
    g_bChangeMap = true;
    StopTimer();
}

void StartTimer()
{
    StopTimer();
    g_hTimer = CreateTimer(1.0, Timer_CheckTimeleft, _, TIMER_REPEAT);
}

void StopTimer()
{
    if (g_hTimer != null)
        KillTimer(g_hTimer);

    g_hTimer = null;
}

public void OnTimelimitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) > 0)
        g_bChangeMap = true;
}

public Action Timer_CheckTimeleft(Handle timer, any data)
{
    int time;
    GetMapTimeLeft(time);
    
    if (time > 0)
        return Plugin_Continue;

    if (GetClientCount(true) <= 0)
        return Plugin_Continue;

    // Map has ended
    if (g_bChangeMap && time < 0)
    {
        char nextMap[PLATFORM_MAX_PATH];
        if (GetNextMap(nextMap, sizeof(nextMap)))
        {
            ForceChangeLevel(nextMap, "forcemapend.smx");
            g_hTimer = null;
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}