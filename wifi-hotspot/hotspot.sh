#!/bin/bash

# This script is used to enable / disable a wifi hotspot on this machine.
# It must be run as root, and takes one command - either on or off

# Usage function
function usage() {
	echo "This script will enable or disable a wifi hotspot on this machine."
	echo "It must be run as root, as the commands it runs will not work as a normal user."
	echo "The following commands are supported:"
	echo "   on      Turns the hotspot on."
	echo "   off     Turns the hotspot off."
	echo "   status  Tells if the hotspot is running.  If running, will also print out hotspot name and password."
}

# Confirm user is root
if [[ $EUID -ne 0 ]]; then
	usage
	exit 1;
fi

# Confirm the user specified either on or off
OPTION="$@"
if [[ $OPTION = "" ]]; then
	usage
	exit 1;
fi

echo "You specified $OPTION"
