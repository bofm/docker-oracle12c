#!/bin/bash

set -e
source colorecho

alert_log="$ORACLE_DATA/diag/rdbms/orcl/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_DATA/dbs/init$ORACLE_SID.ora

if [ "$1" = 'listener' ]; then

	trap "echo_red 'Caught SIGTERM signal, shutting down listener...'; lsnrctl stop" SIGTERM
	trap "echo_red 'Caught SIGINT signal, shutting down listener...'; lsnrctl stop" SIGINT
	tail -F -n 0 $listener_log | while read line; do echo -e "listener: $line"; done &
	lsnrctl start
	wait %1

elif [ "$1" = 'database' ]; then

	trap_db() {
		trap "echo_red 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
		trap "echo_red 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
	}

	start_db() {
		echo_yellow "Starting listener..."
		tail -F -n 0 $listener_log | while read line; do echo -e "listener: $line"; done &
		lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
		echo_yellow "Starting database..."
		trap_db
		tail -F -n 0 $alert_log | while read line; do echo -e "alertlog: $line"; done &
		TAIL_PID=$!
		sqlplus / as sysdba <<-EOF |
			pro Starting with pfile='$pfile' ...
			startup pfile='$pfile';
			alter system register;
			exit 0
		EOF
		while read line; do echo -e "sqlplus: $line"; done
		wait $TAIL_PID
	}

	create_db() {
		echo_yellow "Database does not exist. Creating database..."
		date "+%F %T"
		tail -F -n 0 $alert_log | while read line; do echo -e "alertlog: $line"; done &
		TAIL_PID=$!
		tail -F -n 0 $listener_log | while read line; do echo -e "listener: $line"; done &
		lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
		/tmp/create_database.sh
		echo_green "Database created."
		date "+%F %T"
		trap_db
		wait $TAIL_PID
	}

	stop() {
		shu_immediate
		kill $TAIL_PID
		echo_yellow "Shutting down listener..."
		lsnrctl stop | while read line; do echo -e "lsnrctl: $line"; done
		exit 0
	}

	shu_immediate() {
		ps -ef | grep ora_pmon | grep -v grep > /dev/null && \
		echo_yellow "Shutting down the database..." && \
		sqlplus / as sysdba <<-EOF |
			set echo on
			shutdown immediate;
			exit 0
		EOF
		while read line; do echo -e "sqlplus: $line"; done
	}

	echo "Checking shared memory..."
	df -h | grep "Mounted on" && df -h | egrep --color "^.*/dev/shm" || echo "Shared memory is not mounted."
	[ -f $pfile ] && start_db || create_db

else
	exec "$@"
fi
