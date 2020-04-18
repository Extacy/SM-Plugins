#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <kztimer>

#pragma semicolon 1
#pragma newdecls required

#define CHAT_PREFIX " \x02[\x01Extend Time\x02]\x01" 
#define CHAT_COLOR "\x01"
#define CHAT_ACCENT "\x0F"

// Plugin ConVars
ConVar g_VoteCooldown;
ConVar g_VoteCountdown;

// Plugin Variables
Menu g_hVoteMenu = null;
int g_iCooldown[MAXPLAYERS + 1];
bool g_bKZTimer = false;

// CSGO ConVars 
ConVar mp_timelimit;

public Plugin myinfo = 
{
    name = "Extend Time", 
    author = "Extacy", 
    description = "", 
    version = "1.0", 
    url = "https://steamcommunity.com/profiles/76561198183032322"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_extendvote", CMD_ExtendTimeVote);
    RegConsoleCmd("sm_voteextend", CMD_ExtendTimeVote);
    RegConsoleCmd("sm_extendtimevote", CMD_ExtendTimeVote);

    RegAdminCmd("sm_extend", CMD_ExtendTime, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_extendtime", CMD_ExtendTime, ADMFLAG_CHANGEMAP);

    mp_timelimit = FindConVar("mp_timelimit");
    SetConVarFlags(mp_timelimit, GetConVarFlags(mp_timelimit) & ~FCVAR_NOTIFY);

    g_VoteCountdown = CreateConVar("sm_extendtime_vote_countdown", "10", "How long should the warning be before the vote is called. Prints to chat every second");
    g_VoteCooldown = CreateConVar("sm_extendtime_vote_cooldown", "120", "In seconds, cooldown for a player to call another extend vote");
}

public void OnAllPluginsLoaded()
{
	g_bKZTimer = LibraryExists("KZTimer");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "KZTimer"))
		g_bKZTimer = true;
}

public void OnLibraryREmoved(const char[] name)
{
	if (StrEqual(name, "KZTimer"))
		g_bKZTimer = false;
}

public Action CMD_ExtendTime(int client, int args)
{
    if (args != 1)
    {
        PrintToChat(client, "%s Usage: sm_extend <[+/-] minutes>", CHAT_PREFIX);
        return Plugin_Handled;
    }

    char arg[10];
    GetCmdArg(1, arg, sizeof(arg));

    int increase = StringToInt(arg);
    mp_timelimit.SetInt(mp_timelimit.IntValue + increase);

    int mins, secs;
    GetMapTimeLeft(secs);
    mins = secs / 60;
    secs = secs % 60;

    PrintToChatAll("%s %s%N%s extended the map by %s%i minutes%s! (Timeleft: %s%i:%02i%s)", CHAT_PREFIX, CHAT_ACCENT, client, CHAT_COLOR, CHAT_ACCENT, increase, CHAT_COLOR, CHAT_ACCENT, mins, secs, CHAT_COLOR);
    return Plugin_Handled;
}

public Action CMD_ExtendTimeVote(int client, int args)
{
    int cooldown = GetTime() - g_iCooldown[client];

    if (cooldown < g_VoteCooldown.IntValue)
    {
        PrintToChat(client, "%s You must wait %s%i%s seconds before calling another vote.", CHAT_PREFIX, CHAT_ACCENT, g_VoteCooldown.IntValue - cooldown, CHAT_COLOR);
        return Plugin_Handled;
    }

    Menu menu = new Menu(ExtendTimeMenuHandler);

    int timeleft;
    GetMapTimeLeft(timeleft);

    int mins, secs;
    mins = timeleft / 60;
    secs = timeleft % 60;

    char title[64];
    Format(title, sizeof(title), "Extend Map? (Timeleft: %i:%02i)", mins, secs);

    menu.SetTitle(title);
    menu.AddItem("1", "1 minute");
    menu.AddItem("2", "2 minutes");
    menu.AddItem("5", "5 minutes");
    menu.AddItem("10", "10 minutes");
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int ExtendTimeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));

        int extend = StringToInt(info);

        DataPack pack;
        CreateDataTimer(1.0, Timer_VoteCountdown, pack, TIMER_REPEAT);
        pack.WriteCell(param1);
        pack.WriteCell(extend);
        
        g_iCooldown[param1] = GetTime();
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    
    return;
}

