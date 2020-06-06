#if defined _skynetjailbreak_bans_included
 #endinput
#endif
#define _skynetjailbreak_bans_included

#include <sdkhooks>

#define SNG_BANS_PREFIX " \x07[\x04Jailbreak Bans\x07] \x01-\x09"

#define INVALID_BAN_ID -1
#define INVALID_UNIX_TIME_STAMP 0
#define INVALID_BAN_LENGTH -1

// Max size for a admin name in BanInformation enum
#define SNGJAILBREAK_BANS_BANNED_BY_NAME_SIZE 32

// Max size for a ban reason in BanInformation enum
#define SNGJAILBREAK_BANS_BAN_REASON_SIZE 64

enum BanInformation
{
	iBanId,
	iBanCreated,
	iBanLength,
	iBanCount,
	iUnbanned,
	iTimeLeft,
	iTimeExpired,
	String:szBannedByName[SNGJAILBREAK_BANS_BANNED_BY_NAME_SIZE],
	String:szBanReason[SNGJAILBREAK_BANS_BAN_REASON_SIZE],
}

enum //CTBanStatus
{
	CTBAN_NONE = 0,
	CTBAN_EXPIRED,
	CTBAN_UNBANNED,
	CTBAN_PERIOD,
	CTBAN_PERMANENT
}

/**
 * Returns ct ban status
 * @param client index
 * @return  int					status of the ban (see CTBanStatus enum above)
 */
native int SNGJailbreak_Bans_GetClientCTBanStatus(int client);

/**
 * Returns client ready status
 * @param client index
 * @return  bool				is client ban info loaded
 */
native bool SNGJailbreak_Bans_IsClientBanLoaded(int client);

/**
 * Returns client ban date (unix timestamp)
 * @param client index
 * @return  int					unix timestamp
 */
native int SNGJailbreak_Bans_GetClientCTBanDate(int client);

/**
 * Returns client ban length (in minutes)
 * @param client index
 * @return  int				time in minutes
 */
native int SNGJailbreak_Bans_GetClientCTBanLength(int client);

/**
 * Called when a client is ct banned
 * @param client index that bans
 * @param client index that gets banned
 * @param length of the ban in minutes
 * @param reason of the ban
 * @noreturn
 */
forward Action SNGJailbreak_Bans_OnCTBanClient(int client, int target, int banLength, const char[] reason);

/**
 * Called when a client is ct unbanned
 * @param client index that unbans
 * @param client index that gets unbanned
 * @param the time client was unbanned in unix timestamp
 * @noreturn
 */
forward void SNGJailbreak_Bans_OnUnCTBanClient(int client, int target, int timeUnbanned);

public SharedPlugin __pl_SNGJailBreak_Bans  =
{
	name = "skynetjailbreak-bans",
	file = "skynetjailbreak-bans.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_SNGJailBreak_Bans_SetNTVOptional()
{	
	MarkNativeAsOptional("SNGJailbreak_Bans_GetClientCTBanStatus");
	MarkNativeAsOptional("SNGJailbreak_Bans_IsClientBanLoaded");
	MarkNativeAsOptional("SNGJailbreak_Bans_GetClientCTBanDate");
	MarkNativeAsOptional("SNGJailbreak_Bans_GetClientCTBanLength");
}
#endif