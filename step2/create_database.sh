#!/usr/bin/env bash

source colorecho
trap "echo_red '******* ERROR: Something went wrong.'; exit 1" ERR
trap "echo_red '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

mkdir -p $ORACLE_DATA/oradata $ORACLE_DATA/dbs $ORACLE_DATA/fra
chown -R oracle:oinstall $ORACLE_DATA
chmod -R 775 $ORACLE_DATA

log="$ORACLE_BASE/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log"
pfile=$ORACLE_DATA/dbs/init$ORACLE_SID.ora

tail -n0 -F $log | while read line; do echo -e "dbca_log: $line"; done &
DBCA_TAIL_PID=$!

dbca -silent -createDatabase \
	-templateName              /tmp/db_template.dbt \
	-gdbName                   $ORACLE_SID \
	-sid                       $ORACLE_SID \
	-responseFile              NO_VALUE \
	-characterSet              AL32UTF8 \
	-memoryPercentage          40 \
	-emConfiguration           LOCAL \
	-sysPassword               sys \
	-systemPassword            system \
	-datafileDestination       $ORACLE_DATA/oradata \
	-recoveryAreaDestination   $ORACLE_DATA/fra \
	-redoLogFileSize           100 \
	-storageType               FS \
	-variables                 ORACLE_DATA=$ORACLE_DATA \
	-initParams                audit_file_dest=$ORACLE_DATA/admin/$ORACLE_SID/adump,diagnostic_dest=$ORACLE_DATA,filesystemio_options=SETALL \
	-sampleSchema              true \
	-automaticMemoryManagement true \
	-databaseType              MULTIPURPOSE \
	| while read line; do echo -e "dbca: $line"; done
	test ${PIPESTATUS[0]} -eq 0 || (echo_red "dbca exit code is $?." && sleep 5 && false)

kill $DBCA_TAIL_PID

sqlplus / as sysdba <<-EOF |
	whenever sqlerror exit failure
	create pfile='$pfile' from spfile;
	alter system register;
	exit 0
EOF
while read line; do echo -e "sqlplus: $line"; done

echo_green pfile saved to $pfile
