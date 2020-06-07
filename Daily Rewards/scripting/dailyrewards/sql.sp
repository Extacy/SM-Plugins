public void SQL_OnDBConnected(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Could not connect to chatbox database: %s", error);
	}
	else
	{
		g_Database = db;
		g_Database.SetCharset("utf8mb4");
		SQL_CreateTables();
	}
}

void SQL_CreateTables()
{
	char query[4096];
	Format(query, sizeof(query), " \
		CREATE TABLE IF NOT EXISTS `dailyrewards` ( \
			`id` INT NOT NULL AUTO_INCREMENT, \
			`steamid64` VARCHAR(32) NOT NULL, \
			`time_redeemed` INT NOT NULL, \
			`times_redeemed` INT DEFAULT 1, \
			`streak` INT DEFAULT 0, \
			PRIMARY KEY (`id`) \
		) ENGINE = InnoDB;");

	g_Database.Query(SQL_OnTablesCreated, query);
}

public void SQL_OnTablesCreated(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || strlen(error) > 0)
	{
		LogError("Query failed: %s", error);
	}

	// If plugin was reloaded
	for (int i = 0; i <= MaxClients; i++)
		if (IsValidClient(i))
			OnClientPostAdminCheck(i);
}

void SQL_CheckLastRedeemed(int client)
{
	if (!IsValidClient(client))
		return;

	if (!g_bRedeemingReward[client])
		g_bRedeemingReward[client] = true;

	char query[2048];
	char authid[32];
	GetClientAuthId(client, AuthId_SteamID64, authid, sizeof(authid));
	
	Format(query, sizeof(query), "SELECT `time_redeemed`, `streak` FROM `dailyrewards` WHERE `steamid64`='%s'", authid);						 
	g_Database.Query(SQL_OnCheckLastRedeemed, query, GetClientUserId(client));
}

public void SQL_OnCheckLastRedeemed(Database db, DBResultSet results, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if (db == null || strlen(error) > 0)
	{
		g_bRedeemingReward[client] = false;
		PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 An error occured when attempting to redeem your reward.");
		LogError("Query failed: %s", error);
	}

	DataPack pack = new DataPack();
	pack.WriteCell(userid);

	int currentTime = GetTime();

	char authid[32];
	GetClientAuthId(client, AuthId_SteamID64, authid, sizeof(authid));

	if (results.RowCount == 0)
	{
		pack.WriteCell(0); // streak
		pack.WriteCell(false);
		char query[2048];
		Format(query, sizeof(query), "INSERT INTO `dailyrewards` ( `steamid64`, `time_redeemed` ) VALUES ('%s', '%i' );", authid, currentTime);				 
		g_Database.Query(SQL_OnRowUpdated, query, GetClientUserId(client));
		return;
	}

	results.FetchRow();
	int lastRedeemed = results.FetchInt(0);
	int streak = results.FetchInt(1);

	int cooldown = g_RewardCooldown.IntValue;
	int difference = currentTime - lastRedeemed;

	if (difference >= cooldown)
	{
		pack.WriteCell(streak);

		char query[2048];
		Format(query, sizeof(query), "UPDATE `dailyrewards` SET `times_redeemed` = `times_redeemed` + 1, `time_redeemed` = '%i' WHERE `steamid64` = '%s';", currentTime, authid);						 
		g_Database.Query(SQL_OnRowUpdated, query, pack);

		if (difference <= 86400 && streak + 1 > g_Streak.IntValue)
		{
			Format(query, sizeof(query), "UPDATE `dailyrewards` SET `streak` = 0 WHERE `steamid64` = '%s';", authid);
			pack.WriteCell(true);
		}
		else
		{
			Format(query, sizeof(query), "UPDATE `dailyrewards` SET `streak` = `streak` + 1 WHERE `steamid64` = '%s';", authid);
			pack.WriteCell(false);
		}

		g_Database.Query(SQL_VoidCallback, query);
	}
	else
	{
		char time[32];
		ShowTime(cooldown - difference, time, sizeof(time));
		PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 You may redeem your next reward in %s.", time);
		g_bRedeemingReward[client] = false;
		delete pack;
	}
}

public void SQL_OnRowUpdated(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int streak = pack.ReadCell();
	bool giveStreak = pack.ReadCell();
	delete pack;
	
	int client = GetClientOfUserId(userid);

	if (db == null || strlen(error) > 0)
	{
		g_bRedeemingReward[client] = false;
		PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 An error occured when attempting to redeem your reward.");
		LogError("Query failed: %s", error);
	}

	if (!IsValidClient(client))
		return;

	PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 You have redeemed your reward of \x0F%i\x01 credits. (\x0FStreak: %i\x01)", g_RewardAmount.IntValue, streak);
	ServerCommand("sm_givecredits #%i %i", userid, g_RewardAmount.IntValue);

	if (giveStreak)
	{
		PrintToChat(client, " \x02[\x01Daily Reward\x02]\x01 You have redeemed your \x02bonus\x01 reward of \x0F%i\x01 credits.", g_StreakAmount.IntValue);
		ServerCommand("sm_givecredits #%i %i", userid, g_RewardAmount.IntValue);
	}

	g_bRedeemingReward[client] = false;
}

public void SQL_VoidCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || strlen(error) > 0)
	{
		LogError("Query failed: %s", error);
	}
}