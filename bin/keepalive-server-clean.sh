#!/bin/bash

# environment
HOME=~

fail() {
	echo "$@"
	exit 0
}

list_clients() {
	ls ${HOME}/keepalive/ -1
}

# Loads in configuration variables
[ -f /etc/keepalive-server.conf ] && source /etc/keepalive-server.conf || fail "Config not found"

for CLIENT in $(list_clients); do
	time_now_unix="$(date +%s)"
	count=0
	for TIME in $(ls ${HOME}/keepalive/${CLIENT} -1 | sort); do
		time_diff_unix=$(($time_now_unix - $TIME))
		if [ $time_diff_unix -gt $KEEP_LOGS ]; then
			rm ${HOME}/keepalive/${CLIENT}/${TIME}
			count=$(($count + 1))
		fi
	done
	echo Deleted $count logs for ${CLIENT}.
done
