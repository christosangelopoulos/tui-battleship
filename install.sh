#! /bin/bash
#make sh executable, copy it to the $PATH
chmod +x tui-battleship.sh
[[ -d $HOME/.local/bin/ ]]&&cp tui-battleship.sh $HOME/.local/bin/&&INSTALL_MESSAGE="The script was copied to\n\e[33m $HOME/.local/bin/\e[m\nProvided that this directory is included in the '\$PATH', the user can run the script with\n\e[33m$ tui-battleship.sh\e[m\nfrom any directory.\nAlternatively, the script can be run with\n\e[33m$ ./tui-battleship.sh\e[m\nfrom the tui-battleship/ directory."||INSTALL_MESSAGE="The script has been made executable and the user can run it with:\n\e[33m$ ./tui-battleship.sh\e[m\nfrom the tui-battleship/ directory."
# create the necessary directories and files:
mkdir -p $HOME/.local/share/tui-battleship/ $HOME/.config/tui-battleship/
cp  tui-battleship*.png $HOME/.local/share/tui-battleship/
touch $HOME/.local/share/tui-battleship/tui-battleship.log $HOME/.local/share/tui-battleship/hiscores.txt


echo -e "#Procedure to populate user's grid with ships. Acceptable values:auto, manual
PLACE_SHIPS=auto

#Number of Carriers (4 squares long), default 1, max 2
CARRIERS=1

#Number of Battleships (3 squares long), default 2, max 3
BATTLESHIPS=2

#Number of Cruisers (2 squares long), default 3, max 4
CRUISERS=3

#Number of Destroyers (1 square long), default 4, max 5
DESTROYERS=4

#Text editor to open config file
PREFERRED_EDITOR=${EDITOR-nano}

#Preferred themed png to show up in the notifications. Acceptable values:light, dark
PREFERRED_PNG=dark

#Acceptable notification toggle values: yes / no
NOTIFICATION_TOGGLE=yes

#Acceptable log toggle values: yes / no.
LOG_TOGGLE=yes

#Acceptable cheatsheet toggle values: yes / no. This can also be controlled while playing.
CHEATSHEET_TOGGLE=yes

#Key binding to hit a square. Spacebar is also hardcoded. Non acceptable values: Upper-case,q,i, arrow keys, navigation key-bindings.
HIT_BIND=f

#Acceptable values for navigation keys: vim, aswd. Arrow keys are hardcoded and work in all options.
NAVIGATION_KEYS=vim">$HOME/.config/tui-battleship/tui-battleship.config
echo -e "$INSTALL_MESSAGE"
