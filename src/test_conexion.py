#!/usr/bin/env python3
"""
Script de prueba: Conexión a PostgreSQL con CourseFlow
Verifica que db_config.py funciona correctamente
"""

import os
import sys
sys.path.insert(0, os.path.dirname(__file__))

from db_config import DatabaseConfig
from sqlalchemy import create_engine, text

def test_connection(environment='docker'):
    """Prueba conexión a la base de datos"""
    print(f"\n{'='*60}")
    print(f"Probando conexión: {environment.upper()}")
    print(f"{'='*60}")
    
    # Obtener configuración
    config = DatabaseConfig.get_config(environment)
    print(f"\n📋 Configuración:")
    print(f"   Host: {config['host']}")
    print(f"   Puerto: {config['port']}")
    print(f"   Usuario: {config['user']}")
    print(f"   Base de datos: {config['database']}")
    
    # Obtener string de conexión
    conn_string = DatabaseConfig.get_connection_string(environment, 'psycopg2')
    print(f"\n🔗 String de conexión:")
    print(f"   {conn_string.replace(config['password'], '***')}")
    
    try:
        # Crear engine
        engine = create_engine(conn_string, echo=False)
        
        # Probar conexión
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version();"))
            version = result.scalar()
            print(f"\n✅ Conexión EXITOSA")
            print(f"   {version}")
        
        # Verificar tablas
        with engine.connect() as conn:
            result = conn.execute(
                text("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';")
            )
            num_tables = result.scalar()
            print(f"\n📊 Tablas en BD: {num_tables}")
            
            # Listar tablas
            result = conn.execute(
                text("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;")
            )
            for row in result:
                print(f"   - {row[0]}")
        
        # Verificar datos
        with engine.connect() as conn:
            categorias = conn.execute(text("SELECT COUNT(*) FROM categorias;")).scalar()
            cursos = conn.execute(text("SELECT COUNT(*) FROM cursos;")).scalar()
            usuarios = conn.execute(text("SELECT COUNT(*) FROM usuarios;")).scalar()
            solicitudes = conn.execute(text("SELECT COUNT(*) FROM solicitudes;")).scalar()
            
            print(f"\n📈 Datos cargados:")
            print(f"   Categorías: {categorias}")
            print(f"   Cursos: {cursos}")
            print(f"   Usuarios: {usuarios}")
            print(f"   Solicitudes: {solicitudes}")
        
        engine.dispose()
        return True
        
    except Exception as e:
        print(f"\n❌ Error de conexión:")
        print(f"   {str(e)}")
        return False


def test_orm():
    """Prueba ORM con SQLAlchemy"""
    print(f"\n{'='*60}")
    print(f"Probando ORM SQLAlchemy")
    print(f"{'='*60}")
    
    try:
        from sqlalchemy import create_engine
        from sqlalchemy.orm import sessionmaker
        from models_sqlalchemy import Base, Curso, Categoria, Usuario
        
        conn_string = DatabaseConfig.get_connection_string('local', 'psycopg2')
        engine = create_engine(conn_string, echo=False)
        Session = sessionmaker(bind=engine)
        session = Session()
        
        # Consultar cursos
        cursos = session.query(Curso).limit(3).all()
        print(f"\n✅ ORM funciona correctamente")
        print(f"\n📚 Primeros 3 cursos:")
        
        for curso in cursos:
            print(f"\n   Curso: {curso.nombre}")
            print(f"   Categoría: {curso.categoria.nombre}")
            print(f"   Plazas disponibles: {curso.plazas_disponibles()}/{curso.capacidad}")
            print(f"   Estado: {curso.estado}")
        
        session.close()
        return True
        
    except ImportError as e:
        print(f"\n⚠️  Modelos no disponibles: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Error en ORM:")
        print(f"   {str(e)}")
        return False


if __name__ == '__main__':
    print("\n" + "="*60)
    print("PRUEBA DE CONEXIÓN - CourseFlow PostgreSQL")
    print("="*60)
    
    # Probar conexión local (desde host a Docker)
    test_connection('local')
    
    # Probar ORM
    test_orm()
    
    print("\n" + "="*60)
    print("✅ Todas las pruebas completadas")
    print("="*60 + "\n")
