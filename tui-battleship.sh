#! /bin/bash
#tui-battleship, a tui implementation of the popular pen & paper game, written in Bash by Christos Angelopoulos,under GPL v2, April 2024
function load_colors()
{
  C0="\e[38;5;242m" #Grid Color
  C1="\e[33m" #Given Numbers Color-Yellow
  C2="\e[36m" #Found Numbers Color-Cyan
  C3="\e[31m" #Red
  C4="\e[35m" #TextColor1 Magenta
  C5="\e[34m" #blue
  C6="\e[32m" # green
}

function load_config()
{
 config_fail=0
 [[ -z "$CONFIG_FILE" ]]&&config_fail=1||source "$CONFIG_FILE"
 #DEFAULT VALUES in case config doesn't load
 [[ -z $PLACE_SHIPS ]]&&PLACE_SHIPS=auto&&config_fail=1
 [[ -z $CARRIERS ]]&&CARRIERS=1&&config_fail=1
 [[ -z $BATTLESHIPS ]]&&BATTLESHIPS=2&&config_fail=1
 [[ -z $CRUISERS ]]&&CRUISERS=3&&config_fail=1
 [[ -z $DESTROYERS ]]&&DESTROYERS=4&&config_fail=1
 [[ -z $PREFERRED_EDITOR ]]&&PREFERRED_EDITOR=${EDITOR-nano}&&config_fail=1
 [[ -z $PREFERRED_PNG ]]&&PREFERRED_PNG="dark"&&config_fail=1
 [[ -z $NOTIFICATION_TOGGLE ]]&&NOTIFICATION_TOGGLE='yes'&&config_fail=1
 [[ -z $CHEATSHEET_TOGGLE ]]&&CHEATSHEET_TOGGLE='yes'&&config_fail=1
 [[ -z $LOG_TOGGLE ]]&&LOG_TOGGLE='yes'&&config_fail=1
 [[ -z $HIT_BIND ]]&&HIT_BIND="f"&&config_fail=1
 [[ -z $NAVIGATION_KEYS ]]&&NAVIGATION_KEYS="vim"&&config_fail=1
 [[ $CARRIERS -gt 2 ]]||[[ $CARRIERS -lt 0 ]]&&CARRIERS=1
 [[ $BATTLESHIPS -gt 3 ]]||[[ $BATTLESHIPS -lt 0 ]]&&BATTLESHIPS=2
 [[ $CRUISERS -gt 4 ]]||[[ $CRUISERS -lt 0 ]]&&CRUISERS=3
 [[ $DESTROYERS -gt 5 ]]||[[ $DESTROYERS -lt 0 ]]&&DESTROYERS=4
 if [[ $NAVIGATION_KEYS == 'vim' ]];then NAV_LEFT='h';NAV_DOWN='j';NAV_UP='k';NAV_RIGHT='l';CHEAT_NAV='hjkl';fi
 if [[ $NAVIGATION_KEYS == 'aswd' ]];then NAV_LEFT='a';NAV_DOWN='s';NAV_UP='w';NAV_RIGHT='d';CHEAT_NAV='aswd';fi
 TOTAL=$(($CARRIERS*4+$BATTLESHIPS*3+$CRUISERS*2+$DESTROYERS))
 load_colors
[[ $config_fail == 1 ]]&&notify-send -t 9000 -i  "$SHARE_DIR/tui-battleship-$PREFERRED_PNG.png" "Configurations not loaded correctly.
Running with hardcoded default values."
}

function show_hiscores ()
{
 echo -e "                          ${C0} ╔═══╤═══╤═══╤═══╤═══╤═══╤═══╗ \n                           ║ ${C1}T${C0} │ ${C1}O${C0} │ ${C1}P${C0} │ ${C3}-${C0} │ ${C1}T${C0} │ ${C1}E${C0} │ ${C1}N${C0} ║\n                           ╚═══╧═══╧═══╧═══╧═══╧═══╧═══╝"
 if [[ -f "$SHARE_DIR/hiscores.txt" ]]&&[[ -n $(cat "$SHARE_DIR/hiscores.txt") ]]
 then
  TOP_10_LENGTH=$(cat "$SHARE_DIR/hiscores.txt"|wc -l)
  if [[ $TOP_10_LENGTH -gt 10 ]];then TOP_10_LENGTH=10;fi
  ii=31;i=1;
  while [[ $i -le $TOP_10_LENGTH ]]
  do
   echo -e '                             \e['${ii}m$i $(sort -h "$SHARE_DIR/hiscores.txt" |head -$i|tail +$i)
   sleep 0.3
   ((i++));((ii++))
   if [[ $ii -gt 36 ]];then ii=31;fi;
  done
 else echo -e "                    No statistics available just yet."
 fi
 tput civis; #make cursor disappear
}

