#!/bin/bash

# Loads in configuration variables
[ -f /etc/keepalive-client.conf ] && source /etc/keepalive-client.conf

RESULT=""
FILENAME="$(date +%s)"

add_key_value_pair() {
	RESULT+="$1=\"$2\"\n"
}

add_directive() {
	RESULT+="$1\n"
}

send_info() {
	ssh ${SERVER_USER}@${SERVER_ADDRESS} \
	    -p ${SERVER_SSH_PORT} \
	    -i ${SERVER_USER_KEY} \
	    mkdir -p /home/${SERVER_USER}/keepalive/${CLIENT_HOSTNAME}/
	scp -P ${SERVER_SSH_PORT} \
	    -i ${SERVER_USER_KEY} \
	    /tmp/keepalive.tmp \
	    ${SERVER_USER}@${SERVER_ADDRESS}:/home/${SERVER_USER}/keepalive/${CLIENT_HOSTNAME}/${FILENAME}
}

# Put common name
add_key_value_pair "MACHINE_NAME" "${CLIENT_MACHINE_NAME}"

# Check CPU and memory usage
CPU_USAGE=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))
MEM_USAGE=$(free -h | grep 'Mem:')
MEM_ACTIVE=$(echo $MEM_USAGE | awk '{print $3}')
MEM_TOTAL=$(echo $MEM_USAGE | awk '{print $2}')
add_key_value_pair "CPU_USAGE" "$CPU_USAGE"
add_key_value_pair "MEM_ACTIVE" "$MEM_ACTIVE"
add_key_value_pair "MEM_TOTAL" "$MEM_TOTAL"

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

echo -e "${RESULT}" > /tmp/keepalive.tmp

((${DRY_RUN})) || send_info
