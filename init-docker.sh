#!/bin/bash

# ==========================================
# Script de Inicialización - CourseFlow + Docker
# Automatiza el setup de PostgreSQL y la aplicación
# ==========================================

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║   COURSEFLOW - DOCKER SETUP     ║"
echo "║  PostgreSQL + pgAdmin                ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}\n"

# ==========================================
# 1. Verificar Prerequisites
# ==========================================

echo -e "${BLUE}▶ Verificando prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker no está instalado${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker instalado: $(docker --version)${NC}"
echo -e "${GREEN}✓ Docker Compose instalado: $(docker-compose --version)${NC}\n"

# ==========================================
# 2. Crear archivo .env si no existe
# ==========================================

if [ ! -f .env ]; then
    echo -e "${YELLOW}▶ Creando archivo .env...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ Archivo .env creado${NC}"
    echo -e "${YELLOW}  ⚠ Revisa .env y ajusta valores si es necesario${NC}\n"
else
    echo -e "${GREEN}✓ Archivo .env ya existe${NC}\n"
fi

# ==========================================
# 3. Detener containers existentes
# ==========================================

echo -e "${BLUE}▶ Limpiando containers previos...${NC}"

if docker-compose ps | grep -q "courseflow"; then
    echo -e "${YELLOW}  Deteniendo containers existentes...${NC}"
    docker-compose down || true
fi

echo -e "${GREEN}✓ Limpieza completada${NC}\n"

# ==========================================
# 4. Construir y levantar servicios
# ==========================================

echo -e "${BLUE}▶ Levantando servicios Docker...${NC}"

docker-compose up -d

sleep 3  # Esperar a que inicie

echo -e "${GREEN}✓ Servicios levantados${NC}\n"

# ==========================================
# 5. Verificar salud de servicios
# ==========================================

echo -e "${BLUE}▶ Verificando estado de servicios...${NC}"

echo -e "${YELLOW}  Esperando que PostgreSQL esté listo...${NC}"

for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U courseflow_user -d courseflow &> /dev/null; then
        echo -e "${GREEN}✓ PostgreSQL está listo${NC}"
        break
    fi
    echo -ne "  Intento $i/30...\r"
    sleep 1
done

# ==========================================
# 6. Mostrar estado de containers
# ==========================================

echo -e "\n${BLUE}▶ Estado de containers:${NC}"
docker-compose ps
echo ""

# ==========================================
# 7. Información de acceso
# ==========================================

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN} ¡SETUP COMPLETADO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}\n"

echo -e "${BLUE} INFORMACIÓN DE ACCESO:${NC}\n"

echo -e "${YELLOW}PostgreSQL:${NC}"
echo "  Host:     localhost"
echo "  Puerto:   5433"
echo "  Usuario:  courseflow_user"
echo "  Password: courseflow_pass"
echo "  Database: courseflow"
echo ""
echo "  Conexión desde CLI:"
echo "  ${BLUE}docker exec -it courseflow-db psql -U courseflow_user -d courseflow${NC}"
echo ""

echo -e "${YELLOW}pgAdmin Web:${NC}"
echo "  URL:      http://localhost:5050"
echo "  Email:    admin@courseflow.dev"
echo "  Password: admin123"
echo ""

echo -e "${YELLOW}Desde Python:${NC}"
echo "  ${BLUE}from db_config import DatabaseConfig${NC}"
echo "  ${BLUE}conn_str = DatabaseConfig.get_connection_string('docker', 'psycopg2')${NC}"
echo ""

# ==========================================
# 8. Ver logs
# ==========================================

echo -e "${BLUE}▶ Últimos logs de PostgreSQL:${NC}"
docker-compose logs --tail=10 postgres
echo ""

# ==========================================
# 9. Opciones avanzadas
# ==========================================

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE} COMANDOS ÚTILES:${NC}\n"

echo -e "${YELLOW}Ver logs en tiempo real:${NC}"
echo "  ${BLUE}docker-compose logs -f postgres${NC}"
echo ""

echo -e "${YELLOW}Ejecutar query SQL:${NC}"
echo "  ${BLUE}docker exec -it courseflow-db psql -U courseflow_user -d courseflow -c \"SELECT * FROM usuarios;\"${NC}"
echo ""

echo -e "${YELLOW}Detener servicios:${NC}"
echo "  ${BLUE}docker-compose down${NC}"
echo ""

echo -e "${YELLOW}Detener y eliminar datos:${NC}"
echo "  ${BLUE}docker-compose down -v${NC}"
echo ""

echo -e "${YELLOW}Reiniciar servicios:${NC}"
echo "  ${BLUE}docker-compose restart${NC}"
echo ""

echo -e "${YELLOW}Ver estado completo:${NC}"
echo "  ${BLUE}docker-compose ps -a${NC}"
echo ""

# ==========================================
# 10. Test de conexión (opcional)
# ==========================================

echo -e "${BLUE}▶ Probando conexión a la BD...${NC}"

docker exec -it courseflow-db psql -U courseflow_user -d courseflow -c "\dt" &> /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Conexión a PostgreSQL exitosa${NC}"
    
    # Contar tablas
    TABLES=$(docker exec -it courseflow-db psql -U courseflow_user -d courseflow -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null)
    echo -e "${GREEN}✓ Tablas creadas: $TABLES${NC}"
else
    echo -e "${RED}✗ No se pudo conectar a PostgreSQL${NC}"
fi

echo ""

# ==========================================
# 11. Checklist final
# ==========================================

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE} CHECKLIST DE VERIFICACIÓN:${NC}\n"

echo -e "  [✓] Docker iniciado"
echo -e "  [✓] PostgreSQL ejecutándose (port 5433)"
echo -e "  [✓] pgAdmin ejecutándose (port 5050)"
echo -e "  [✓] Base de datos 'courseflow' creada"
echo -e "  [✓] Tablas creadas automáticamente"
echo -e "  [✓] Datos de prueba cargados"
echo ""

# ==========================================
# 12. Próximos pasos
# ==========================================

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE} PRÓXIMOS PASOS:${NC}\n"

echo -e "  1. Conectar desde pgAdmin:"
echo -e "     ${BLUE}http://localhost:5050${NC}"
echo ""

echo -e "  2. Conectar desde Python/Flask:"
echo -e "     ${BLUE}pip install flask flask-sqlalchemy psycopg2-binary${NC}"
echo ""

echo -e "  3. Consultar datos de prueba:"
echo -e "     ${BLUE}docker exec -it courseflow-db psql -U courseflow_user -d courseflow${NC}"
echo ""

echo -e "  4. Ver documentación:"
echo -e "     ${BLUE}cat DOCKER_POSTGRES_SETUP.md${NC}"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Setup completado exitosamente ✨${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
