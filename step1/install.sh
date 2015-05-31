#!/usr/bin/env bash
set -e

trap "echo '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

gosu oracle /bin/bash -c "cd /tmp/install/database/ && ./runInstaller -waitforcompletion -ignoreSysPrereqs -ignorePrereq -silent -noconfig -responseFile /tmp/install/db_install.rsp" &
wait $!
/app/oracle/product/12.1.0/dbhome_1/root.sh
