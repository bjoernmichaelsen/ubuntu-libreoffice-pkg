check_for_running_ooo() {
	if [ -e /usr/lib/openoffice/program/bootstraprc ]; then
		LOCKFILE=`grep UserInstallation /usr/lib/openoffice/program/bootstraprc | cut -d= -f2 | sed -e 's,SYSUSERCONFIG,HOME,'`
		PID=`pgrep soffice.bin | head -n 1`
		if [ -n "$PID" ] || [ -e "$LOCKFILE" ]; then
			db_input high openoffice.org/running
			db_go
			# try again in case OOo got closed before hitting OK
			PID=`pgrep soffice.bin | head -n 1`
			if [ -n "$PID" ] || [ -e "$LOCKFILE" ]; then
			  exit 1
			fi
		fi
	fi
}

handle_soffice_listeners() {
	services="docvert-converter"
	for s in $services; do
		if [ -x /etc/init.d/$s ]; then
			if [ -x /usr/sbin/invoke-rc.d ]; then
				invoke-rc.d $s $1
			else
				/etc/init.d/$s $1
			fi
		fi
	done
	# wait for proper shutdown/kill
	sleep 1
}

revoke_from_services_rdb() {
  handle_soffice_listeners stop
  check_for_running_ooo
  rdb="`echo /@OOBASISDIR@/program | sed -e s/usr/var/`/services.rdb"
  lib="`basename $1`"
  if [ -e "$rdb" ] && /usr/lib/ure/bin/regview $rdb | grep -q $lib; then
    /usr/lib/ure/bin/regcomp -revoke -r $rdb -br $rdb -c file://$1
  fi
  handle_soffice_listeners start
}

register_to_services_rdb() {
  handle_soffice_listeners stop
  check_for_running_ooo
  rdb="`echo /@OOBASISDIR@/program | sed -e s/usr/var/`/services.rdb"
  /usr/lib/ure/bin/regcomp -register -r $rdb -br $rdb -c file://$1
  handle_soffice_listeners start
}