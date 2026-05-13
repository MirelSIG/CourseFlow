# Este contenido sustituira al archivo generado automaticamente por por el comando 
# "alembic init" en la carpeta "alembic" (env.py) y posteriormente sera eliminado. 
# Este archivo es el encargado de configurar las migraciones de la base de datos utilizando Alembic. 
# Se establece la conexión a la base de datos utilizando la URL proporcionada en la configuración, 
# y se define el metadata objetivo para las migraciones. 
# El código también incluye funciones para ejecutar las migraciones tanto en modo offline como online, 
# dependiendo del contexto en el que se ejecute el script.
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.db.base import Base
from app.core.config import settings

config = context.config
config.set_main_option("sqlalchemy.url", settings.SQLALCHEMY_DATABASE_URI)

if config.config_file_name:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline():
    context.configure(
        url=settings.SQLALCHEMY_DATABASE_URI,
        target_metadata=target_metadata,
        literal_binds=True,
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
