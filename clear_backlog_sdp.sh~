# clear_backlog_sdp.sh
#!/bin/bash
#Created by Prashant Gupta based on the Inputs from Mohamed Fahim

#Checks the number of Inputs
if [[ $# != 2 ]]; then
  echo "Usage: Clear_Backlog <Threshold Value> <Number of Files to Move>"
  exit
fi

SOURCE_DIR="/var/DWS/bkp/SDP"
INCOMING_DIR="/var/DWS/incoming/CS40/SDP"
TARGET_DIR="/var/DWS/processing/CS40/SDP"

THRESHOLD=$1
SLEEP_TIME_IF_FULL=10
SLEEP_TIME_AFTER_MOVE=60
NUM_OF_FILES_TO_MOVE=$2

#Searching for Source Directory for Files
while [ `find $SOURCE_DIR -type f | wc -l` -gt 0 ]
do

NO_OF_TARGET=`find $TARGET_DIR -type f -name *SDPOUTPUTCDR* | wc -l`

#Comparing the Target Directory with Threshold
if [ $NO_OF_TARGET -lt $THRESHOLD ]; then
echo `date +%d/%m/%y-%H:%M:%S`":: Number of Files in Target Directory is Less than Threshold "$THRESHOLD" - Moving Files from Source directory for processing>>>" >> $0.log

#Moving files to Incoming Directory
for file in `find $SOURCE_DIR -type f -name SDPOUTPUTCDR* -print | tail -$NUM_OF_FILES_TO_MOVE`
do
echo `date +%d/%m/%y-%H:%M:%S`":: Moving" $file  >> $0.log
mv $file $INCOMING_DIR
done
echo `date +%d/%m/%y-%H:%M:%S`":: Waiting for more files to come..." >> $0.log

#Files moved waiting for more
sleep $SLEEP_TIME_AFTER_MOVE
else

#Target Directory is full waiting for files to process
echo `date +%d/%m/%y-%H:%M:%S`":: Processing "$NO_OF_TARGET" files - More than Threshold "$THRESHOLD >> $0.log
echo `date +%d/%m/%y-%H:%M:%S`":: Still Full, Waiting for "$SLEEP_TIME_IF_FULL" seconds..." >> $0.log
sleep $SLEEP_TIME_IF_FULL
fi
done
echo "No Files left in Source Directory, Exiting now..."
echo `date +%d/%m/%y-%H:%M:%S`":: No Files left in Source Directory, Exiting now..." >> $0.log
