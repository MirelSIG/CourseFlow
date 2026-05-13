# ==========================================
# Makefile - CourseFlow
# Simplifica comandos comunes de Docker/BD
# ==========================================

.PHONY: help up down restart logs db shell test clean build

# Colores
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

# Variables
DOCKER_COMPOSE := docker-compose
DB_CONTAINER := courseflow-db
DB_USER := courseflow_user
DB_PASSWORD := courseflow_pass
DB_NAME := courseflow

help:
	@echo "$(BLUE)╔═══════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  CourseFlow - Docker Makefile        ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Comandos disponibles:$(NC)"
	@echo ""
	@echo "  $(YELLOW)make up$(NC)              - Levantar servicios"
	@echo "  $(YELLOW)make down$(NC)            - Detener servicios"
	@echo "  $(YELLOW)make restart$(NC)         - Reiniciar servicios"
	@echo "  $(YELLOW)make logs$(NC)            - Ver logs en tiempo real"
	@echo "  $(YELLOW)make logs-postgres$(NC)   - Ver logs de PostgreSQL"
	@echo "  $(YELLOW)make status$(NC)          - Ver estado de servicios"
	@echo ""
	@echo "  $(YELLOW)make db-shell$(NC)        - Entrar a psql"
	@echo "  $(YELLOW)make db-test$(NC)         - Test de conexión BD"
	@echo "  $(YELLOW)make db-backup$(NC)       - Backup de BD"
	@echo "  $(YELLOW)make db-restore FILE=$(NC) - Restaurar BD desde backup"
	@echo "  $(YELLOW)make db-reset$(NC)        - Reset total de BD"
	@echo ""
	@echo "  $(YELLOW)make shell-postgres$(NC)  - Shell del container"
	@echo "  $(YELLOW)make prune$(NC)           - Limpiar containers/volúmenes"
	@echo "  $(YELLOW)make clean$(NC)           - Limpieza completa"
	@echo ""
	@echo "  $(YELLOW)make query SQL=$(NC)      - Ejecutar query SQL"
	@echo "  $(YELLOW)make tables$(NC)          - Listar tablas"
	@echo "  $(YELLOW)make users$(NC)           - Listar usuarios"
	@echo "  $(YELLOW)make courses$(NC)         - Listar cursos"
	@echo "  $(YELLOW)make categories$(NC)      - Listar categorías"
	@echo ""

up:
	@echo "$(BLUE)▶ Levantando servicios...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@sleep 2
	@echo "$(GREEN)✓ Servicios levantados$(NC)"
	$(MAKE) status

down:
	@echo "$(BLUE)▶ Deteniendo servicios...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✓ Servicios detenidos$(NC)"

restart:
	@echo "$(BLUE)▶ Reiniciando servicios...$(NC)"
	$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)✓ Servicios reiniciados$(NC)"

status:
	@echo "$(BLUE)Estado de servicios:$(NC)"
	$(DOCKER_COMPOSE) ps

logs:
	@$(DOCKER_COMPOSE) logs -f

logs-postgres:
	@$(DOCKER_COMPOSE) logs -f postgres

db-shell:
	@echo "$(BLUE)Conectando a PostgreSQL...$(NC)"
	$(DOCKER_COMPOSE) exec postgres psql -U $(DB_USER) -d $(DB_NAME)

db-test:
	@echo "$(BLUE)▶ Probando conexión a BD...$(NC)"
	@$(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME) -c "SELECT COUNT(*) FROM usuarios;" && \
		echo "$(GREEN)✓ Conexión exitosa$(NC)" || echo "$(RED)✗ Error de conexión$(NC)"

db-backup:
	@echo "$(BLUE)▶ Creando backup de BD...$(NC)"
	@mkdir -p backups
	@$(DOCKER_COMPOSE) exec -T postgres pg_dump -U $(DB_USER) $(DB_NAME) > backups/courseflow_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✓ Backup creado$(NC)"

db-restore:
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)Error: especificar archivo con FILE=path/to/backup.sql$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)▶ Restaurando BD desde $(FILE)...$(NC)"
	@cat $(FILE) | $(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME)
	@echo "$(GREEN)✓ BD restaurada$(NC)"

db-reset:
	@echo "$(RED)⚠ ADVERTENCIA: Esto eliminará TODOS los datos$(NC)"
	@read -p "¿Continuar? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(BLUE)▶ Reseteando BD...$(NC)"; \
		$(DOCKER_COMPOSE) down -v; \
		$(DOCKER_COMPOSE) up -d; \
		sleep 3; \
		echo "$(GREEN)✓ BD resetada$(NC)"; \
	else \
		echo "$(YELLOW)Cancelado$(NC)"; \
	fi

shell-postgres:
	@echo "$(BLUE)Entrando a shell del container...$(NC)"
	@$(DOCKER_COMPOSE) exec postgres bash

tables:
	@echo "$(BLUE)Tablas en la BD:$(NC)"
	@$(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME) \
		-c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"

users:
	@echo "$(BLUE)Usuarios registrados:$(NC)"
	@$(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME) \
		-c "SELECT id_usuario, nombre, email, rol, estado FROM usuarios;"

courses:
	@echo "$(BLUE)Cursos disponibles:$(NC)"
	@$(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME) \
		-c "SELECT c.id_curso, c.nombre, cat.nombre AS categoria, c.capacidad, c.estado FROM cursos c INNER JOIN categorias cat ON c.id_categoria = cat.id_categoria ORDER BY cat.nombre, c.nombre;"

categories:
	@echo "$(BLUE)Categorías disponibles:$(NC)"
	@$(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME) \
		-c "SELECT id_categoria, nombre, activo FROM categorias ORDER BY nombre;"

query:
	@if [ -z "$(SQL)" ]; then \
		echo "$(RED)Error: especificar query con SQL='...'$(NC)"; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec -T postgres psql -U $(DB_USER) -d $(DB_NAME) -c "$(SQL);"

prune:
	@echo "$(YELLOW)▶ Limpiando recursos de Docker...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

clean: down
	@echo "$(RED)▶ Limpieza completa (datos incluidos)...$(NC)"
	@$(DOCKER_COMPOSE) down -v
	@rm -rf postgres_data pgadmin_data
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

build:
	@echo "$(BLUE)▶ Construyendo images...$(NC)"
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)✓ Images construidas$(NC)"

init:
	@echo "$(BLUE)╔═══════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  Inicialización de CourseFlow       ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════╝$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Creando .env...$(NC)"; \
		cp .env.example .env; \
	fi
	@$(MAKE) up
	@$(MAKE) db-test
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo "$(GREEN) Inicialización completada$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Próximos pasos:$(NC)"
	@echo "  - pgAdmin: http://localhost:5050"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - Ver documentación: cat DOCKER_README.md"

# Alias útiles
ps: status
start: up
stop: down

# Desarrollo
dev-logs:
	@$(MAKE) logs

dev-shell:
	@$(MAKE) db-shell

# Default
.DEFAULT_GOAL := help