public Action Timer_VoteCountdown(Handle timer, DataPack pack)
{
    static bool active = false;
    static int countdown;

    if (!active)
    {
        countdown = g_VoteCountdown.IntValue;
        active = true;
    }

    if (countdown == 0)
    {
        pack.Reset();
        int client = pack.ReadCell();
        int extend = pack.ReadCell();

        char info[32];
        IntToString(extend, info, sizeof(info));
    
        int mins, secs;
        GetMapTimeLeft(secs);
        mins = secs / 60;
        secs = secs % 60;

        char title[64];
        Format(title, sizeof(title), "Extend Map by %i minutes? (Timeleft: %i:%02i)", extend, mins, secs);

        if (g_bKZTimer)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                KZTimer_StopUpdatingOfClimbersMenu(i);
            }
        }

        g_hVoteMenu= new Menu(VoteMenuHandler, MENU_ACTIONS_ALL);
        g_hVoteMenu.SetTitle(title);
        g_hVoteMenu.AddItem(info, "Yes");
        g_hVoteMenu.AddItem("no", "No");
        g_hVoteMenu.ExitButton = false;
        g_hVoteMenu.DisplayVoteToAll(20);

        PrintToChatAll("%s %s%N%s is voting to extend the map by %s%i%s minutes!", CHAT_PREFIX, CHAT_ACCENT, client, CHAT_COLOR, CHAT_ACCENT, extend, CHAT_COLOR);
        active = false;
        return Plugin_Stop;
    }

    PrintToChatAll("%s %sWARNING%s - Extend time vote in %s%i seconds%s. Pause your timers!", CHAT_PREFIX, CHAT_ACCENT, CHAT_COLOR, CHAT_ACCENT, countdown, CHAT_COLOR);

    countdown--;
    return Plugin_Continue;
}

public int VoteMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
#if defined _KZTimer_included
        if (g_bKZTimer)
        {
            ClientCommand(param1, "sm_menu");
        }
#endif
    }
    else if (action == MenuAction_VoteEnd)
    {
        int votes, totalVotes;
        GetMenuVoteInfo(param2, votes, totalVotes);

        float percent = float(votes) / float(totalVotes);

        if (param1 == 0) /* 0=yes, 1=no */
        {
            char buffer[16];
            menu.GetItem(param1, buffer, sizeof(buffer));
            int increase = StringToInt(buffer);

            mp_timelimit.SetInt(mp_timelimit.IntValue + increase);

            int mins, secs;
            GetMapTimeLeft(secs);
            mins = secs / 60;
            secs = secs % 60;

            PrintToChatAll("%s Vote passed! (%sRecieved %i%% of %i votes%s)", CHAT_PREFIX, CHAT_ACCENT, RoundToNearest(100.0 * percent), totalVotes, CHAT_COLOR);
            PrintToChatAll("%s The map has been extended by %s%i%s minutes. (Timeleft: %s%i:%02i%s)", CHAT_PREFIX, CHAT_ACCENT, increase, CHAT_COLOR, CHAT_ACCENT, mins, secs, CHAT_COLOR);
        }
        else
        {
            PrintToChatAll("%s Not enough players voted to extend the map! (%sRecieved %i%% of %i votes%s)", CHAT_PREFIX, CHAT_ACCENT, RoundToNearest(100.0 * percent), totalVotes, CHAT_COLOR);
        }
    }
    else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
    {
        PrintToChatAll("%s No players voted to extend the map!", CHAT_PREFIX);
    }
    else if (action == MenuAction_End)
    {
        delete g_hVoteMenu;
    }

    return 0;
}
