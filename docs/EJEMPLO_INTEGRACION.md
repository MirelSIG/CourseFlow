"""
Ejemplo de integración de endpoints con Flask y FastAPI
Elige uno de los dos frameworks
"""

# ==========================================
# OPCIÓN 1: FLASK
# ==========================================

"""
pip install flask flask-sqlalchemy psycopg2-binary

Archivo: app_flask.py
"""

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from db_config import DatabaseConfig
from models_sqlalchemy import Base
from routes import crear_rutas

# Configuración
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = DatabaseConfig.get_connection_string('docker', 'psycopg2')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
db.Model = Base  # Usar el Base de SQLAlchemy

# Registrar rutas
crear_rutas(app, db)

if __name__ == '__main__':
    with app.app_context():
        Base.metadata.create_all(bind=db.engine)
    app.run(debug=True, host='0.0.0.0', port=5000)


# ==========================================
# OPCIÓN 2: FASTAPI (Async)
# ==========================================

"""
pip install fastapi uvicorn sqlalchemy psycopg2-binary

Archivo: app_fastapi.py
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from db_config import DatabaseConfig
from models_sqlalchemy import Base
from routes import router

# Configuración de BD asincrónica
DATABASE_URL = DatabaseConfig.get_connection_string('docker', 'asyncpg')

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    future=True,
    pool_pre_ping=True,
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Crear aplicación
app = FastAPI(
    title="CourseFlow API",
    description="API para gestión de cursos y solicitudes",
    version="1.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registrar rutas
app.include_router(router, prefix="/api")

@app.on_event("startup")
async def startup():
    """Crear tablas al iniciar"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.on_event("shutdown")
async def shutdown():
    """Cerrar conexión"""
    await engine.dispose()

# Dependencia para obtener sesión
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=8000)


# ==========================================
# USO DESDE PYTHON
# ==========================================

"""
Con SQLAlchemy directo (sin framework):

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from db_config import DatabaseConfig
from models_sqlalchemy import Base, Usuario, Curso

# Crear conexión
engine = create_engine(DatabaseConfig.get_connection_string('docker', 'psycopg2'))
Session = sessionmaker(bind=engine)
session = Session()

# Crear tablas
Base.metadata.create_all(engine)

# Consultar
cursos = session.query(Curso).filter_by(estado='activo').all()
for curso in cursos:
    print(f"{curso.nombre} - {curso.categoria.nombre}")

session.close()
"""


# ==========================================
# EJEMPLO DE CLIENTE (requests)
# ==========================================

"""
import requests
import json

BASE_URL = "http://localhost:5000/api"  # Flask
# BASE_URL = "http://localhost:8000/api"  # FastAPI

# 1. Obtener categorías
response = requests.get(f"{BASE_URL}/categorias")
print(response.json())

# 2. Obtener cursos por categoría
response = requests.get(f"{BASE_URL}/cursos?categoria_id=1")
print(response.json())

# 3. Crear solicitud
payload = {"id_curso": 1, "id_usuario": 2}
response = requests.post(
    f"{BASE_URL}/solicitudes",
    json=payload,
    headers={"Content-Type": "application/json"}
)
print(response.json())

# 4. Ver mis solicitudes
response = requests.get(f"{BASE_URL}/mis-solicitudes/2")
print(response.json())

# 5. Admin: actualizar solicitud
payload = {"estado": "aceptado"}
response = requests.put(
    f"{BASE_URL}/solicitudes/1",
    json=payload,
    headers={"Content-Type": "application/json"}
)
print(response.json())

# 6. Admin: ver todas las solicitudes
response = requests.get(f"{BASE_URL}/admin/solicitudes")
print(response.json())

# 7. Admin: ver lista de espera
response = requests.get(f"{BASE_URL}/admin/lista-espera/1")
print(response.json())
"""