function draw_line ()
{
 d=1
 echo -ne "${C0}""$1"
 while [[ $d -le $5 ]]
 do
 echo -ne "$2$2$2"
 [[ $d -lt $5 ]]&&echo -ne "$3"||echo -ne "$4"
 ((d++))
 done
}

function load_cheat()
{
if [[ $CHEATSHEET_TOGGLE == yes ]];then echo -e "${C0}╭────────────────────┬─────────────────┬──────┬─────────┬───────────┬────────────╮\n│${C4}$CHEAT_NAV/arrow keys:${C2}Move${C0}│${C4}$HIT_BIND/space/enter:${C2}Hit${C0}│${C4}q:${C2}Quit${C0}│${C4}r:${C2}Restart${C0}│${C4}i:${C2}Hide Info${C0}│${C4}u:${C2}Toggle Log${C0}│\n╰────────────────────┴─────────────────┴──────┴─────────┴───────────┴────────────╯\n${n}";else info1="${C4} Computer: $CPU_TRIES Tries $CPU_HITS/$TOTAL Hits                               ";info2="${C2} You: $USR_TRIES Tries $USR_HITS/$TOTAL Hits  ";echo -e "${info1:0:47}${info2}\n${C0} Enter ${C4}i${C0} to Show Cheatsheet${n}";fi
}

function load_grids()
{
 i=0;ii=0
 F="";G="";P=""
 while [[ $i -lt 100 ]]
 do
#  X[i]=${C2} #sq color
  USR_F[i]="░░░" #sq appearence
  USR_G[i]="0"  #sq content
  USR_X[i]=${C5}
  USR_P[i]=$ii #sq position:== 0:left border, == $((WIDTH - 1)): right border, -lt $WIDTH:top border,  -ge $((TOTAL-WIDTH)) bottom border
  CPU_F[i]="░░░" #sq appearence
  CPU_G[i]="0"  #sq content
  CPU_P[i]=$ii
  CPU_X[i]=${C5}
  ((i++));((ii++))
 if [[ $ii == 10 ]];then ii=0;fi
 done
}

function print_matrix()
{
 clear
 x=0;y=0
 height=1
 draw_line "╔" "═" "╤" "╗" 10
 draw_line "╔" "═" "╤" "╗\n" 10
 while [[ $height -le 10 ]]
 do
 width=1
  echo -ne "${C0}║"
  while [[ $width -le 10 ]]
  do
   echo -ne ${USR_X[x]}"${USR_F[x]}"${n}${C0}
   ((x++))
   [[ $width -lt 10 ]]&&echo -ne "│"||echo -ne "║║"
   ((width++))
  done
  width=1
  while [[ $width -le 10 ]]
  do
   echo -ne ${CPU_X[y]}"${CPU_F[y]}"${n}${C0}
   ((y++))
   [[ $width -lt 10 ]]&&echo -ne "│"||echo -ne "║\n"
   ((width++))
  done
  if [[ $height -lt 10 ]]
  then draw_line "╟" "─" "┼" "╢" 10;draw_line "╟" "─" "┼" "╢\n" 10
  else draw_line "╚" "═" "╧" "╝" 10;draw_line "╚" "═" "╧" "╝\n" 10
  fi
  ((height++))
 done
 }

function place_vessel()
{
 gonot=$1[@]
 posit=$2[@]
 g=("${!gonot}")
 p=("${!posit}")
 i=0
 while [[ $i -lt $3 ]]
 do
  ORIENTATION=$((RANDOM % 2))
  if [[ $ORIENTATION == 0 ]];then next=1;anext=10;else next=10;anext=1;fi
  sq=$((RANDOM % 100))
  if [[ ${p[sq]} -le $((10-$4)) ]]
  then
   check=0
    if [[ ${g[sq]} != 0 ]];then ((check++));fi
    if [[ ${g[sq+1]} != 0 ]];then ((check++));fi
    if [[ ${g[sq+10]} != 0 ]];then ((check++));fi
    if [[ ${g[sq-1]} != 0 ]];then ((check++));fi
    if [[ ${g[sq-10]} != 0 ]];then ((check++));fi
   ii=1
   while [[ $ii -lt $4 ]]
   do
    if [[ ${g[sq+ii*next]} != 0 ]];then ((check++));fi
    if [[ ${g[sq+ii*next+anext]} != 0 ]];then ((check++));fi
    if [[ ${g[sq+ii*next-anext]} != 0 ]];then ((check++));fi
    if [[ $ii -eq $(($4-1)) ]]&&[[ ${g[sq+ii*next+next]} != 0 ]];then ((check++));fi
    ((ii++))
   done
   if [[ $check == 0 ]]
   then
    ii=0
    while [[ $ii -lt $4 ]]
    do
     g[sq+ii*next]=$4
     ((ii++))
    done
    ((i++))
   fi
  fi
 done
 echo ${g[@]}
}

