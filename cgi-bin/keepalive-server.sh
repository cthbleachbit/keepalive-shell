#!/bin/bash

# environment
HOME=~
WIDTH=64

[ -f /etc/keepalive-server.conf ] && source /etc/keepalive-server.conf || fail "Config not found"
GRAPH_WIDTH=${WIDTH}
source /usr/local/lib/keepalive/graph-sh

fail() {
	RET="$@"
	final_transmit
	exit 0
}

# time markers
# $1 = unix epoch
assemble_time_tag() {
	RET_INNER=""
	time_text="$(date --date=@${1})"
	time_now_unix="$(date +%s)"
	time_diff_unix=$(($time_now_unix - $1))
	if [ $time_diff_unix -lt 1800 ]; then
		RET_INNER+="<span class=\"upd30m\">"
	elif [ $time_diff_unix -lt 3600 ]; then
		RET_INNER+="<span class=\"upd1h\">"
	else
		RET_INNER+="<span class=\"updfail\">"
	fi
	RET_INNER+="${time_text}</span>"
	echo "${RET_INNER}"
}

# add an html linefeed
lf() {
	RET+="\n"
}

# $1 = charac
add_horizon_line() {
	for i in $(seq 1 $WIDTH); do RET+="$1"; done
	lf
}

# $1 = title text
add_title() {
	RET+="$1"
	lf
	add_horizon_line "="
	lf
}

# $1 = title text
add_subtitle() {
	RET+="$1"
	lf
	add_horizon_line "-"
	lf
}

# $1 = title text
add_bullet() {
	RET+="* ${1}"
	lf
}

final_transmit() {
	echo "Content-type: text/html"
	echo ""
	echo "<html><head>"
	echo "<link rel=\"stylesheet\" href=\"/static/tui.css\">"
	echo "<title>Status</title>"
	echo "</head><body><p class=\"status\">"
	echo -e "$RET"
	echo "<\p></body></html>"
}

list_clients() {
	ls ${HOME}/keepalive/ -1
}

# $1 = hostname
list_client_timestamps() {
	ls ${HOME}/keepalive/${1} -1 | sort -r
}

# $1 = client_hostname
# $2 = timpstamp
assemble_single_client() {
	GRAPH_CPU="$(draw_cpu_usage $1)"
	source ${HOME}/keepalive/${1}/${2}
	add_title "$1"
	add_subtitle "Machine Name"
	add_bullet "${MACHINE_NAME}"
	add_bullet "$(assemble_time_tag ${2})"
	lf
	add_subtitle "CPU and memory"
	add_bullet "Load: ${LOADAVG}"
	add_bullet "CPU: ${CPU_USAGE}"

	add_horizon_line "+"
	RET+="$GRAPH_CPU"
	add_horizon_line "+"

	add_bullet "Active memory: ${MEM_ACTIVE}"
	add_bullet "Total memory: ${MEM_TOTAL}"
	lf
	(( ${#SYSTEMD[@]} )) && add_subtitle "Systemd services"
	(( ${#SYSTEMD[@]} )) && for SVC in "${!SYSTEMD[@]}"; do
		add_bullet "$SVC: ${SYSTEMD[${SVC}]}"
	done
	lf
	# clean up the array
	unset SYSTEMD
}

# $1 = client_hostname
draw_cpu_usage() {
	TIME_LIST="$(list_client_timestamps ${1} | tail -${WIDTH})"
	CPU_LIST=""
	for TIME in ${TIME_LIST}; do
		source ${HOME}/keepalive/${1}/${TIME}
		CPU_LIST="$CPU_LIST ${CPU_USAGE}"
	done
	CPU_LIST=$(echo $CPU_LIST | sed -e 's/\.[0-9]\+//g')
	draw_graph ${CPU_LIST//%/}
}

ACCESS_GRANTED=1
if (($ENABLE_TOTP)); then
	ACCESS_GRANTED=0
	source /usr/local/lib/totp-cth-cli/alg.lib.sh
	source /usr/local/lib/totp-cth-cli/uri.lib.sh
	source /usr/local/lib/totp-cth-cli/base32decoder.lib.sh
fi

# string storage
RET=""

if (($TOTP_ENABLED)); then
	USER=`echo "$QUERY_STRING" | sed -n 's/^.*username=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
fi

if (($ACCESS_GRANTED)); then
	for CLIENT in $(list_clients); do
		LIST=$(list_client_timestamps ${CLIENT})
		TIMESTAMPS=($LIST)
		assemble_single_client ${CLIENT} ${TIMESTAMPS[0]}
	done

	final_transmit
else
	add_bullet "Access Denied"
	final_transmit
fi
