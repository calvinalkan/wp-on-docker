##@ [Docker]

#
# =================================================================
# Enable BuildKit for docker
# =================================================================
#
# Export BuildKit settings for docker and docker-compose to
# subshells.
#
# https://docs.docker.com/develop/develop-images/build_enhancements/#to-enable-buildkit-builds
DOCKER_BUILDKIT:=1
BUILDKIT_INLINE_CACHE:=1
export DOCKER_BUILDKIT
export BUILDKIT_INLINE_CACHE

#
# =================================================================
# Define docker variables
# =================================================================
#
DOCKER_DIR:=$(CURDIR)/.docker
LOG_DIR:=$(CURDIR)/.logs
DOCKER_ENV_FILE:=$(DOCKER_DIR)/.env
DOCKER_COMPOSE_DIR:=$(DOCKER_DIR)/compose
 # Make this a lazy variable so that we can override it from the command line.
DOCKER_COMPOSE_PROJECT_NAME?=wp_on_docker
# These values must match exactly the service names
# in the docker-compose files.
DOCKER_SERVICE_WP_NAME:=wp

#
# =================================================================
# Determine compose files for environment
# =================================================================
#
# We need to "assemble" the correct combination and order of
# docker-compose files depending on the environment.
#
ALL_DOCKER_COMPOSE_FILES=-f $(DOCKER_COMPOSE_DIR)/docker-compose.yml


#
# =================================================================
# Define a docker compose macro
# =================================================================
#
# Build a make macro so that we dont have to type very
# long commands all the time.
#
# This will export the current environment variables and then
# run docker compose.
#
DOCKER_COMPOSE=DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
 DOCKER_NAMESPACE=$(DOCKER_NAMESPACE) \
 DOCKER_DIR=$(DOCKER_DIR) \
 LOG_DIR=$(LOG_DIR) \
 ROOT_DIR=$(CURDIR) \
 LOCAL_USER_NAME=$(LOCAL_USER_NAME) \
 LOCAL_GROUP_NAME=$(LOCAL_GROUP_NAME) \
 LOCAL_USER_ID=$(LOCAL_USER_ID) \
 LOCAL_GROUP_ID=$(LOCAL_GROUP_ID) \
 SITE_HOST=$(SITE_HOST) \
 WP_CONTAINER_WP_PATH=$(WP_CONTAINER_WP_PATH) \
 docker compose -p $(DOCKER_COMPOSE_PROJECT_NAME) --env-file $(DOCKER_ENV_FILE) $(ALL_DOCKER_COMPOSE_FILES)

#
# =================================================================
# Are we running make inside a docker container?
# =================================================================
#
# This macro will determine if we are currently running
# inside a docker container.
#
# This is convenient and will allow use to use our make commands inside
# a docker container the same way we would use them from our local machine.
#
# If FORCE_RUN_IN_CONTAINER=true is passed we will always run
# commands inside new docker containers.
#
FORCE_RUN_IN_CONTAINER?=
MAYBE_EXEC_IN_DOCKER?=
MAYBE_EXEC_IN_WP_SERVICE?=
DOCKER_EXEC_ARGS?=
DOCKER_RUN_ARGS?=

ifndef FORCE_RUN_IN_CONTAINER
	# check if 'make' is executed in a docker container,
	# @see https://stackoverflow.com/a/25518538/413531
	# `wildcard $file` checks if $file exists,
	# @see https://www.gnu.org/software/make/manual/html_node/Wildcard-Function.html
	# i.e. if the result is "empty" then $file does NOT exist => we are NOT in a container
	ifeq ("$(wildcard /.dockerenv)","")
		FORCE_RUN_IN_CONTAINER=1
	endif
endif
ifeq ($(FORCE_RUN_IN_CONTAINER),1)
	# These variables need to be lazy so that the arguments can be customized from targets.
	MAYBE_EXEC_IN_DOCKER=$(DOCKER_COMPOSE) exec $(DOCKER_EXEC_ARGS) --user $(LOCAL_USER_NAME) $(SERVICE)
	MAYBE_EXEC_IN_WP_SERVICE=$(DOCKER_COMPOSE) exec $(DOCKER_EXEC_ARGS) --user $(LOCAL_USER_NAME) $(DOCKER_SERVICE_WP_NAME)
endif

