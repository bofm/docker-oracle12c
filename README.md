## Goals
* Provide an easy way to build a lightweight [Docker](http://www.docker.com/) image for [Oracle Database](http://docs.oracle.com/database/121/index.htm).
* Be able to just run a new database and skip the complexity of installing software, creating and configuring database.

## Features
* `docker run` creates and starts up a new database or the existing database, if it is already created.
* `docker logs` shows all the logs prefixed with log source (in the style of syslog).
* Uses `trap` to handle signals and shutdown gracefully.
* Data and logs go to `/data`, so that `-v /data` could be used.
* Mounts 40% of RAM to `/dev/shm` as shared memory. Can be changed in [entrypoint.sh](step2/entrypoint.sh).


## Build
1.  download `linuxamd64_12102_database_1of2.zip` and `linuxamd64_12102_database_2of2.zip` from [oracle.com](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html) and extract the archives to current directory.
2. Execute the following lines in bash:
```shell
git clone https://github.com/bofm/docker-oracle12c.git
cd docker-oracle12c
make all
```

## Usage
*Note: In the following examples `oracle_database` is the name of the container.*

* Create or run database and listener

  ```bash
  # Daemon mode
  docker run -d --privileged --name oracle_database -p 1521:1521 -v /data bofm/oracle12c

  # Foreground mode
  docker run -it --privileged --name oracle_database -p 1521:1521 -v /data bofm/oracle12c
  ```

* Logs

  ```bash
  # Check all the logs in one place
  docker logs oracle_database

  # Check alert log
  docker logs oracle_database | grep alert:

  # Check listener log
  docker logs oracle_database | grep listener:
  ```

* SQL*Plus, RMAN or any other program

  ```bash
  # Run sqlplus in the running container
  docker exec -it oracle_database gosu oracle sqlplus / as sysdba

  # Run rman in the running container
  docker exec -it oracle_database gosu oracle rman target /

  # Run sqlplus in a separate container and
  # connect to the database in the linked container
  docker run -it --rm --link oracle_database:oradb bofm/oracle12c sqlplus sys/sys@oradb/ORCL as sysdba
  ```

* Start listener only (not sure if anybody needs it :) )

  ```bash
  docker run -d --name listener -p 1521:1521 bofm/oracle12c listener
  # Or link it to the running container
  docker run -d --name listener -p 1521:1521 --link <database_container> bofm/oracle12c listener
  ```

### Limitations and Bugs
* `--privileged` option is required to mount /dev/shm to use Oracle's automatic memory management.
* 12.1.0.2's dbca always creates database with unnecessary stuff (like APEX, OLAP, example schemas, etc.), although these options are disabled in the database template [db_template.dbc](step2/db_template.dbc). Seems to be a bug of dbca.

### License
* This repo - [MIT License](LICENSE).
* Oracle Database software - see [Database Licensing Information](http://docs.oracle.com/database/121/DBLIC/toc.htm).

### TODO
* rlwrap
* Archivelog mode option?
* syslog-ng, maybe?