function get_sq_color()
{
  case  $1 in
   0|.)echo ${C5};
   ;;
   1)echo ${C1};
   ;;
   2)echo ${C2};
   ;;
   3)echo ${C4};
   ;;
   4)echo ${C6};
   ;;
  esac
}

function man_place()
{
 check=0
 i=0
 while [[ $i -lt $2 ]]
 do
  if [[ ${USR_F[CURSOR+i]} != *"░░░"* ]];then check=1;fi
  #adjacent squares hid ships?
  if [[ $((CURSOR+i*STEP)) -gt 9 ]]&&[[ "${USR_F[CURSOR+i*STEP-10]}" != *"░░░"* ]];then check=1;fi
  if [[ $((CURSOR+i*STEP)) -le 89 ]]&&[[ "${USR_F[CURSOR+i*STEP+10]}" != *"░░░"* ]];then check=1;fi
  if [[ "${USR_P[CURSOR+i*STEP]}" != 9 ]]&&[[ "${USR_F[CURSOR+i*STEP+1]}" != *"░░░"* ]];then check=1;fi
  if [[ "${USR_P[CURSOR+i*STEP]}" != 0 ]]&&[[ "${USR_F[CURSOR+i*STEP-1]}" != *"░░░"* ]];then check=1;fi
  ((i++))
 done
 if [[ $STEP == 1 ]]&&[[ $((${USR_P[CURSOR]}+$2-1)) -gt 9 ]];then check=1;fi
 if [[ $STEP == 10 ]]&&[[ $((CURSOR+$2*10-10)) -gt 99 ]];then check=1;fi
 if [[ $check == 0 ]]
 then
  i=0
  while [[ $i -lt $(($2*STEP)) ]]
  do
   USR_G[CURSOR+i]="$2"
   USR_F[CURSOR+i]=" "$2" "
   USR_X[CURSOR+i]=$(get_sq_color ${USR_G[CURSOR+i]})
   i=$((i+STEP))
  done
  USR_F[CURSOR]="${I}""${USR_F[CURSOR]}"
  ((PICKED$2++))
 else
 echo -e "${C5}This placement is not possible.\n${C0}Hit any key to return.${n}";read -sn 1 ggg;
 fi
}

function placing_dialog()
{
 echo -e "${C2}Which type of vessel do you want to place\nstarting from the selected square?   Hit:"
 [[ $((CARRIERS-PICKED4)) -gt 0 ]]&&echo -e "      ${I}${C6} 4 ${n}${C6} for Carrier    (4444) horizontal ($((CARRIERS-PICKED4)) available)"
 [[ $((CARRIERS-PICKED4)) -gt 0 ]]&&echo -e "${I}${C6}shift${n}${C6}+${I}${C6} 4 ${n}${C6} for Carrier    (4444) vertical   ($((CARRIERS-PICKED4)) available)"
 [[ $((BATTLESHIPS-PICKED3)) -gt 0 ]]&&echo -e "      ${I}${C4} 3 ${n}${C4} for Battleship (333)  horizontal ($((BATTLESHIPS-PICKED3)) available)"
 [[ $((BATTLESHIPS-PICKED3)) -gt 0 ]]&&echo -e "${I}${C4}shift${n}${C4}+${I}${C4} 3 ${n}${C4} for Battleship (333)  vertical   ($((BATTLESHIPS-PICKED3)) available)"
 [[ $((CRUISERS-PICKED2)) -gt 0 ]]&&echo -e "      ${I}${C2} 2 ${n}${C2} for Cruiser    (22)   horizontal ($((CRUISERS-PICKED2)) available)"
 [[ $((CRUISERS-PICKED2)) -gt 0 ]]&&echo -e "${I}${C2}shift${n}${C2}+${I}${C2} 2 ${n}${C2} for Cruiser    (22)   vertical   ($((CRUISERS-PICKED2)) available)"
 [[ $((DESTROYERS-PICKED1)) -gt 0 ]]&&echo -e "      ${I}${C1} 1 ${n}${C1} for Destroyer  (1)               ($((DESTROYERS-PICKED1)) available)${n}"
 echo -e "      ${I}${C6} r ${n}${C6} to Restart${n}"
 echo -e "      ${I}${C3} m ${n}${C3} to Go to Main Menu${n}"
 read -sN 1 bbb
 case $bbb in
 "4")if [[ $PICKED4 -lt $CARRIERS ]];then STEP=1;man_place $CURSOR 4 $PICKED4;else echo -e "${C5}You have already placed all the available Carriers.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 "$")if [[ $PICKED4 -lt $CARRIERS ]];then STEP=10;man_place $CURSOR 4 $PICKED4;else echo -e "${C5}You have already placed all the available Carriers.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 "3")if [[ $PICKED3 -lt $BATTLESHIPS ]];then STEP=1;man_place $CURSOR 3;else echo -e "${C5}You have already placed all the available Battleships.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 "#")if [[ $PICKED3 -lt $BATTLESHIPS ]];then STEP=10;man_place $CURSOR 3;else echo -e "${C5}You have already placed all the available Battleships.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 "2")if [[ $PICKED2 -lt $CRUISERS ]];then STEP=1;man_place $CURSOR 2;else echo -e "${C5}You have already placed all the available Cruisers.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 "@")if [[ $PICKED2 -lt $CRUISERS ]];then STEP=10;man_place $CURSOR 2;else echo -e "${C5}You have already placed all the available Cruisers.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 "1")if [[ $PICKED1 -lt $DESTROYERS ]];then STEP=1;man_place $CURSOR 1;else echo -e "${C5}You have already placed all the available Destroyers.${C0}\nHit any key to return.${n}";read -sn 1 ggg;fi
 ;;
 *)clear
 esac
 if [[ $PICKED1 == $DESTROYERS ]]&&[[ $PICKED2 == $CRUISERS ]]&&[[ $PICKED3 == $BATTLESHIPS ]]&&[[ $PICKED4 == $CARRIERS ]];then db3="M";fi
}

