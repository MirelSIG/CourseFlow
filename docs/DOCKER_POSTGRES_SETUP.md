#  Setup PostgreSQL en Docker - CourseFlow

##  Requisitos Previos

- Docker instalado ([descargar](https://www.docker.com/products/docker-desktop))
- Docker Compose (incluido en Docker Desktop)
- Git (para clonar/guardar el proyecto)

##  Levantando la Base de Datos

### Opción 1: Levantar todos los servicios (Recomendado)

```bash
# Navegar a la carpeta del proyecto
cd /home/penascalf5/PEDAGOGICO

# Iniciar los servicios en background
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f postgres

# Verificar que todo está funcionando
docker-compose ps
```

**Resultado esperado:**
```
NAME                COMMAND             SERVICE      STATUS      PORTS
courseflow-db       postgres            postgres     Up          0.0.0.0:5432->5432/tcp
courseflow-pgadmin  /entrypoint.sh      pgadmin      Up          0.0.0.0:5050->80/tcp
```

### Opción 2: Levantar solo PostgreSQL

```bash
# Si solo quieres la BD sin pgAdmin
docker-compose up -d postgres
```

##  Acceder a la Base de Datos

### Opción 1: Desde pgAdmin Web (Más fácil)

1. Abre tu navegador: [http://localhost:5050](http://localhost:5050)
2. Inicia sesión:
    - Email: `admin@courseflow.dev`
   - Password: `admin123`
3. Click en "Add New Server"
4. Configuración:
   - Name: `CourseFlow`
   - Host: `postgres` (nombre del container)
   - Port: `5432`
   - Username: `courseflow_user`
   - Password: `courseflow_pass`
   - Database: `courseflow`
5. ¡Listo! Ya puedes ver/ejecutar queries

### Opción 2: Desde línea de comandos

```bash
# Conectar directamente al container
docker exec -it courseflow-db psql -U courseflow_user -d courseflow

# Una vez dentro, comandos útiles:
\dt              # Listar tablas
\v               # Listar vistas
\d usuarios      # Ver estructura de tabla
SELECT * FROM usuarios;
\q               # Salir
```

### Opción 3: Desde tu aplicación Python

```python
# Con psycopg2
import psycopg2

conn = psycopg2.connect(
    host='localhost',      # O 'postgres' si está en docker-compose
    user='courseflow_user',
    password='courseflow_pass',
    database='courseflow',
    port=5432
)

cursor = conn.cursor()
cursor.execute("SELECT * FROM usuarios;")
print(cursor.fetchall())
cursor.close()
conn.close()
```

##  Verificar que la BD se creó correctamente

```bash
# Conectar y verificar
docker exec -it courseflow-db psql -U courseflow_user -d courseflow -c "\dt"

# Deberías ver 5 tablas:
# - usuarios
# - cursos
# - solicitudes
# - lista_espera
# - auditoria
```

##  Gestión del Container

### Ver logs
```bash
docker-compose logs postgres          # Últimos logs
docker-compose logs -f postgres       # En tiempo real
docker-compose logs --tail=50 postgres # Últimas 50 líneas
```

### Detener servicios
```bash
docker-compose down              # Detiene pero mantiene datos
docker-compose down -v           # Detiene y elimina volúmenes (CUIDADO!)
```

### Reiniciar servicios
```bash
docker-compose restart postgres
docker-compose restart           # Reinicia todos
```

### Ver estado de volúmenes
```bash
docker volume ls
docker volume inspect courseflow_postgres_data
```

##  Estructura de Volúmenes

Los datos persisten en volúmenes Docker:
- `postgres_data` → datos de PostgreSQL
- `pgadmin_data` → configuración de pgAdmin

```bash
# Ubicación real en el sistema (Linux)
# /var/lib/docker/volumes/courseflow_postgres_data/_data/

# Ver todo
docker volume ls
```

##  Probar la Conexión desde Python

Copia este código en `test_db.py`:

```python
#!/usr/bin/env python3

import psycopg2
from db_config import DatabaseConfig

def test_connection():
    """Prueba conexión a BD en Docker"""
    config = DatabaseConfig.get_config('docker')
    
    try:
        conn = psycopg2.connect(
            host='localhost',  # Mapeado desde Docker
            user=config['user'],
            password=config['password'],
            database=config['database'],
            port=config['port']
        )
        
        cursor = conn.cursor()
        
        # Prueba 1: Ver tablas
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        """)
        tablas = cursor.fetchall()
        print(" Tablas en la BD:")
        for tabla in tablas:
            print(f"   - {tabla[0]}")
        
        # Prueba 2: Contar usuarios
        cursor.execute("SELECT COUNT(*) FROM usuarios")
        count = cursor.fetchone()[0]
        print(f"\n Usuarios en la BD: {count}")
        
        # Prueba 3: Ver cursos
        cursor.execute("SELECT id_curso, nombre, capacidad FROM cursos LIMIT 3")
        cursos = cursor.fetchall()
        print(f"\n Primeros cursos:")
        for curso in cursos:
            print(f"   - {curso[1]} (Capacidad: {curso[2]})")
        
        cursor.close()
        conn.close()
        
        print("\n ¡Conexión exitosa!")
        
    except Exception as e:
        print(f" Error: {e}")

if __name__ == "__main__":
    test_connection()
```

Ejecutar:
```bash
python3 test_db.py
```

##  Solución de Problemas

### "Connection refused"
```bash
# Verificar que el container está corriendo
docker-compose ps

# Si no está, levantarlo
docker-compose up -d postgres
```

### "password authentication failed"
Verificar credenciales en `docker-compose.yml` y `.env`

### "Database already exists"
```bash
# Limpiar todo y empezar de nuevo
docker-compose down -v
docker-compose up -d
```

### "Port 5432 already in use"
```bash
# Ver qué usa el puerto
lsof -i :5432

# Cambiar puerto en docker-compose.yml:
# ports:
#   - "5433:5432"  # Usar 5433 en lugar de 5432
```

### Recrear BD sin perder datos
```bash
# Eliminar solo container, mantener volumen
docker-compose down

# Levantar de nuevo (datos persisten)
docker-compose up -d postgres
```

##  Herramientas Útiles

### DBeaver (GUI para BD)
- Descargar: [dbeaver.io](https://dbeaver.io)
- Conexión:
  - Host: `localhost`
  - Port: `5432`
  - Database: `courseflow`
  - User: `courseflow_user`
  - Password: `courseflow_pass`

### Comandos Útiles en psql

```bash
# Dentro del container
docker exec -it courseflow-db psql -U courseflow_user -d courseflow

# Dentro de psql:
\dt                    # Listar tablas
\v                     # Listar vistas
\d usuarios            # Ver estructura
\d+ usuarios           # Ver con más detalle
\df                    # Listar funciones
SELECT * FROM usuarios LIMIT 5;  # Ver datos
\x                     # Expandir salida
\timing                # Mostrar tiempo de queries
\copy usuarios TO 'file.csv' WITH CSV;  # Exportar
\q                     # Salir
```

##  Seguridad en Producción

Cambiar valores antes de hacer deploy:

```yaml
# docker-compose.yml
environment:
  POSTGRES_PASSWORD: "tu_password_seguro_aqui"
  POSTGRES_USER: "nuevo_usuario"

# .env
POSTGRES_PASSWORD=otro_password_diferente
PGADMIN_DEFAULT_PASSWORD=otro_admin_pass
```

##  Checklist de Setup

- [ ] Docker instalado
- [ ] docker-compose.yml en proyecto
- [ ] init-db.sql en proyecto
- [ ] seed-db.sql en proyecto
- [ ] Ejecutar `docker-compose up -d`
- [ ] Verificar logs: `docker-compose logs postgres`
- [ ] Acceder a pgAdmin: http://localhost:5050
- [ ] Conectar desde Python
- [ ] Ver datos de prueba en BD
- [ ] Backup de datos (opcional)

##  Próximos Pasos

1. **Conectar backend**
   ```bash
   pip install flask flask-sqlalchemy psycopg2-binary
   # Usar db_config.py para conexión
   ```

2. **Crear migraciones**
   ```bash
   pip install alembic
   alembic init alembic
   ```

3. **Implementar API**
   - Endpoints CRUD
   - Autenticación
   - Lógica de lista de espera

---

**Últimas preguntas:**
- ¿Necesitas backup de BD?
- ¿Quieres seed data adicional?
- ¿Necesitas resetear la BD?

---

**Última actualización:** 13 de mayo de 2026
