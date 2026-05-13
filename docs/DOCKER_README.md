#  CourseFlow - Plataforma de Gestión de Cursos
## Con PostgreSQL en Docker

![Version](https://img.shields.io/badge/version-1.0-blue)
![Status](https://img.shields.io/badge/status-active-green)
![Docker](https://img.shields.io/badge/docker-ready-brightgreen)
![PostgreSQL](https://img.shields.io/badge/postgresql-16-blue)

---

##  Descripción

**CourseFlow** es una plataforma fullstack para la gestión completa de cursos, solicitudes de inscripción y lista de espera. Diseñada para Somos F5, permite:

-  Gestión centralizada de cursos
-  Sistema de solicitudes de inscripción
-  **Lista de espera automática** con promociones
-  Panel de administrador
-  Panel de usuario
-  Auditoría completa de operaciones

---

##  Stack Técnico

| Componente | Tecnología |
|-----------|-----------|
| **Base de Datos** | PostgreSQL 16 |
| **Contenedorización** | Docker & Docker Compose |
| **Backend** | Python (Flask/FastAPI) |
| **Frontend** | Vue.js 3 |
| **ORM** | SQLAlchemy 2.0 |
| **Autenticación** | JWT |
| **Hosting** | Docker (local/cloud) |

---

##  Estructura del Proyecto

```
PEDAGOGICO/
├── docker-compose.yml           # Configuración de servicios
├── init-db.sql                  # Script SQL de inicialización
├── seed-db.sql                  # Datos de prueba
├── init-docker.sh               # Script de setup automático
├── db_config.py                 # Configuración de conexión
├── models_sqlalchemy.py         # Modelos ORM
├── .env.example                 # Variables de entorno
├── .gitignore                   # Archivos ignorados
│
├── docs/                        # Documentación
│   └── *.md, *.uml
│
├── modelo_er_courseflow.json    # Modelo ER para drawDB
├── modelo_er_courseflow.sql     # SQL con tablas/índices/vistas
├── MODELO_ER.md                 # Documentación ER
├── DIAGRAMA_ER_MERMAID.md       # Diagramas visuales
├── README_MODELO.md             # Guía de uso del modelo
│
└── DOCKER_POSTGRES_SETUP.md     # Esta guía completa
```

---

## ⚡ Inicio Rápido (5 minutos)

### 1️ Clonar el Proyecto
```bash
cd /home/penascalf5/PEDAGOGICO
```

### 2️ Configurar Variables de Entorno
```bash
cp .env.example .env
# Opcionalmente editar .env con tus valores
```

### 3️ Ejecutar Setup Automático
```bash
./init-docker.sh
```

O **manualmente**:
```bash
docker-compose up -d
```

### 4️ Verificar que Todo Funciona
```bash
docker-compose ps
```

### 5️ Acceder a la BD

**Opción A - pgAdmin (Recomendado):**
- URL: [http://localhost:5050](http://localhost:5050)
- Email: `admin@courseflow.dev`
- Password: `admin123`

**Opción B - CLI:**
```bash
docker exec -it courseflow-db psql -U courseflow_user -d courseflow
```

---

##  Comandos Docker Útiles

### Ver Estado
```bash
docker-compose ps                    # Estado de servicios
docker-compose logs postgres         # Últimos logs
docker-compose logs -f postgres      # Logs en tiempo real
```

### Gestión
```bash
docker-compose up -d                 # Iniciar
docker-compose down                  # Detener (mantiene datos)
docker-compose down -v               # Detener y eliminar todo
docker-compose restart               # Reiniciar
docker-compose restart postgres      # Reiniciar solo postgres
```

### Conexión
```bash
# Entrar a psql
docker exec -it courseflow-db psql -U courseflow_user -d courseflow

# Ejecutar query
docker exec -it courseflow-db psql -U courseflow_user -d courseflow -c "SELECT * FROM usuarios;"

# Backup
docker exec courseflow-db pg_dump -U courseflow_user courseflow > backup.sql

# Restore
docker exec -i courseflow-db psql -U courseflow_user courseflow < backup.sql
```

---

##  Modelos de Datos

### Entidades Principales

```
USUARIOS (1)
├── (1:N) → SOLICITUDES
├── (1:N) → LISTA_ESPERA
└── (1:N) → AUDITORIA

CURSOS (1)
├── (1:N) → SOLICITUDES
└── (1:N) → LISTA_ESPERA

SOLICITUDES (1)
└── (1:N) → LISTA_ESPERA
```

### Estados de Solicitud
- `pendiente` - Esperando revisión
- `aceptado` - Usuario aceptado
- `rechazado` - Usuario rechazado
- `cancelado` - Usuario se dio de baja
- `no_presentado` - Usuario no asistió

### Estados de Lista de Espera
- `en_espera` - En fila de espera
- `promovido` - Promovido a aceptado
- `rechazado` - Rechazado desde lista

---

##  Conectar desde la Aplicación

### Flask
```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from db_config import FLASK_SQLALCHEMY_CONFIG

app = Flask(__name__)
app.config.update(FLASK_SQLALCHEMY_CONFIG)
db = SQLAlchemy(app)

# Crear tablas (primera vez)
with app.app_context():
    db.create_all()
```

### FastAPI (Async)
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from db_config import DatabaseConfig

DATABASE_URL = DatabaseConfig.get_connection_string('docker', 'asyncpg')

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

### Conexión Directa (psycopg2)
```python
import psycopg2
from db_config import DatabaseConfig

config = DatabaseConfig.get_config('docker')
conn = psycopg2.connect(
    host='localhost',
    user=config['user'],
    password=config['password'],
    database=config['database'],
    port=config['port']
)

cursor = conn.cursor()
cursor.execute("SELECT * FROM usuarios;")
print(cursor.fetchall())
```

---

##  Vistas SQL Disponibles

### `vista_ocupacion_cursos`
Resumen de ocupación por curso:
```sql
SELECT * FROM vista_ocupacion_cursos;
```

### `vista_candidatos_por_curso`
Candidatos con sus estados:
```sql
SELECT * FROM vista_candidatos_por_curso WHERE id_curso = 1;
```

### `vista_mis_solicitudes_usuario`
Solicitudes del usuario en todos los cursos:
```sql
SELECT * FROM vista_mis_solicitudes_usuario WHERE id_usuario = 10;
```

---

##  Seguridad

### Credenciales por Defecto (Cambiar en Producción)

| Variable | Defecto | Cambiar en Producción |
|----------|---------|-----|
| POSTGRES_USER | courseflow_user |  |
| POSTGRES_PASSWORD | courseflow_pass |  |
| DB_NAME | courseflow |  |
| PGADMIN_PASSWORD | admin123 |  |

### Mejores Prácticas
```bash
# 1. Usar .env.local para overrides
cp .env .env.local

# 2. No commitear .env
git config core.hooksPath ./.githooks

# 3. Usar variables de entorno en producción
export DB_PASSWORD="secure_password"

# 4. Limitar acceso a puertos
# En firewall: solo 5432 para aplicación interna
```

---

## Testing

### Test de Conexión
```bash
python3 test_db.py
```

O manualmente:
```bash
docker exec -it courseflow-db psql \
  -U courseflow_user \
  -d courseflow \
  -c "SELECT COUNT(*) FROM usuarios;"
```

### Verificar Tablas
```bash
docker exec -it courseflow-db psql \
  -U courseflow_user \
  -d courseflow \
  -c "\dt"
```

### Ver Datos de Prueba
```bash
docker exec -it courseflow-db psql \
  -U courseflow_user \
  -d courseflow \
  -c "SELECT id_usuario, nombre, email, rol FROM usuarios;"
```

---

##  Logs y Debugging

### Ver Logs
```bash
# Últimas 50 líneas
docker-compose logs --tail=50 postgres

# Seguimiento en tiempo real
docker-compose logs -f postgres

# Solo errores
docker-compose logs postgres 2>&1 | grep ERROR
```

### Habilitar Debug SQL
```python
# En db_config.py cambiar a:
'SQLALCHEMY_ECHO': True,
```

---

## Solución de Problemas

### Puerto 5432 ya en uso
```bash
# Opción 1: Cambiar puerto en docker-compose.yml
# ports:
#   - "5433:5432"

# Opción 2: Eliminar proceso que usa el puerto
lsof -i :5432
kill -9 <PID>
```

### "Connection refused"
```bash
# Verificar que postgres esté corriendo
docker ps | grep postgres

# Si no está, levantarlo
docker-compose up -d postgres

# Esperar a que esté listo
docker-compose exec postgres pg_isready -U courseflow_user
```

### Credenciales incorrectas
```bash
# Verificar en docker-compose.yml
cat docker-compose.yml | grep POSTGRES

# Verificar en .env
cat .env | grep DB_
```

### Datos corruptos, empezar de cero
```bash
docker-compose down -v
rm -rf postgres_data
docker-compose up -d
```

---

##  Documentación Adicional

| Documento | Contenido |
|-----------|----------|
| [MODELO_ER.md](./MODELO_ER.md) | Especificación técnica del modelo |
| [DIAGRAMA_ER_MERMAID.md](./DIAGRAMA_ER_MERMAID.md) | Diagramas visuales |
| [DOCKER_POSTGRES_SETUP.md](./DOCKER_POSTGRES_SETUP.md) | Guía detallada Docker |
| [README_MODELO.md](./README_MODELO.md) | Guía de uso del modelo |

---

##  Deployment

### Local (Desarrollo)
```bash
./init-docker.sh
# Ya está listo en http://localhost:5050
```

### Servidor
```bash
# 1. SSH a servidor
ssh user@server

# 2. Clonar repo
git clone <repo> courseflow
cd courseflow

# 3. Configurar .env con valores seguros
nano .env

# 4. Levantar
docker-compose up -d

# 5. Configurar reverse proxy (nginx)
# Ver nginx.conf en documentación
```

### Cloud (AWS/DigitalOcean/etc)
```bash
# Usar RDS para PostgreSQL en lugar de container
# O usar DockerHub para imagen personalizada
docker build -t courseflow:latest .
docker tag courseflow:latest <account>.dkr.ecr.<region>.amazonaws.com/courseflow
docker push <account>.dkr.ecr.<region>.amazonaws.com/courseflow
```

---

##  Equipo

- **Formadores:** Equipo Pedagógico Somos F5
- **Proyecto:** CourseFlow
- **Organización:** Somos F5
- **Stack:** Python/Flask + Vue.js + PostgreSQL

---

##  Soporte

Para problemas:
1. Revisar [DOCKER_POSTGRES_SETUP.md](./DOCKER_POSTGRES_SETUP.md)
2. Revisar logs: `docker-compose logs -f`
3. Contactar al equipo de desarrollo

---

##  Versiones

- **v1.0** (13-05-2026) - Versión inicial con PostgreSQL en Docker

---

##  Licencia

Este proyecto es educativo para Somos F5.

---

** ¿Te fue útil? Deja una estrella en el repo**

Última actualización: **13 de mayo de 2026**