function print_manual()
{
 clear
 x=0;y=0
 height=1
 draw_line "╔" "═" "╤" "╗\n" 10
 while [[ $height -le 10 ]]
 do
 width=1
  echo -ne "${C0}║"
  while [[ $width -le 10 ]]
  do
   echo -ne ${USR_X[x]}"${USR_F[x]}"${n}${C0}
   ((x++))
   [[ $width -lt 10 ]]&&echo -ne "│"||echo -ne "║\n"
   ((width++))
  done

  if [[ $height -lt 10 ]]
  then draw_line "╟" "─" "┼" "╢\n" 10
  else draw_line "╚" "═" "╧" "╝\n" 10
  fi
  ((height++))
 done
}

function manual_populate()
{
 load_grids
 PICKED4=0
 PICKED3=0
 PICKED2=0
 PICKED1=0
 db3="";
 CURSOR="0"
 USR_F[0]="${I}"${USR_F[0]}
 while [[ "$db3" != "M" ]]
 do
 print_manual
 echo -e "${C0}╭──────────────────────╮\n│${C4} $CHEAT_NAV/arrow keys ${C2}Move ${C0}│\n├──────────────────────┤\n│${C4} $HIT_BIND/space/enter ${n}${C2} Place ${C0}│\n├──────────────────────┤\n│${C4} r ${C2}           Restart ${C0}│\n├──────────────────────┤\n│${C4} p ${C2}     Auto Populate ${C0}│\n├──────────────────────┤\n│${C4} q          ${n}${C2}Main Menu ${C0}│\n╰──────────────────────╯\n"
  [[ "$db3" != "M" ]]&&read -sn 1 db3
  [[ $(echo "$db3" | od) = "$spacebar" ]]&&db3=$HIT_BIND
  case $db3 in
   $NAV_UP|A) if  [[ $CURSOR -ge 10 ]]; then NEW_CURSOR=$((CURSOR-10));mv_usr_cursor;fi;
   ;;
   $NAV_DOWN|B) if  [[ $CURSOR -lt 90 ]]; then NEW_CURSOR=$((CURSOR+10));mv_usr_cursor;fi;
   ;;
   $NAV_RIGHT|C) if  [[ ${USR_P[CURSOR]} !=  9 ]]; then NEW_CURSOR=$((CURSOR+1));mv_usr_cursor;fi;
   ;;
   $NAV_LEFT|D) if  [[ ${USR_P[CURSOR]} != 0 ]]; then NEW_CURSOR=$((CURSOR-1));mv_usr_cursor;fi;
   ;;
   $HIT_BIND)[[ ${USR_F[CURSOR]} == *"░░░"* ]]&&clear&&print_manual&&placing_dialog;
   ;;
   p|P)db3="M";switch_populate=1;
   ;;
   r|R)db3="M";manual_populate;
   ;;
   q|Q)db3="M";db="M";clear;
   ;;
   *)
  esac
 done

}
function populate()
{

 if [[ $PLACE_SHIPS == 'auto' ]]
 then
  for z in  "$CARRIERS 4" "$BATTLESHIPS 3" "$CRUISERS 2" "$DESTROYERS 1"
  do
   USR_G=($(place_vessel USR_G USR_P $z))
  done
 else manual_populate
 fi
 # update_usr_fgrid
 for i in {0..99}
 do
  [[ ${USR_G[i]} != 0 ]]&&USR_F[i]=" ""${USR_G[i]}"" "
  USR_X[i]=$(get_sq_color ${USR_G[i]})
 done
 for z in  "$CARRIERS 4" "$BATTLESHIPS 3" "$CRUISERS 2" "$DESTROYERS 1"
 do
  CPU_G=($(place_vessel CPU_G CPU_P $z))
 done

}

