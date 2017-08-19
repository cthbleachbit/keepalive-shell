#!/bin/bash

# Loads in configuration variables
[-f /etc/keepalive-client.conf] && source /etc/keepalive-client.conf

RESULT=""
FILENAME="${CLIENT_MACHINE_NAME}:$(date +%s)"

add_key_value_pair(){
	RESULT+="$1=\"$2\"\n"
}

add_directive(){
	RESULT+="$1\n"
}

# Check loadavg
add_key_value_pair "LOADAVG" "$(cat /proc/loadavg)"

# Check systemd services
add_directive "declare -A SYSTEMD"
for SVC in ${MONITOR_SYSTEMD_SVC}; do
	if systemctl -q is-active ${SVC}; then
		add_key_value_pair "SYSTEMD[$SVC]" "active"
	elif systemctl -q is-failed ${SVC}; then
		add_key_value_pair "SYSTEMD[$SVC]" "failed"
	else
		add_key_value_pair "SYSTEMD[$SVC]" "inactive"
	fi
done

echo -e "${RESULT}" >> /tmp/keepalive.tmp

((${DRY_RUN})) || scp -P ${SERVER_SSH_PORT} \
    -i ${SERVER_USER_KEY} \
    /tmp/keepalive.tmp \
    ${SERVER_USER}@${SERVER_ADDRESS}:/home/${SERVER_USER}/keepalive/$(FILENAME)
