#!/bin/bash

DIR=/mnt/sdb/steam/kztimer/

# Exit server if running
tmux kill-session -t kztimer

# Update using SteamCMD
/mnt/sdb/steam/Steam/steamcmd.sh +force_install_dir $DIR +login anonymous +app_update 740 +quit

# Update Sourcemod / Metamod
mkdir $DIR/update-buffer && cd $DIR/update-buffer

# wget -qO- https://mms.alliedmods.net/mmsdrop/1.10/$(curl -s https://mms.alliedmods.net/mmsdrop/1.10/mmsource-latest-linux) | tar xz
wget -qO- https://sm.alliedmods.net/smdrop/1.10/$(curl -s https://sm.alliedmods.net/smdrop/1.10/sourcemod-latest-linux) | tar xz 

cp -r $DIR/update-buffer/addons/sourcemod/bin/* /mnt/sdb/steam/kztimer/csgo/addons/sourcemod/bin/
cp -r $DIR/update-buffer/addons/sourcemod/extensions/* /mnt/sdb/steam/kztimer/csgo/addons/sourcemod/extensions/
cp -r $DIR/update-buffer/addons/sourcemod/gamedata/* /mnt/sdb/steam/kztimer/csgo/addons/sourcemod/gamedata/
cp -r $DIR/update-buffer/addons/sourcemod/translations/* /mnt/sdb/steam/kztimer/csgo/addons/sourcemod/translations/
cp -r $DIR/update-buffer/addons/sourcemod/plugins/* /mnt/sdb/steam/kztimer/csgo/addons/sourcemod/plugins/


rm -r /mnt/sdb/steam/kztimer/update-buffer