function mv_usr_cursor ()
{
 USR_F[CURSOR]=${USR_F[CURSOR]:5}
 USR_F[NEW_CURSOR]="${I}${USR_F[NEW_CURSOR]}"
 CURSOR="$NEW_CURSOR"
}

function mv_cursor ()
{
 CPU_F[CURSOR]=${CPU_F[CURSOR]:5}
 CPU_F[NEW_CURSOR]="${I}${CPU_F[NEW_CURSOR]}"
 CURSOR="$NEW_CURSOR"
}

function lose_game()
{
 print_matrix
 echo -e "                                     ${J}${C3}A SAD DAY!${n}\n             ${C1}The computer bombed and sank all your ships in $CPU_TRIES tries.${n}"
 [[ $NOTIFICATION_TOGGLE == "yes" ]]&&notify-send -t 5000 -i  "$SHARE_DIR/tui-battleship-$PREFERRED_PNG.png" "You were DEFEATED after $CPU_TRIES tries."
 sleep 5
  echo -e "                     ${C0}Press any key to return to the main menu${n}";read -sn 1 vw;db="M";clear;
}

function win_game()
{
 clear
 print_matrix
 if [[ $(cat "$SHARE_DIR/hiscores.txt"|wc -l) -lt 1 ]]
 then
  TENTH=100 #avoid first time error
 else
  TENTH="$(sort -h "$SHARE_DIR/hiscores.txt"|head -10|tail -1|awk '{print $1}')"
 fi
 SCORELINE="$USR_TRIES $(date +%Y-%m-%d\ %T) "
 echo -e "                               ${J}${C3}MISSION ACCOMPLISHED!!!${n}\n                        ${C1}You bombed all enemy ships in $USR_TRIES tries.${n}"
 [[ $NOTIFICATION_TOGGLE == "yes" ]]&&notify-send -t 5000 -i  "$SHARE_DIR/tui-battleship-$PREFERRED_PNG.png" "VICTORY in $USR_TRIES tries!"
 if [ "$USR_TRIES" -lt "$TENTH" ]||[[ "$(cat "$SHARE_DIR/hiscores.txt"|wc -l)" -lt 10 ]]
 then
  echo $SCORELINE>>"$SHARE_DIR/hiscores.txt"
  echo -e "                          ${C1}That's right, you made it to the${n}"
  show_hiscores
 fi
 sleep 5
 echo -e "                     ${C0}Press any key to return to the main menu${n}";read -sn 1 vw;db="M";clear;
}

function new_game()
{
 USR_HITS=0
 USR_TRIES=0
 CPU_HITS=0
 CPU_TRIES=0
 FOLLOW=0
 load_grids
 populate
 if [[ $switch_populate == 1 ]];then PLACE_SHIPS='auto';load_grids;populate;PLACE_SHIPS=manual;switch_populate='';fi
  echo -e "                        ${C0}┏━━━┯━━━┯━━━┓\n                        ${C0}┃ ${C2}T ${C0}│${C2} U ${C0}│${C2} I ${C0}┃\n                        ${C0}┗━━━╅───┼───╄━━━┯━━━┯━━━┯━━━┓\n                            ${C0}┃ ${C2}B ${C0}│${C2} A ${C0}│${C2} T ${C0}│${C2} T ${C0}│${C6} L ${C0}│${C6} E ${C0}┃\n                        ${C0}    ┗━━━┷━━━┷━━━╅───┼───┼───╄━━━┓\n                           ${C6}GOOD LUCK!${C0}   ┃${C2} S ${C0}│${C2} H ${C0}${C0}│${C6} I ${C0}│${C6} P ${C0}┃\n                                       ${C0} ┗━━━┷━━━┷━━━┷━━━┛ ">$SHARE_DIR/tui-battleship.log
}

function cpu_miss()
{
 echo -e "                    ${C4}Computer missed.            Hits:$CPU_HITS/$TOTAL Tries:$CPU_TRIES${n}">>$SHARE_DIR/tui-battleship.log
 USR_F[$1]=" . "
 USR_X[$1]=${C5}
 print_matrix
 load_cheat
 [[ $LOG_TOGGLE == 'yes' ]]&&tail "$SHARE_DIR/tui-battleship.log"
}

