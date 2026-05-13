# Docker Configuration Guide for CourseFlow

## Problema Identificado

El intento de descargar imágenes de Docker fallaba con:
```
httpReadSeeker: failed open: failed to do request: ... context deadline exceeded
```

Esto puede ser causado por:
1. Problemas de conectividad a los registros de Docker (Cloudflare, Docker Hub)
2. Firewall o restricciones de red
3. Timeout de conexión insuficiente

## Soluciones Aplicadas

### 1. Configuración de Docker Mirrors
Se agregaron mirrors alternativos en `~/.docker/daemon.json`:
```json
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ],
  "max-concurrent-downloads": 5,
  "max-concurrent-uploads": 5
}
```

### 2. Optimización de docker-compose.yml
- Cambio de `postgres:15` a `postgres:15-alpine` (imagen más pequeña)
- Agregado healthcheck para PostgreSQL
- Especificación explícita de contexto y Dockerfile
- Dependencia condicional en healthcheck

### 3. Alternativa: Desarrollo Local sin Docker

Si Docker sigue con problemas, usa la configuración SQLite:

```bash
# Ejecutar setup
bash setup_dev.sh

# Activar venv y ejecutar servidor
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Opción 1: Docker (Recomendado para producción)

```bash
# Limpiar contenedores viejos
docker-compose down -v

# Reintentar levantamiento
docker-compose up --build

# En caso de problemas, hacer pull manual
docker pull postgres:15-alpine
docker pull dpage/pgadmin4:latest
```

## Opción 2: Desarrollo Local (SQLite)

```bash
# Ejecutar setup automático
bash setup_dev.sh

# Iniciar servidor
source venv/bin/activate
uvicorn app.main:app --reload
```

**Ventajas:**
- No requiere Docker
- Inicio rápido
- Perfecto para desarrollo local
- BD SQLite incluida

**Desventajas:**
- SQLite no es para producción
- Rendimiento limitado en concurrencia

## Opción 3: PostgreSQL Local (sin Docker)

```bash
# Instalar PostgreSQL en tu máquina
brew install postgresql

# Iniciar servicio
brew services start postgresql

# Crear BD
createdb courseflow_db

# Actualizar config
export SQLALCHEMY_DATABASE_URI="postgresql://localhost/courseflow_db"
```

## Próximos Pasos

1. Intentar nuevamente: `docker-compose up --build`
2. Si falla, usar: `bash setup_dev.sh`
3. Validar endpoints con: `python test_local_api.py`

## Debugging Docker

```bash
# Ver logs de Docker
docker logs courseflow_db

# Ver imagenes descargadas
docker images

# Reiniciar Docker daemon
# En macOS: Quit Docker.app y volver a abrir

# Diagnosticar conexión de red
docker pull hello-world
```
