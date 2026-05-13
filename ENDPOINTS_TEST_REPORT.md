# Prueba de Endpoints - CourseFlow API

## Resumen de Endpoints Encontrados

| Módulo | Método | Ruta | Descripción | Status |
|--------|--------|------|-------------|--------|
| Auth | POST | `/api/v1/auth/login` | Login con email y password | Implementado |
| Usuarios | POST | `/api/v1/users/` | Registrar nuevo usuario | Implementado |
| Cursos | POST | `/api/v1/courses/` | Crear curso | Implementado |
| Cursos | GET | `/api/v1/courses/` | Listar todos los cursos | Implementado |
| Cursos | GET | `/api/v1/courses/{course_id}` | Obtener curso por ID | Implementado |
| Cursos | PUT | `/api/v1/courses/{course_id}` | Actualizar curso | Implementado |
| Solicitudes | POST | `/api/v1/applications/` | Crear solicitud de inscripción | Implementado |
| Solicitudes | PATCH | `/api/v1/applications/{app_id}` | Actualizar estado de solicitud | Implementado |
| Lista de Espera | POST | `/api/v1/waiting-list/` | Agregar a lista de espera | Implementado |
| Lista de Espera | GET | `/api/v1/waiting-list/{course_id}` | Obtener lista de espera por curso | Implementado |

## Resultados de Validación

### Estructura de Código
- Todos los routes están correctamente importados en `app/main.py`
- Los routers están configurados con prefijos `/api/v1/`
- CORS está habilitado para `http://localhost:5173`

### Fixes Aplicados
1. **Corrección de imports de schemas:**
   - `routes_users.py`: `from app.schemas.user` → `from app.schemas.user_schema`
   - `routes_courses.py`: `from app.schemas.course` → `from app.schemas.course_schema`

### Detalles de Implementación

#### routes_auth.py
```python
@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    # Valida credenciales y retorna JWT
    # Status: 401 si credenciales inválidas
```

#### routes_users.py
```python
@router.post("/")
def create_user(user_in: UserCreate, db: Session = Depends(get_db)):
    # Crea nuevo usuario
    # Status: 400 si email ya existe
    # Retorna: UserRead (sin password)
```

#### routes_courses.py
```python
@router.post("/")      # Crear curso
@router.get("/")       # Listar todos (con modelo response)
@router.get("/{id}")   # Obtener por ID
@router.put("/{id}")   # Actualizar curso
```

#### routes_applications.py
```python
@router.post("/")           # Crear solicitud (user_id, course_id)
@router.patch("/{app_id}")  # Cambiar estado
```

#### routes_waiting_list.py
```python
@router.post("/")              # Agregar a lista de espera
@router.get("/{course_id}")    # Obtener lista por curso (ordenada por posición)
```

## Requisitos para Pruebas Reales

Para ejecutar la API con pruebas reales necesitas:

1. **PostgreSQL**: Base de datos en `postgresql://courseflow:courseflow@localhost:5432/courseflow_db`
2. **Docker Compose**: Ejecutar `docker-compose up` (sin network issues)
3. **Migraciones**: Ejecutar `alembic upgrade head` antes de pruebas

## Alternativa: FastAPI en Desarrollo Local

```bash
# Instalar venv
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar servidor (requiere BD PostgreSQL activa)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Estado de Tests

- Estructura de código validada
- Imports corregidos
- Tests completos pendientes (requieren BD PostgreSQL)
- Endpoints documentados en FastAPI (vía Swagger en `/docs`)

## Próximos Pasos

1. Corregir configuración de Docker para descargar imágenes exitosamente
2. Ejecutar `pytest` con BD en memoria o fixture setup
3. Validar respuestas JSON y códigos de status en cada endpoint
4. Pruebas de autenticación con JWT