function cpu_hit()
{
 USR_F[$1]=" X "
 USR_X[$1]=${C3}
 ((CPU_HITS++))
 echo -e "                    ${C3}Computer hit a ship.        Hits:$CPU_HITS/$TOTAL Tries:$CPU_TRIES${n}">>$SHARE_DIR/tui-battleship.log
 if [[ ${USR_G[$1]} == "1" ]];then echo -e "                    ${C3}${I}COMPUTER SANK YOUR DESTROYER (1).${n}">>$SHARE_DIR/tui-battleship.log;else((SHIP_HITS++));fi
 print_matrix
 load_cheat
 [[ $LOG_TOGGLE == 'yes' ]]&&tail "$SHARE_DIR/tui-battleship.log"
# sleep 1
 cpu_play
}

function sink_ship()
{
 case $FOLLOW in
 2)ship="CRUISER (22)";
 ;;
 3)ship="BATTLESHIP (333)"
 ;;
 4)ship="CARRIER (4444)"
 ;;
 esac
 echo -e "                    ${C3}${I}COMPUTER SANK YOUR $ship.${n}">>$SHARE_DIR/tui-battleship.log
 FOLLOW=0
 SHIP_HITS=0
 SQ0=0
}

function hit_South()
{
 x=$1
 if [[ $SHIP_HITS -lt $FOLLOW ]]
 then
  if [[ ${USR_F[x]} = " X " ]]&&[[ $x -le 89 ]];then hit_South $(($x+10))
  elif [[ ${USR_F[x]} = " X " ]]&&[[ $x -gt 89 ]];then hit_East $SQ0
  elif [[ ${USR_F[x]} = " . " ]]||[[ $x -gt 99 ]];then hit_East $SQ0
  else cpu_open_sq $x
  fi
 else
  sink_ship
  cpu_play
 fi
}

function hit_North()
{
 x=$1
 if [[ $SHIP_HITS -lt $FOLLOW ]]
 then
   if [[ ${USR_F[$x]} = " X " ]]&&[[ $x -gt 9 ]];then hit_North $(($x-10))
   elif [[ ${USR_F[$x]} = " X " ]]&&[[ $x -le 9 ]];then hit_South $SQ0
   elif [[ ${USR_F[$x]} = " . " ]]||[[ $x -lt 0 ]];then hit_South $SQ0
   else cpu_open_sq $x;fi
 else
  sink_ship
  cpu_play
 fi
}

function hit_West()
{
 x=$1
 if [[ $SHIP_HITS -lt $FOLLOW ]]
 then
   if [[ ${USR_F[$x]} = " X " ]]&&[[ ${USR_P[x]} != 0 ]];then hit_West $(($x-1))
   elif [[ ${USR_F[$x]} = " X " ]]&&[[ ${USR_P[x]} == 0 ]];then hit_North $SQ0
   elif [[ ${USR_F[$x]} = " . " ]]||[[ ${USR_P[x]} -lt 0 ]];then hit_North $SQ0
   else cpu_open_sq $x;fi
 else
  sink_ship
  cpu_play
 fi
}

function hit_East()
{
 x=$1
 if [[ $SHIP_HITS -lt $FOLLOW ]]
 then
   if [[ ${USR_F[x]} = " X " ]]&&[[ ${USR_P[x]} != 9 ]];then hit_East $(($x+1))
   elif [[ ${USR_F[x]} = " X " ]]&&[[ ${USR_P[x]} == 9 ]];then hit_West $SQ0
   elif [[ ${USR_F[x]} = " . " ]];then hit_West $SQ0
   else cpu_open_sq $x;fi
 else
  sink_ship
  cpu_play
 fi
}

function cpu_open_sq()
{
 ((CPU_TRIES++))
 if [[ ${USR_F[$1]} == *"░░░"* ]]
 then
  cpu_miss $1
 else
  cpu_hit $1
 fi
}

function cpu_play()
{
 if [[ $CPU_HITS == $TOTAL ]]
 then
  lose_game
  else
  if [[ $FOLLOW == 0 ]]
  then
   place=1
   while [[ $place == 1 ]]
   do
    SQ=$((RANDOM % 100))
    place=0
    [[ ${USR_F[SQ]} == *" . "* ]]&&place=1
    [[ ${USR_F[SQ]} == *" X "* ]]&&place=1
    if [[ ${USR_P[SQ]} != 0 ]]&&[[ ${USR_F[SQ-1]} == *" X "* ]];then place=1;fi
    if [[ ${USR_P[SQ]} != 9 ]]&&[[ ${USR_F[SQ+1]} == *" X "* ]];then place=1;fi
    if [[ $SQ -gt 9 ]]&&[[ ${USR_F[SQ-10]} == *" X "* ]];then place=1;fi
    if [[ $SQ -le 89 ]]&&[[ ${USR_F[SQ+10]} == *" X "* ]];then place=1;fi
   done
   if [[ ${USR_G[SQ]} -gt 1 ]];then FOLLOW=${USR_G[SQ]};SHIP_HITS=0;SQ0=$SQ;fi
   cpu_open_sq $SQ
  else
   hit_East $SQ0
  fi
 fi
}

