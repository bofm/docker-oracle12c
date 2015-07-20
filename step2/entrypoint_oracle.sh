#!/usr/bin/env bash

set -e
source colorecho

alert_log="$ORACLE_DATA/diag/rdbms/orcl/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
pfile=$ORACLE_DATA/dbs/init$ORACLE_SID.ora

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}


if [ "$1" = 'listener' ]; then

	trap "echo_red 'Caught SIGTERM signal, shutting down listener...'; lsnrctl stop" SIGTERM
	trap "echo_red 'Caught SIGINT signal, shutting down listener...'; lsnrctl stop" SIGINT
	monitor $listener_log listener &
	MON_LSNR_PID=$!
	lsnrctl start
	wait %1

elif [ "$1" = 'database' ]; then

	trap_db() {
		trap "echo_red 'Caught SIGTERM signal, shutting down...'; stop" SIGTERM;
		trap "echo_red 'Caught SIGINT signal, shutting down...'; stop" SIGINT;
	}

	start_db() {
		echo_yellow "Starting listener..."
		monitor $listener_log listener &
		lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
		MON_LSNR_PID=$!
		echo_yellow "Starting database..."
		trap_db
		monitor $alert_log alertlog &
		MON_ALERT_PID=$!
		sqlplus / as sysdba <<-EOF |
			pro Starting with pfile='$pfile' ...
			startup pfile='$pfile';
			alter system register;
			exit 0
		EOF
		while read line; do echo -e "sqlplus: $line"; done
		wait $MON_ALERT_PID
	}

	create_db() {
		echo_yellow "Database does not exist. Creating database..."
		date "+%F %T"
		monitor $alert_log alertlog &
		MON_ALERT_PID=$!
		monitor $listener_log listener &
		lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
		MON_LSNR_PID=$!
		/tmp/create_database.sh
		echo_green "Database created."
		date "+%F %T"
		trap_db
		wait $MON_ALERT_PID
	}

	stop() {
        trap '' SIGINT SIGTERM
		shu_immediate
		echo_yellow "Shutting down listener..."
		lsnrctl stop | while read line; do echo -e "lsnrctl: $line"; done
		kill $MON_ALERT_PID $MON_LSNR_PID
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
