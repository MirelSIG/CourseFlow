## Guía Rápida: Modelos y Endpoints

### Archivos Creados

1. **src/models_sqlalchemy.py** - Modelos ORM para PostgreSQL
   - Clases: `Usuario`, `Categoria`, `Curso`, `Solicitud`, `ListaEspera`
   - Enums: Rol, Estado, Visibilidad
   - Servicios: `ServicioSolicitudes` (lógica de aceptación/rechazo)

2. **src/routes.py** - Endpoints para Flask y FastAPI
   - 8 endpoints implementados (GET/POST/PUT)
   - Soporte para filtrado por categoría

3. **src/app/main_flask.py** y **src/app/main_fastapi.py** - Entrypoints de API
   - CORS activo en Flask (`Flask-CORS`)
   - CORS activo en FastAPI (`CORSMiddleware`)

### Endpoints Disponibles

#### Público (Todos)
```
GET  /api/categorias              → Listar categorías activas
GET  /api/cursos?categoria_id=1   → Listar cursos (filtro opcional)
POST /api/solicitudes             → Crear solicitud (body: id_curso, id_usuario)
GET  /api/mis-solicitudes/{id}    → Ver mis solicitudes
```

#### Admin
```
PUT  /api/solicitudes/{id}        → Cambiar estado (aceptado/rechazado/cancelado)
GET  /api/admin/solicitudes       → Ver todas las solicitudes
GET  /api/admin/lista-espera/{id} → Ver lista de espera por curso
```

### Instalación Rápida

**Opción 1: Flask**
```bash
pip install flask flask-sqlalchemy psycopg2-binary
python -m src.app.main_flask
# API en http://localhost:5000
```

**Opción 2: FastAPI (Async)**
```bash
pip install fastapi uvicorn sqlalchemy asyncpg
python -m uvicorn src.app.main_fastapi:app --reload
# API en http://localhost:8000
```

### Ejemplo de Uso

```python
# SQLAlchemy directo
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from src.models_sqlalchemy import Base, Curso
from src.db_config import DatabaseConfig

engine = create_engine(DatabaseConfig.get_connection_string('docker', 'psycopg2'))
Session = sessionmaker(bind=engine)
session = Session()

# Consultar cursos activos
cursos = session.query(Curso).filter_by(estado='activo').all()
for curso in cursos:
    print(f"{curso.nombre} ({curso.categoria.nombre})")
    print(f"  Plazas: {curso.plazas_disponibles()}")
```

### Lógica de Lista de Espera

1. **Solicitud creada** → Estado: `pendiente`
2. **Admin acepta** → Si hay plaza: `aceptado` | Si lleno: `aceptado` + entrada en `lista_espera`
3. **Alguien cancela** → Primer candidato en lista → promovido a `aceptado`

### Notas

- Base de datos: PostgreSQL en Docker (5433)
- Arquitectura: todo el código Python está bajo `src/`
- CORS: habilitado para rutas `/api/*` en Flask y para toda la API en FastAPI
- Autenticación: Implementar JWT en middleware (no incluida)
- Validación de rol: Decoradores Flask/FastAPI (no incluida)
- Vista SQL: `vista_catalogo_cursos` ya existe en BD para filtrado eficiente
