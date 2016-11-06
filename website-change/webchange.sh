#!/bin/bash

# VARIABLES
LOG_FILE=$PWD"/log.txt"
URL="http://www.full-url.com/here"

# EMAIL RELATED VARIABLES
EMAIL_RECIPIENTS="to@example.com"
EMAIL_SENDER="from@example.com"
EMAIL_CHANGE_SUBJECT="UPDATED PAGE!!"
EMAIL_FILE=$PWD"/update.email"

# WRITE HEADER TO LOG FILE
echo "=================================" 								> $LOG_FILE
echo " Check for update to web page $URL"		 						>> $LOG_FILE
echo " " 																>> $LOG_FILE
echo " Starting at `eval date +%c`" 									>> $LOG_FILE
echo "=================================" 								>> $LOG_FILE

# 	MOVE LATEST FILE TO OLD FILE
mv -v $PWD/latest.html $PWD/old.html									>> $LOG_FILE 2>> $LOG_FILE
rm -v $PWD/diff.output                              		            >> $LOG_FILE 2>> $LOG_FILE

# RETRIEVE THE LATEST WEB PAGE
echo "Retrieving page from $URL"										>> $LOG_FILE
wget --output-document=$PWD/latest.html --append-output=$LOG_FILE $URL

# COMPARE THE NEWEST ONE TO THE OLDEST ONE
echo "Comparing latest file to the older one"							>> $LOG_FILE
diff $PWD/latest.html $PWD/old.html | tee -a  $LOG_FILE $PWD/diff.output
DIFF_SIZE=$(stat -c %s $PWD/diff.output)

# CONSTRUCT EMAIL TO SEND
echo "To: $EMAIL_RECIPIENTS"											>$EMAIL_FILE
echo "From: $EMAIL_SENDER"												>>$EMAIL_FILE
echo "Subject: $EMAIL_CHANGE_SUBJECT"									>>$EMAIL_FILE
echo " "																>>$EMAIL_FILE
cat $LOG_FILE															>>$EMAIL_FILE

if [ "$DIFF_SIZE" = "0" ]; then
	echo "No change to website"											>> $LOG_FILE
else
	echo "Website has changed!!"										>> $LOG_FILE
	# SEND EMAIL
	cat $EMAIL_FILE | msmtp -a default $EMAIL_RECIPIENTS
fi