function open_sq()
{
 ((USR_TRIES++))
 CPU_F[CURSOR]=${I}" "${CPU_G[CURSOR]/0/.}" "
 CPU_X[CURSOR]=$(get_sq_color ${CPU_G[CURSOR]})
 if [[ ${CPU_G[CURSOR]} != 0 ]]
 then
  ((USR_HITS++))
   echo -e "                    ${C2}You hit a ship.             Hits:$USR_HITS/$TOTAL Tries:$USR_TRIES${n}">>$SHARE_DIR/tui-battleship.log
  print_matrix
  load_cheat
  [[ $LOG_TOGGLE == 'yes' ]]&&tail "$SHARE_DIR/tui-battleship.log"
  [[ $USR_HITS == $TOTAL ]]&&win_game
 else
  echo -e "                    ${C2}You missed.                 Hits:$USR_HITS/$TOTAL Tries:$USR_TRIES${n}">>$SHARE_DIR/tui-battleship.log
  print_matrix
  load_cheat
  [[ $LOG_TOGGLE == 'yes' ]]&&tail "$SHARE_DIR/tui-battleship.log"
  cpu_play
 fi
}

function play_menu ()
{
 CURSOR="0"
 CPU_F[0]="${I}"${CPU_F[0]}
 while [[ "$db" != "M" ]]
 do
  print_matrix
  load_cheat
  [[ $LOG_TOGGLE == 'yes' ]]&&tail "$SHARE_DIR/tui-battleship.log"
  [[ "$db" != "M" ]]&&read -sn 1 db
  [[ $(echo "$db" | od) = "$spacebar" ]]&&db=$HIT_BIND
  case $db in
   $NAV_UP|A) if  [[ $CURSOR -ge 10 ]]; then NEW_CURSOR=$((CURSOR-10));mv_cursor;fi;
   ;;
   $NAV_DOWN|B) if  [[ $CURSOR -lt 90 ]]; then NEW_CURSOR=$((CURSOR+10));mv_cursor;fi;
   ;;
   $NAV_RIGHT|C) if  [[ ${CPU_P[CURSOR]} !=  9 ]]; then NEW_CURSOR=$((CURSOR+1));mv_cursor;fi;
   ;;
   $NAV_LEFT|D) if  [[ ${CPU_P[CURSOR]} != 0 ]]; then NEW_CURSOR=$((CURSOR-1));mv_cursor;fi;
   ;;
   q|Q)[[ $NOTIFICATION_TOGGLE == "yes" ]]&&notify-send -t 5000 -i  "$SHARE_DIR/tui-battleship-$PREFERRED_PNG.png" "Quitting game...";clear;db="M";
   ;;
   I|i) if [[ $CHEATSHEET_TOGGLE == yes ]];then CHEATSHEET_TOGGLE="no";else CHEATSHEET_TOGGLE="yes";fi;
   ;;
   U|u) if [[ $LOG_TOGGLE == yes ]];then LOG_TOGGLE="no";else LOG_TOGGLE="yes";fi;
   ;;
   $HIT_BIND)[[ ${CPU_F[CURSOR]} == *"░░░"* ]]&&open_sq;
   ;;
   r|R)db="M";new_game;db="";play_menu;
   ;;
   *)
  esac
 done
}

function instructions()
{
echo -e "${I}${C6}TUI-BATTLESHIP\n${n}${C6}This is a tui implementation of the popular pen &paper guessing game.\nThe objective of the game is to destroy the computer's fleet,\nbefore the computer achieves the same against you.\nYou take turns with the computer, hitting squares in each other's grids.\nYou have to guess the position of the enemy ships on the\ncomputer's 10x10 grid, in order to win.\nYou lose if the computer achieves sinking your ships first.\n\nYou can move on the enemy grid using the ${C4}$CHEAT_NAV or the arrow keys.${C6}\nYou can hit the square you moved in using the ${C4}$HIT_BIND,space or enter keys.\n${C6}You can configure the positioning of your ships to be either\n${C4}automatic${C6} or ${C4}manual${C6}, through selecting the ${C4}e option in the main menu.\n${C6}In this variation of the game,\n${I}it is not allowed for the player's ships to be adjacent to each other.${n}\n\n${C6}You can also configure:\nthe ${C4}number of each sort of ship${C6} in the grid,\nthe ${C4}navigation keys${C6},\nthe ${C4}hit key${C6} (space and enter are also hardcoded),\nthe preferred ${C4}image${C6} to show in the notifications,\nwhether ${C4}notifications${C6} are shown,\nwhether the keybinding ${C4}cheatsheet${C6} is shown,\nwhether the ${C4}game log${C6} is shown,\nthe preferred ${C4}text editor${C6} to use within the game. \n\nMore details on the original game and its\nother variations in this wikipedia page:\nhttps://en.wikipedia.org/wiki/Battleship_(game)\n${C0}Hit any key to return.${n}";read -sn 1 ggg
}

