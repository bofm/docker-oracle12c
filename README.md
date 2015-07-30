## Goals
* Provide an easy way to build a lightweight [Docker](http://www.docker.com/) image for [Oracle Database](http://docs.oracle.com/database/121/index.htm).
* Just run a database and skip the complexity of installing software, creating and configuring database.

## Features
* `docker run` creates and starts up a new database or the existing database, if it is already created.
* `docker logs` shows all the logs prefixed with log source (in the style of syslog).
* Uses `trap` to handle signals and shutdown gracefully.
* Data and logs go to `/data`, so that `-v /data` could be used.
* Mounts 50% of total memory to `/dev/shm` as shared memory. Oracle instance uses 40% of total memory. Can be changed in [entrypoint.sh](step2/entrypoint.sh) and [create_database.sh](step2/create_database.sh).
* rlwrap can be installed by running `bash /tmp/install/install_rlwrap.sh` (+ 50 MB on disk).


## Build
Optional: if you are using [Vagrant](https://www.vagrantup.com/), you can use this [Vagrantfile](Vagrantfile) for your build environment.

1.  download `linuxamd64_12102_database_1of2.zip` and `linuxamd64_12102_database_2of2.zip` from [oracle.com](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html) **and extract the archives to current directory**.
2. Execute the following lines in bash and wait ~15 minutes:
```shell
git clone https://github.com/bofm/docker-oracle12c.git
cd docker-oracle12c
make all
```

## Usage
*Note: In the following examples `oracle_database` is the name of the container.*

* Create or run database and listener
  * Daemon mode

    ```bash
    # Create and start
    docker run -d --privileged --name oracle_database -p 1521:1521 -v /data bofm/oracle12c
    # Stop
    docker stop -t 120 oracle_database
    # Start again
    docker start oracle_database
    ```
    **Important:** Always stop with `-t`, otherwise Docker will kill the database instance, if it doesn't shut down in 10 seconds.
  * Foreground mode

    ```bash
    # Start
    docker run -it --privileged --name oracle_database -p 1521:1521 -v /data bofm/oracle12c
    # `ctrl+c` (SIGINT) to stop
    ```

* Create a gzipped tar archive suitable for `docker load` (an archive of the image with a created database and without volumes)

  It is recommended to use large (>=20GB, the default is 10GB) Docker base volume size, for which Vagrant with [Vagrantfile](Vagrantfile) can be used.

  ```bash
  # Build everything and save the created image to a file.
  #   This will echo something like this:
  #     Image saved to: /some/path/docker_img_oracle_database_created_YYYY-MM-DD.tgz
  make all docker-save

  # The saved image can be loaded from the file
  # The image will be loaded with tag bofm/oracle12c:created
  docker load < docker_img_oracle_database_created_YYYY-MM-DD.tgz

  # Run the image in the new container
  # Daemon
  docker run -d --privileged --name oracle_database -p 1521:1521 bofm/oracle12c:created
  # Foreground
  docker run -it --privileged --name oracle_database -p 1521:1521 bofm/oracle12c:created
  ```

* Logs

  ```bash
  # Check all the logs in one place
  docker logs oracle_database

  # Check alert log
  docker logs oracle_database | grep alertlog:

  # Check listener log
  docker logs oracle_database | grep listener:
  ```

* SQL*Plus, RMAN or any other program

  ```bash
  # Bash
  # as root
  docker exec -it oracle_database bash
  # as oracle
  docker exec -it oracle_database gosu oracle bash

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
* Database options and sample schemas installation through DBCA is a mystery. In this repo dbca is run with `-sampleSchema true` and [db_template.dbt](step2/db_template.dbt) contains this line `<option name="SAMPLE_SCHEMA" value="true"/>`, but nothing happens, the database is always created without sample schemas. Well, that's Oracle Database after 30+ years of development.

### License
* This repo - [MIT License](LICENSE).
* Oracle Database software - see [Database Licensing Information](http://docs.oracle.com/database/121/DBLIC/toc.htm).

### TODO
* use spfile
* EM DBconsole
* Archivelog mode option?
* syslog-ng or rsyslog, maybe?
