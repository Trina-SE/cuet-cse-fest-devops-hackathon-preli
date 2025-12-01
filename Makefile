## Docker Services:
##   up           - Start services (use: make up [SERVICE=...] or MODE=prod, ARGS="--build" for options)
##   down         - Stop services (use: make down MODE=prod, ARGS="--volumes" for options)
##   build        - Build containers (use: make build [SERVICE=backend] or make build MODE=prod)
##   logs         - View logs (use: make logs [SERVICE=backend] or MODE=prod for production)
##   restart      - Restart services (use: make restart [SERVICE=backend] or MODE=prod)
##   shell        - Open shell in container (use: make shell [SERVICE=gateway] or MODE=prod, default: backend)
##   ps           - Show running containers (use MODE=prod for production)
##
## Convenience Aliases (Development):
##   dev-up       - Start development environment
##   dev-down     - Stop development environment
##   dev-build    - Build development containers
##   dev-logs     - View development logs
##   dev-restart  - Restart development services
##   dev-shell    - Open shell in backend container (dev)
##   dev-ps       - Show running development containers
##   backend-shell- Open shell in backend container
##   gateway-shell- Open shell in gateway container
##   mongo-shell  - Open MongoDB shell
##
## Convenience Aliases (Production):
##   prod-up      - Start production environment
##   prod-down    - Stop production environment
##   prod-build   - Build production containers
##   prod-logs    - View production logs
##   prod-restart - Restart production services
##
## Backend:
##   backend-build      - Build backend TypeScript
##   backend-install    - Install backend dependencies
##   backend-type-check - Type check backend code
##   backend-dev        - Run backend in development mode (local, not Docker)
##
## Database:
##   db-reset   - Reset MongoDB database (WARNING: deletes all data)
##   db-backup  - Backup MongoDB database
##
## Cleanup:
##   clean         - Remove containers and networks (both dev and prod)
##   clean-all     - Remove containers, networks, volumes, and images
##   clean-volumes - Remove all volumes
##
## Utilities:
##   status  - Alias for ps
##   health  - Check service health
##
## Help:
##   help    - Display this help message

SHELL := /bin/sh

MODE ?= dev
SERVICE ?=
ARGS ?=

COMPOSE_DEV := docker/compose.development.yaml
COMPOSE_PROD := docker/compose.production.yaml

ifeq ($(MODE),prod)
  COMPOSE_FILE := $(COMPOSE_PROD)
else
  COMPOSE_FILE := $(COMPOSE_DEV)
endif

COMPOSE := docker compose -f $(COMPOSE_FILE)

.PHONY: up down build logs restart shell ps \
        dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps \
        backend-shell gateway-shell mongo-shell \
        prod-up prod-down prod-build prod-logs prod-restart \
        backend-build backend-install backend-type-check backend-dev \
        db-reset db-backup \
        clean clean-all clean-volumes \
        status health help

up:
	$(COMPOSE) up -d $(SERVICE) $(ARGS)

down:
	$(COMPOSE) down $(ARGS)

build:
	$(COMPOSE) build $(SERVICE)

logs:
	$(COMPOSE) logs -f $(SERVICE)

restart:
	$(COMPOSE) restart $(SERVICE)

shell:
	@if [ -z "$(SERVICE)" ]; then \
	  S=backend; \
	else \
	  S=$(SERVICE); \
	fi; \
	$(COMPOSE) exec $$S /bin/sh

ps:
	$(COMPOSE) ps

## Development aliases
dev-up:
	$(MAKE) up MODE=dev

dev-down:
	$(MAKE) down MODE=dev

dev-build:
	$(MAKE) build MODE=dev

dev-logs:
	$(MAKE) logs MODE=dev

dev-restart:
	$(MAKE) restart MODE=dev

dev-shell:
	$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	$(MAKE) ps MODE=dev

backend-shell:
	$(MAKE) shell SERVICE=backend

gateway-shell:
	$(MAKE) shell SERVICE=gateway

mongo-shell:
	$(COMPOSE) exec mongo mongosh -u $$MONGO_INITDB_ROOT_USERNAME -p $$MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin

## Production aliases
prod-up:
	$(MAKE) up MODE=prod

prod-down:
	$(MAKE) down MODE=prod

prod-build:
	$(MAKE) build MODE=prod

prod-logs:
	$(MAKE) logs MODE=prod

prod-restart:
	$(MAKE) restart MODE=prod

## Backend tooling (host, not Docker)
backend-build:
	cd backend && npm run build

backend-install:
	cd backend && npm install

backend-type-check:
	cd backend && npm run type-check

backend-dev:
	cd backend && npm run dev

## Database utilities (operate on dev by default)
db-reset:
	$(COMPOSE) down -v
	$(COMPOSE) up -d mongo

db-backup:
	@backup_dir=./backups; \
	mkdir -p $$backup_dir; \
	timestamp=$$(date +%Y%m%d-%H%M%S); \
	$(COMPOSE) exec -T mongo mongodump -u $$MONGO_INITDB_ROOT_USERNAME -p $$MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin --out /dump/$$timestamp; \
	$(COMPOSE) cp mongo:/dump $$backup_dir/$$timestamp

## Cleanup
clean:
	docker compose -f $(COMPOSE_DEV) down || true
	docker compose -f $(COMPOSE_PROD) down || true

clean-all:
	docker compose -f $(COMPOSE_DEV) down -v || true
	docker compose -f $(COMPOSE_PROD) down -v || true

clean-volumes:
	docker volume prune -f

status: ps

health:
	@echo "Gateway health:"; curl -s http://localhost:5921/health || true; echo
	@echo "Backend health via gateway:"; curl -s http://localhost:5921/api/health || true; echo

help:
	@grep "^##" Makefile | sed 's/^## //'