function main_menu ()
{
clear
 mm=""
 while [[ "$mm" != "q" ]]
 do
  echo -e "                      ${C0}┏━━━┯━━━┯━━━┓"
  echo -e "                      ${C0}┃${I}${C5} T ${n}${C0}│${I}${C5} U ${n}${C0}│${I}${C5} I ${n}${C0}┃"
  echo -e "                      ${C0}┗━━━╅───┼───╄━━━┯━━━┯━━━┯━━━┓"
  echo -e "                      ${C0}    ┃${I}${C5} B ${n}${C0}│${I}${C5} A ${n}${C0}│${I}${C5} T ${n}${C0}│${I}${C5} T ${n}${C0}│${I}${C5} L ${n}${C0}│${I}${C5} E ${n}${C0}┃"
  echo -e "                      ${C0}    ┗━━━┷━━━┷━━━┷━━━╅───┼───╄━━━┯━━━┓"
  echo -e "                      ${C0}                    ┃${I}${C5} S ${n}${C0}│${I}${C5} H ${n}${C0}${n}${C0}│${I}${C5} I ${n}${C0}│${I}${C5} P ${n}${C0}┃"
  echo -e "                      ${C0}                    ┗━━━┷━━━┷━━━┷━━━┛"
  echo -e "                      ${C0}┏━━━┯━━━┯━━━┯━━━┯━━━┓╭──────────────╮"
  echo -e "                      ${C0}┃${C3} X ${C0}│${C5}░░░${C0}│${C5}░░░${C0}│${C5}░░░${C0}│${C1} 1 ${C0}┃│${C4} n   ${n}${C2} New Game${C0}│"
  echo -e "                      ${C0}┠───┼───┼───┼───┼───┨├──────────────┤"
  echo -e "                      ${C0}┃${C3} X ${C0}│${C5}░░░${C0}│${C2} 2 ${C0}│${C2} 2 ${C0}│${C5}░░░${C0}┃│${C4} e  ${n}${C2} Configure${C0}│"
  echo -e "                      ${C0}┠───┼───┼───┼───┼───┨├──────────────┤"
  echo -e "                      ${C0}┃${C6} 4 ${n}${C0}│${C5}░░░${C0}│${C5}░░░${C0}│${C5}░░░${C0}│${C4} 3 ${C0}┃│${C4} s  ${n}${C2}Show Stats${C0}│"
  echo -e "                      ${C0}┠───┼───┼───┼───┼───┨├──────────────┤"
  echo -e "                      ${C0}┃${C6} 4 ${n}${C0}│${C5}░░░${C0}│${C5}░░░${C0}│${C5}░░░${C0}│${C4} 3 ${C0}┃│${C4} r  ${n}${C2}Show Rules${C0}│"
  echo -e "                      ${C0}┠───┼───┼───┼───┼───┨├──────────────┤"
  echo -e "                      ${C0}┃${C5}░░░${n}${C0}│${C5}░░░${C0}│${C1} 1 ${C0}│${C5}░░░${C0}│${C4} 3 ${C0}┃│${C4} q      ${n}${C2}  Exit${C0}│"
  echo -e "                      ${C0}┗━━━┷━━━┷━━━┷━━━┷━━━┛╰──────────────╯${n}"
  read -sn 1 mm
  case $mm in
   n|N)db="";new_game;play_menu;
   ;;
   e|E) clear;[[ $NOTIFICATION_TOGGLE == "yes" ]]&&notify-send -t 5000 -i "$SHARE_DIR/tui-battleship-$PREFERRED_PNG.png" "Editing tui-battleship configuration file" &eval $PREFERRED_EDITOR $CONFIG_FILE;tput civis;load_config
   ;;
   r|R)clear;instructions;clear;
   ;;
   s|S)clear;show_hiscores;echo -e "\n                           ${C0}Press any key to return${n}";read -sN 1 v;clear;
   ;;
   q|Q)clear;[[ $NOTIFICATION_TOGGLE == "yes" ]]&&notify-send -t 5000 -i  "$SHARE_DIR/tui-battleship-$PREFERRED_PNG.png" "Exited tui-battleship.";
   ;;
   *)clear;
  esac
 done
}

function cursor_reappear() {
tput cnorm
exit
}
######################
trap cursor_reappear HUP INT QUIT TERM EXIT ABRT
tput civis # make cursor invisible
spacebar=$(cat << eof
0000000 000012
0000001
eof
)
I="\e[7m" #invert
J="\e[5m" #blink
n="\e[m" #reset
CONFIG_FILE="$HOME/.config/tui-battleship/tui-battleship.config"
SHARE_DIR="$HOME/.local/share/tui-battleship"
############## GAME ####################
load_config
main_menu
