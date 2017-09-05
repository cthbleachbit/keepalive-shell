# keepalive-shell
Server status service with bash

### Client Side

##### Files:

* `bin/keepalive-client.sh`: copy over to `/usr/local/bin/`
* `conf/keepalive-client.conf`: copy over to `/etc` and add systemd service name if desired
* `systemd/keepalive-client.service` and `systemd/keepalive-client.timer`: copy to `/lib/systemd/system` 

##### User separation:

Use a separate account both on server and client side to migitate security problems (if any). Default to a user named `serv`, create a specialized passphrase-less ssh key pair.

### Server Side

##### Files:

* `cgi-bin/keepalive-server.sh`: copy to where you place cgi scripts
* `conf/keepalive-server.conf`: copy over to `/etc`
* `lib/graph-sh`: copy to /usr/local/lib/keepalive
