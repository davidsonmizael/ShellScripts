#!/bin/bash
####################################################
#Made by Davidson Mizael
#Last update: 11/25/2016
####################################################
#             /`\
#            / : |
#   _.._     | '/
# /`    \    | /
#|  .-._ '-"` ( ""
#|_/   /   -  -\      só por deus
#      |_____y__)
#       \      /
#       / ---<`
##########SERVERS
SERVERS=("server1" "server2" "server3")
LOG="/tmp/checkgetlogs.log"
touch $LOG
MSG=0

function main() {
  echo "Run: $(date +"%Y-%m-%d %H:%M:%S")" >> $LOG
  printPIDs
  if [ $MSG == 1 ]; then
    cat $LOG | mail -s "[REPORT] GetLogs STATUS" mail@mail.com
  fi
}

function printPIDs() {
  for sv in "${SERVERS[@]}";do
    echo "-------" >> $LOG
    result=($(ssh -q -t user@$sv ps -eo %cpu,%mem,pid,cmd | grep getlogs.jar | grep -v grep | awk '{print $1","$2","$3","$7}'))
    if [ ! -z "$result" ]; then
      CPU=$(echo $result | cut -d',' -f1) >> $LOG
      MEM=$(echo $result | cut -d',' -f2) >> $LOG
      PID=$(echo $result | cut -d',' -f3) >> $LOG
      ENV=$(echo $result | cut -d',' -f4) >> $LOG

      for i in "${result[@]}"; do
        echo -e "Server:\t\t$sv" >> $LOG
        echo -e "Process:\t$PID " >> $LOG
        echo -e "Environment:\t$ENV" >> $LOG
        echo -e "CPU usage:\t$CPU" >> $LOG
        echo -e "MEM usage:\t$MEM" >> $LOG
        printLogStatus $sv
      done
    else
      echo "No process found for server $sv" >> $LOG
      MSG=1
    fi
  done
}

function printLogStatus() {
  #$1 server
  result="$(ssh -q -t user@$1 stat /tmp/getlogs.log -c"%y-%s" | tr -d "\r")"
  size=${result##*-}
  date=${result%-*}
  date=$(date -d "$date" +"%Y%m%d")
  datetoday=$(date +"%Y%m%d")
  if [ $size -ge 10000000 ]; then
    echo "Log file size = $size. Please check ASAP" >> $LOG
    MSG=1
  fi
  if [ $date -ge $datetoday ]; then
    error=$(ssh -q -t user@$1 tail -1 /tmp/getlogs.log) >> $LOG
    #daily error message after database reset
    #last message after program starts
    if ! [[ $error == *"Connected to the database successfully."* || $error == *"Starting threads..."* ]]; then
      echo "There are errors for today. Please see below." >> $LOG
      echo $error >> $LOG
      MSG=1
    else
      echo "Last log on file was at: $(date -d $date +"%m-%d-%Y")" >> $LOG
    fi
  else
    echo "Last log on file was at: $(date -d $date +"%m-%d-%Y")" >> $LOG
  fi
}

#executes the main
main

if [ -s $LOG ];then
  rm -rf $LOG
fi
