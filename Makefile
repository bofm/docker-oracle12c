REPO = bofm/oracle12c
NAME = oracle
CURDIR = `pwd`
OPTS =
ccred=\033[0;31m
ccgreen=\033[32m
ccyellow=\033[0;33m
ccend=\033[0m

.PHONY: all clean

all: preinstall install postinstall

clean:
	@[ `docker images -q --filter "dangling=true"| wc -l` -gt 0 ] && docker rmi `docker images -q --filter "dangling=true"` || true
	@[ `docker ps -aq | wc -l` -gt 0 ] && docker rm `docker ps -aq` || true

clean2:
	@echo `docker rm -v oracle > /dev/null 2>&1 && echo Container "oracle" has been removed.`

preinstall:
	@echo "$(ccgreen)Building base image...$(ccend)"
	# The following loop is a fix for the bug of "docker build", related to device mapper.
	# Bug example:
	# INFO[0019] Error getting container ea069f9ff24469184e70e5ce9b2d6132a31109bf1d0a3e0e5d30e50da8cbd0b6 from driver devicemapper:
	# Error mounting '/dev/mapper/docker-8:1-263449-ea069f9ff24469184e70e5ce9b2d6132a31109bf1d0a3e0e5d30e50da8cbd0b6' on
	# '/var/lib/docker/devicemapper/mnt/ea069f9ff24469184e70e5ce9b2d6132a31109bf1d0a3e0e5d30e50da8cbd0b6': no such file or directory
	@for n in `seq 10`; do \
	    docker build -t $(REPO):preinstall step1 &&\
	    break || echo "$(ccred)******* FAILED $$n times$(ccend)" && sleep 2;\
	done

postinstall:
	@echo "$(ccgreen)Building the final image...$(ccend)"
	@for n in `seq 10`; do \
		docker build -t $(REPO):latest step2 &&\
		break || echo "$(ccred)******* FAILED $$n times$(ccend)" && sleep 2;\
	done
	@echo "$(ccgreen)Image created: $(REPO):latest$(ccend)"
	@docker images $(REPO)

install:
	@echo "$(ccgreen)Installing Oracle Database software...$(ccend)"
	@if docker ps -a|grep $(NAME)_install; then docker rm $(NAME)_install; fi
	@docker run --name $(NAME)_install -v $(CURDIR)/../database:/tmp/install/database $(REPO):preinstall /tmp/install/install.sh
	@echo "$(ccgreen)Committing image with tag 'installed'...$(ccend)"
	@docker commit $(NAME)_install $(REPO):installed
	@docker rm $(NAME)_install

run:
	@docker run --rm $(OPTS) --name $(NAME) -i -t $(REPO) bash

run-priv:
	docker run -it --rm -v /data --privileged $(OPTS) --name $(NAME) $(REPO) bash --shm

test:
	docker run -it -v /data --privileged $(OPTS) --name oracle_db_test $(REPO) database --shm
	docker start -ia oracle_db_test
	docker rm -v oracle_db_test

test2:
	docker run -it -v /data --privileged $(OPTS) --name oracle_db_test  $(REPO) database
	docker rm -v oracle_db_test

test3:
	docker run -it $(OPTS) --name oracle_db_test $(REPO) database
	docker rm -v oracle_db_test



