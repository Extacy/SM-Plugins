bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	if (IsClientSourceTV(client)) return false;
	return IsClientInGame(client);
}

void ShowTime(int time, char[] buffer, int maxlength)
{
	int hours = 0;
	int minutes = 0;
	int seconds = time;
	
	while (seconds > 3600)
	{
		hours++;
		seconds -= 3600;
	}
	
	while (seconds > 60)
	{
		minutes++;
		seconds -= 60;
	}
	
	if (hours >= 1)
		Format(buffer, maxlength, "\x0F%i hours\x01 and \x0F%i minutes\x01", hours, minutes);
	else if (minutes >= 1)
		Format(buffer, maxlength, "\x0F%i minutes\x01 and \x0F%i seconds\x01", minutes, seconds);
	else
		Format(buffer, maxlength, "\x0F%i seconds\x01", seconds);
}
