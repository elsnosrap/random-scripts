#!/bin/bash

# CONSTANTS
# The network device to slow down - should be the wireless adapter.
NETWORK_DEVICE="wlan0"

# Network Delays.  These values were pulled from http://developer.android.com/tools/devices/emulator.html#netdelay
# GPRS MIN = 150, MAX = 550
# EDGE MIN = 80, MAX = 400
# 3G MIN = 35, MAX = 200
# No delay for HSDPA
GPRS_DELAY="350ms"
GPRS_DELAY_VARIATION="200ms"
EDGE_DELAY="240ms"
EDGE_DELAY_VARIATION="160ms"
THREEG_DELAY="115ms"
THREEG_DELAY_VARIATION="85ms"

# Network Rates in kbps
GPRS_UP_RATE="40kbps"
GPRS_DOWN_RATE="80kbps"
EDGE_UP_RATE="118kbps"
EDGE_DOWN_RATE="236kbps"
THREEG_UP_RATE="128kbps"
THREEG_DOWN_RATE="1920kbps"
HSDPA_UP_RATE="348kbps"
HSDPA_DOWN_RATE="14400kbps"

function usage() {
	echo "This script introduces delay into the current network connection.  It must be run as root."
	echo "One of the following arguments are required:"
	echo "   usage       Displays this help text"
	echo "   status      Displays the rules currently in effect"
	echo "   clear       Removes any rules in effect"
	echo "   gprs        Slows the network connection down to GPRS speeds"
	echo "   edge        Slows the network connection down to EDGE speeds"
	echo "   3g          Slows the network connection down to 3G speeds"
	echo "   hsdpa       Slows the network connection down to HSDPA speeds"
}

# This script uses NetEm to introduce network latency and delay, simulating slower networks.
# It must be run as root, otherwise these commands won't work
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root."
	exit 1;
fi

# Verify there is only one argument
if [[ $# != 1 ]]; then
	usage
	exit 0;
fi

if [[ "$1" == "usage" ]]; then
	usage
	exit 0;
	
elif [[ "$1" == "status" ]]; then
	tc -p qdisc ls dev $NETWORK_DEVICE
	exit 0;
	
elif [[ "$1" == "clear" ]]; then
	# Clear the rules and then display the status
	tc qdisc del dev $NETWORK_DEVICE root
	tc -p qdisc ls dev $NETWORK_DEVICE
	exit 0;

elif [[ "$1" == "gprs" ]]; then
	NETWORK_DELAY=$GPRS_DELAY
	NETWORK_DELAY_VARIATION=$GPRS_DELAY_VARIATION
	NETWORK_UP_RATE=$GPRS_UP_RATE
	NETWORK_DOWN_RATE=$GPRS_DOWN_RATE

elif [[ "$1" == "edge" ]]; then
	NETWORK_DELAY=$EDGE_DELAY
	NETWORK_DELAY_VARIATION=$EDGE_DELAY_VARIATION
	NETWORK_UP_RATE=$EDGE_UP_RATE
	NETWORK_DOWN_RATE=$EDGE_DOWN_RATE

elif [[ "$1" == "3g" ]]; then
	NETWORK_DELAY=$THREEG_DELAY
	NETWORK_DELAY_VARIATION=$THREEG_DELAY_VARIATION
	NETWORK_UP_RATE=$THREEG_UP_RATE
	NETWORK_DOWN_RATE=$THREEG_DOWN_RATE

elif [[ "$1" == "hsdpa" ]]; then
	NETWORK_UP_RATE=$HSPDA_UP_RATE
	NETWORK_DOWN_RATE=$HSDPA_DOWN_RATE

else
	echo "Unknown argument: $1"
	usage
	exit 0;
fi

# Be sure all rules are cleared first
tc qdisc del dev $NETWORK_DEVICE root

# Create the root rule
echo "tc qdisc add dev $NETWORK_DEVICE root handle 1: htb default 12"
tc qdisc add dev $NETWORK_DEVICE root handle 1: htb default 12

# Create the download limit rate rule
echo "tc class add dev $NETWORK_DEVICE parent 1:1 classid 1:12 htb rate $NETWORK_DOWN_RATE"
tc class add dev $NETWORK_DEVICE parent 1:1 classid 1:12 htb rate $NETWORK_DOWN_RATE

# Create the upload limit rate rule
#echo "tc class add dev $NETWORK_DEVICE parent 1: classid 1:2 htb rate $NETWORK_UP_RATE"
#tc class add dev $NETWORK_DEVICE parent 1: classid 1:2 htb rate $NETWORK_UP_RATE

# If a network delay is used, add a network delay rule
if [[ -n "$NETWORK_DELAY" ]]; then
	echo "tc qdisc add dev $NETWORK_DEVICE parent 1: netem delay $NETWORK_DELAY $NETWORK_DELAY_VARIATION distribution normal"
	tc qdisc add dev $NETWORK_DEVICE parent 1:12 netem delay $NETWORK_DELAY $NETWORK_DELAY_VARIATION distribution normal
fi

# The basic commands to run
#tc qdisc add dev $NETWORK_DEVICE root handle 1: htb default 12
#tc class add dev $NETWORK_DEVICE parent 1:1 classid 1:12 htb rate 118kbps ceil 237kbps
#tc qdisc add dev $NETWORK_DEVICE parent 1:12 netem delay 240ms 160ms distribution normal

# GPRS NETWORK COMMANDS
#sudo tc qdisc add dev wlan0 root handle 1: htb default 12
#sudo tc class add dev wlan0 parent 1:1 classid 1:12 htb rate 80kbps ceil 80kbps
#sudo tc qdisc add dev wlan0 parent 1:12 netem delay 350ms 200ms distribution normal

# EDGE NETWORK COMMANDS
#sudo tc qdisc add dev wlan0 root handle 1: htb default 12
#sudo tc class add dev wlan0 parent 1:1 classid 1:12 htb rate 236kbps
#sudo tc qdisc add dev wlan0 parent 1:12 netem delay 240ms 160ms distribution normal

# 3G NETWORK COMMANDS
#sudo tc qdisc add dev wlan0 root handle 1: htb default 12
#sudo tc class add dev wlan0 parent 1:1 classid 1:12 htb rate 1920kbps
#sudo tc qdisc add dev wlan0 parent 1:12 netem delay 115ms 85ms distribution normal

# HSDPA NETWORK COMMANDS
#sudo tc qdisc add dev wlan0 root handle 1: htb default 12
#sudo tc class add dev wlan0 parent 1:1 classid 1:12 htb rate 1920kbps
#sudo tc qdisc add dev wlan0 parent 1:12 netem delay 60ms 50ms distribution normal

# Command to display which rules are currently in effect
#sudo tc -p qdisc ls dev wlan0

# Command to delete all current rules
#sudo tc qdisc del dev wlan0 root
