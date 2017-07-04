#!/bin/bash

# A little script I initially wrote back in 2012 to control the volume from a
# machine running cmus.
# Predominantly used it to set levels via SSH whenever I wanted, and also as
# an alarm clock.
# Designed to be run on a Debian-based OS derivative - I have noticed issues
# when attempting to run this script on BSD and RHEL systems.

LEVEL=-1
# CLEVEL - Current volume, just a reference to expected $LEVEL, as we need to
# keep checking against this.
CLEVEL="${LEVEL}"
DEVICE="Master" # Target device.
TARGET=false # Target Volume
WAIT=false # Delay in between iterations.
SHOW_ONLY=false # Will change to true if the -s switch is sent through.
IMMEDIATE=false # By default, do not abruptly change the levels.
# NUM_ARGS - Temporary processing variable used to determine if the user has
# provided anything.
NUM_ARGS=0

AMIXER=/usr/bin/amixer

#
#	Notes:
#	  - If the '-d' flag is specified, the value taken is an absolute value, not a
#     relative percentage.
#

# Used to set volume of a device. Takes the level to $1, and uses that.
setVolume() {
	amixer -c 0 set "$DEVICE" "$1" &> /dev/null
}

updateLevel() {
	# Updates $LEVEL to represent the current level.
	AWKINDEX=3
	LEVEL="$("${AMIXER}" -c 0 get "${DEVICE}" | \
		grep '[%]' | \
		head -n 1 | \
		awk '{print $'${AWKINDEX}'}')"
	CLEVEL="${LEVEL}"
}

while getopts "l:l d:d w:w s n" flag
do
	case $flag in
		l) TARGET="$OPTARG";;
		d) DEVICE="$OPTARG";;
		w) WAIT="$OPTARG";;
		s) SHOW_ONLY=true;;
		n) IMMEDIATE=true;;
	esac
	NUM_ARGS=$((NUM_ARGS + 1))
done

# Read current settings
updateLevel

if [ $SHOW_ONLY = true ]; then
	updateLevel
	echo "${LEVEL}"
	exit 0
fi

if [ $NUM_ARGS = 0 ]; then
	echo "Usage: levels [-l desiredLevel] [-d device] [-w delaySpeed]"
	echo "Medium volume: 16"
	exit 1
else
	# Ensure no other levels apps are running.
	for pid in $(pgrep "${0}"); do
		kill "${pid}" > /dev/null 2>&1
	done
	# Read current settings
	updateLevel
	# Sanity check
	# This was written in as the particular system is ran on controlled the master
	# volume in increments of 1 between 0 and 31.
	if [ "${DEVICE}" = "Master" ] && [ "${TARGET}" -gt 31 ]; then
		echo "A value of over 31 is not a good idea for the Master channel."
		exit 2
	fi
	# General protection for maximum thresholds for non-master channels.
	# amixer would set it to the highest allowed value if you entered above the
	# default range, so accidentally typing 255 instead of 25 would result in some
	# interesting situations...
	if [ "${TARGET}" -gt 100 ]; then
		echo "A value of over 100 is not a good idea."
		exit 1
	fi
	if [ "${WAIT}" = false ]; then
		WAIT=0
	fi
	# Conditional - If immediate was true, the volume would immediately 'snap'
	#               to the requested volume, otherwise it would ramp up.
	if [ $IMMEDIATE = true ]; then
		setVolume "${TARGET}"
		if [ "$DEVICE" = "Master" ]; then
			if [ "${TARGET}" = 0 ]; then
				$AMIXER set Master off > /dev/null 2>&1
			else
				$AMIXER set Master on > /dev/null 2>&1
			fi
		fi
	else
		# This is the fade feature - the WAIT flag allows it to ramp up in
		# increments, preventing a jarring volume change (for example, when waking
		# up to this as an alarm)
		while [ "${CLEVEL}" -ne "${TARGET}" ]; do
			# Figure out what the next level is
			NEXTLEVEL=0
			if [ "${CLEVEL}" -gt "${TARGET}" ]; then
				NEXTLEVEL=$((CLEVEL - 1))
			elif [ "${CLEVEL}" -lt "${TARGET}" ]; then
				NEXTLEVEL=$((CLEVEL + 1))
			else
				NEXTLEVEL="${CLEVEL}"
			fi
			setVolume "${NEXTLEVEL}"
			CLEVEL="${NEXTLEVEL}"
			if [ "${CLEVEL}" -eq 0 ] && [ "${DEVICE}" = "Master" ]; then
				$AMIXER set Master off > /dev/null 2>&1
			elif [ "${DEVICE}" = "Master" ]; then
				$AMIXER set Master on > /dev/null 2>&1
			fi
			sleep "${WAIT}"
		done
	fi
fi
