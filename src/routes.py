from src.app.api import register_flask_routes, router


def crear_rutas(app, db):
    return register_flask_routes(app, db)


__all__ = ["crear_rutas", "router"]
