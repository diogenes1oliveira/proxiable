
DOCKER ?= docker
DOCKER_COMPOSE ?= docker-compose
FLAKE8 ?= flake8

IMAGE ?= diogenes1oliveira/proxiable
export IMAGE

.PHONY: build
build:
	@$(DOCKER) build -t $(IMAGE) .

.PHONY: lint
lint:
	@$(DOCKER) run --rm hadolint/hadolint < Dockerfile
	@$(FLAKE8) *.py

.PHONY: test
test:
	@bats --tap test/*.bats

.PHONY: up
up:
	@$(DOCKER_COMPOSE) up -d

.PHONY: rm
rm:
	@$(DOCKER_COMPOSE) kill
	@$(DOCKER_COMPOSE) rm -f -v
	@$(DOCKER) network prune -f
	@$(DOCKER) volume prune -f

.PHONY: logs
logs:
	@$(DOCKER_COMPOSE) logs -f
