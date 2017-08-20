#!/bin/bash

#[ -f /etc/keepalive-server.conf ] && source /etc/keepalive-server.conf || exit 1

RET=""

# $1 = charac
add_horizon_line() {
	for i in {1..40}; do RET+="$1"; done
	RET+="\n"
}

# $1 = title text
add_title() {
	RET+="$1\n"
	add_horizon_line "="
	RET+="\n"
}

# $1 = title text
add_subtitle() {
	RET+="$1\n"
	add_horizon_line "-"
	RET+="\n"
}

# $1 = title text
add_bullet() {
	RET+="* ${1}\n"
}

final_transmit() {
	echo "Content-type: text/html"
	echo ""
	echo "<html><head>"
	echo "<link rel=\"stylesheet\" href=\"/static/tui.css\">"
	echo "</head><body>"
	echo -e "$RET"
	echo "</body></html>"
}

list_clients() {
	ls ${HOME}/keepalive/
}

# $1 = hostname
list_client_timestamp() {
	ls ${HOME}/keepalive/${1}
}

# $1 = client_hostname
# $2 = timpstamp
assemble_single_client() {
	source ${HOME}/keepalive/${1}/${2}
	add_title "$1"
	add_subtitle "Machine Name"
	add_bullet "${MACHINE_NAME}"
	RET+="\n"
	add_subtitle "CPU and memory"
	add_bullet "Load: ${LOADAVG}"
	add_bullet "CPU: ${CPU_USAGE}"
	add_bullet "Active memory: ${MEM_ACTIVE}"
	add_bullet "Total memory: ${MEM_TOTAL}"
}
