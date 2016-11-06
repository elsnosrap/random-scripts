#!/bin/bash

# Verify user supplied one performance definition file
if [[ -z "$1" ]]; then
	echo "Please supply a performance definition file"
	exit;
fi

# Get list of all directories, only searching for ones that start with login_test_
ALL_DIRS=($(find "$PWD" -type d -name "login_test_*" | sort))
NUM_DIRS=${#ALL_DIRS[@]}

# Go through all trace log files
for (( i=0; i<$NUM_DIRS; i++)); do

	# Reset our output line
	MYLINE=""
	
	# Parse through the performance definition file
	while read line
	do
		# Check for a commented-out line
		COMMENT_CHAR=${line:0:1}
		if [[ "$COMMENT_CHAR" == "#" ]]; then
			continue
		fi
		
		# Extract the test's name, its starting text, and its ending text
		TEST_NAME=$(echo $line | cut -d ^ -f 1)
		START_TEXT=$(echo $line | cut -d ^ -f 2)
		END_TEXT=$(echo $line | cut -d ^ -f 3)
		
		# Change the internal field separator to only be end line characters
		# Otherwise, when we search for start and end text, they will be returned as an array separated by spaces
		OLD_IFS=$IFS
		IFS=$'\n'
		
		# Get all start entries
		START_ENTRIES=($(cat ${ALL_DIRS[$i]}/clean_trace.txt | egrep "$START_TEXT"))
		
		# Get all end entries
		END_ENTRIES=($(cat ${ALL_DIRS[$i]}/clean_trace.txt | egrep "$END_TEXT"))
		NUM_END_ENTRIES=${#END_ENTRIES[@]}
		
		# Make sure we found the start and end entries before continuing
		if [[ -n "$START_ENTRIES" && -n "$END_ENTRIES" ]]; then
			# Read the start time
			START_TIME=$(echo ${START_ENTRIES[0]} | cut -d " " -f 1,2)
			START_TIME_EPOCH=$(date --utc --date $START_TIME +%s%N)
			
			# Read the end time
			END_TIME=$(echo ${END_ENTRIES[$NUM_END_ENTRIES-1]} | cut -d " " -f 1,2)
			END_TIME_EPOCH=$(date --utc --date $END_TIME +%s%N)
			
			# Determine the difference between the two times, in milliseconds
			# (by default the calculation returns nanoseconds)
			OP_TIME=$((($END_TIME_EPOCH-$START_TIME_EPOCH)/1000000))
			
			MYLINE="$MYLINE $OP_TIME,"
		else
			MYLINE="$MYLINE 0,"
		fi
		
		# Reset IFS to its original value
		IFS=$OLD_IFS
	done < $1
	echo "${MYLINE%?}"
done
