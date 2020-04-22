#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle g_hTimer = null;

public Plugin myinfo = 
{
    name = "Force Map End", 
    author = "Extacy", 
    description = "Forces a map to end when mp_timelimit runs out", 
    version = "1.0", 
    url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnMapStart()
{
    StartTimer();
}

public void OnMapEnd()
{
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

public Action Timer_CheckTimeleft(Handle timer, any data)
{
    int time;
    GetMapTimeLeft(time);
    
    if (time > 0)
        return Plugin_Continue;

    if (GetClientCount(true) <= 0)
        return Plugin_Continue;

    // Map has ended
    if (time <= 0)
    {
        char map[PLATFORM_MAX_PATH];
        if (GetNextMap(map, sizeof(map)))
        {
            ForceChangeLevel(map, "forcemapend.smx");
            g_hTimer = null;
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}