#
# =================================================================
# General purpose docker commands
# =================================================================
#
# The following docker commands will all run automatically
# with the correct environment, location, etc.
#
# This works by using the DOCKER_COMPOSER macro we defined above.
#
.PHONY: docker-config
docker-config: _validate-docker-env ## List the merged docker configuration.
	$(DOCKER_COMPOSE) config

.PHONY: docker-build
docker-build: SERVICE?=
docker-build: _validate-docker-env ## Build one or more docker image(s). Usage: make docker-build SERVICE=<service...>.
	$(DOCKER_COMPOSE) build $(SERVICE) $(ARGS)

.PHONY: docker-up
docker-up: SERVICE?=
docker-up: MODE?=--build --detach
docker-up: _validate-docker-env ## Start one or more docker container(s). Usage make docker-up SERVICE=<service...>
	$(DOCKER_COMPOSE) up $(MODE) $(SERVICE)

.PHONY: up
up: docker-up

.PHONY: docker-down
docker-down: _validate-docker-env ## Stop all docker containers of the current project.
	$(DOCKER_COMPOSE) down $(ARGS)

.PHONY: docker-down-v
docker-down-v: _validate-docker-env ## Delete all containers and volumes of the current project.
	$(DOCKER_COMPOSE) down -v

.PHONY: dvp
dvp: docker-down-v

.PHONY: docker-down-all
docker-down-all: _validate-docker-env ## Remove docker all containers of all projects.
	docker rm -f $$(docker ps -a -q) || true

.PHONY: docker-prune-all-volumes
docker-prune-all-volumes: ## Remove ALL docker volumes.
	docker volume prune -f

.PHONY: docker-restart
docker-restart: docker-down docker-up ## Restart all containers of the current project.

.PHONY: docker-run
docker-run: CMD?=/bin/sh
docker-run: DOCKER_RUN_ARGS?=-i
docker-run: _validate-docker-env ## Run a command inside a docker container. Usage make docker-run SERVICE=app CMD="php -v".
	@$(if $(SERVICE),,$(error SERVICE is undefined))
	$(DOCKER_COMPOSE) run --user $(LOCAL_USER_NAME) $(DOCKER_RUN_ARGS) --rm  $(SERVICE) $(CMD)

.PHONY: docker-push
docker-push: SERVICE?=
docker-push: _validate-docker-env ## Push image(s) to a remote registry. Usage make docker-push SERVICE=<service...>".
	$(DOCKER_COMPOSE) push $(SERVICE)

.PHONY: docker-pull
docker-pull: SERVICE?=
docker-pull: _validate-docker-env ## Pull image(s) from a remote registry Usage make docker-push SERVICE=<service...>.
	$(DOCKER_COMPOSE) pull $(SERVICE)

.PHONY: docker-copy
docker-copy: ## Copy files from a docker container to the host Usage: make docker-copy SERVICE=<service> FROM<container_path> TO<host_path>.
	@$(if $(SERVICE),,$(error SERVICE is undefined))
	@$(if $(FROM),,$(error FROM is undefined))
	@$(if $(TO),,$(error TO is undefined))
	$(DOCKER_COMPOSE) cp $(SERVICE):$(FROM) $(TO)

.PHONY: _validate-docker-env
_validate-docker-env:
	@$(if $(LOCAL_USER_NAME),,$(error LOCAL_USER_NAME is undefined - Did you run make setup?))
	@$(if $(LOCAL_GROUP_NAME),,$(error LOCAL_GROUP_NAME is undefined - Did you run make setup?))
	@$(if $(LOCAL_USER_ID),,$(error LOCAL_USER_ID is undefined - Did you run make setup?))
	@$(if $(LOCAL_GROUP_ID),,$(error LOCAL_GROUP_ID is undefined - Did you run make setup?))
	@$(if $(DOCKER_REGISTRY),,$(error DOCKER_REGISTRY is undefined - Did you run make setup?))
	@$(if $(DOCKER_NAMESPACE),,$(error DOCKER_NAMESPACE is undefined - Did you run make setup?))
	@$(if $(SITE_HOST),,$(error APP_HOST is undefined - Did you run make setup?))
	@$(if $(WP_CONTAINER_WP_PATH),,$(error WP_CONTAINER_WP_PATH is undefined - Did you run make setup?))
