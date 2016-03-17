REPO = bofm/oracle12c
NAME = oracle
CURDIR = `pwd`
SHM_SIZE = 1GB
OPTS = --shm-size $(SHM_SIZE)
DOCKER_SAVE_FILENAME = docker_img_oracle_database_created_$$(date +%Y-%m-%d).tgz
ccred=\033[0;31m
ccgreen=\033[32m
ccyellow=\033[0;33m
ccend=\033[0m

.PHONY: all

# Use bofm/oracle12c:preinstall from Docker Hub
all: install postinstall

# Build from scratch
full: preinstall install postinstall

clean:
	@[ `docker images -q --filter "dangling=true"| wc -l` -gt 0 ] && docker rmi `docker images -q --filter "dangling=true"` || true
	@[ `docker volume ls -q --filter "dangling=true"| wc -l` -gt 0 ] && docker volume rm `docker volume ls -q --filter "dangling=true"` || true

clean2:
	@echo `docker rm -v oracle > /dev/null 2>&1 && echo Container "oracle" has been removed.`

preinstall:
	@echo "$(ccgreen)Building base image...$(ccend)"
#	The following loop is a workaround for the bug of "docker build", related to device mapper.
#	Bug example:
#	INFO[0019] Error getting container ea069f9ff24469184e70e5ce9b2d6132a31109bf1d0a3e0e5d30e50da8cbd0b6 from driver devicemapper:
#	Error mounting '/dev/mapper/docker-8:1-263449-ea069f9ff24469184e70e5ce9b2d6132a31109bf1d0a3e0e5d30e50da8cbd0b6' on
#	'/var/lib/docker/devicemapper/mnt/ea069f9ff24469184e70e5ce9b2d6132a31109bf1d0a3e0e5d30e50da8cbd0b6': no such file or directory
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
	@docker run $(OPTS) --name $(NAME)_install -v $(CURDIR)/database:/tmp/install/database $(REPO):preinstall /tmp/install/install.sh
	@echo "$(ccgreen)Committing image with tag 'installed'...$(ccend)"
	@docker commit $(NAME)_install $(REPO):installed
	@docker rm $(NAME)_install

run:
	@docker run -it --rm $(OPTS) --name $(NAME) $(REPO) bash

run-v:
	docker run -it --rm -v /data $(OPTS) --name $(NAME) $(REPO) bash

test:
	docker run -it -v /data $(OPTS) --name oracle_db_test $(REPO) database
	docker start -ia oracle_db_test
	docker rm -v oracle_db_test

test2:
	docker run -it -v /data $(OPTS) --name oracle_db_test  $(REPO) database
	docker rm -v oracle_db_test

test3:
	docker run -it $(OPTS) --name oracle_db_test $(REPO) database
	docker rm -v oracle_db_test

docker-save:
	@echo "$(ccgreen)Running new container and creating database...$(ccend)"
	docker run -d $(OPTS) --name oracle_db_test $(REPO) database
	docker logs -f oracle_db_test &
	@while true; do \
		docker logs oracle_db_test 2>/dev/null | grep "Database created." && break || sleep 20; \
	done
	@echo "$(ccgreen)Stopping container...$(ccend)"
	docker stop -t 120 oracle_db_test
	@echo "$(ccgreen)Committing image with tag '$(REPO):created' ...$(ccend)"
	docker commit oracle_db_test $(REPO):created
	@echo "$(ccgreen)Saving image...$(ccend)"
	docker save $(REPO):created | gzip -c > $(DOCKER_SAVE_FILENAME)
	@docker rm oracle_db_test > /dev/null
	@echo "$(ccgreen)Image saved to: `readlink -f $(DOCKER_SAVE_FILENAME)`$(ccend)"

