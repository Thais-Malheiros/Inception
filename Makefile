LOGIN = cadete #ajustar no ambiente da 42
VOLUMES_PATH = /home/$(LOGIN)/data

DOCKER_COMPOSE_FILE=./srcs/docker-compose.yml
DOCKER_COMPOSE_COMMAND=docker compose -f ${DOCKER_COMPOSE_FILE}

export LOGIN
export VOLUMES_PATH

all: setup up

host:
	@if ! grep -q "${LOGIN}.42.fr" /etc/hosts; then \
		sudo sed -i "2i\127.0.0.1\t${LOGIN}.42.fr" /etc/hosts; \
	fi

host-clean:
	sudo sed -i "/${LOGIN}.42.fr/d" /etc/hosts

setup: host
	sudo mkdir -p ${VOLUMES_PATH}/mariadb
	sudo mkdir -p ${VOLUMES_PATH}/wordpress
	sudo chmod 777 ${VOLUMES_PATH}/mariadb
	sudo chmod 777 ${VOLUMES_PATH}/wordpress

up: build
	$(DOCKER_COMPOSE_COMMAND) up -d

build:
	$(DOCKER_COMPOSE_COMMAND) build

downn:
	$(DOCKER_COMPOSE_COMMAND) downn

ps:
	$(DOCKER_COMPOSE_COMMAND) ps

ls:
	docker volume ls

open-wp:
	@echo "Opening Wordpress in local browser..."
	@firefox http://$(LOGIN).42.fr &

clean: host-clean
	$(DOCKER_COMPOSE_COMMAND) down --rmi all --volumes

reset:
	docker stop $$(docker ps -qa)
	docker rm $$(docker ps -qa)
	docker rmi -f $$(docker images -qa)
	docker volume rm $$(docker volume ls -q)
	docker network rm $$(docker network ls -q) 2>/dev/null

fclean:
	docker system prune --force --all --volumes
	sudo rm -rf /hpme/${LOGIN}
	sudo rm -rf ./srcs/logs/

.PHONY: all up build build-no-cache down ps ls clean fclean setup host