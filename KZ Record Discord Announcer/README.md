# KZ Record Discord Announcer

Sends a message to your Discord server when a server record was beat on your KZ Server.

## Screenshot
<img src="https://i.imgur.com/tft1LUQ.png">

## Requirements
[Discord/Slack API](https://forums.alliedmods.net/showthread.php?t=292663)

## Setup

Create a Webhook in your Discord Server, copy the URL.

Add the following KeyValue to `addons/sourcemod/configs/discord.cfg`

```
"recordannouncer"
{
        "url"   "YOUR_WEBHOOK_URL"
}
```

Done!