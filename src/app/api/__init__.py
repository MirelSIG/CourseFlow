def register_flask_routes(app, db):
	from src.app.api.flask_routes import register_flask_routes as _register_flask_routes

	return _register_flask_routes(app, db)


try:
	from src.app.api.fastapi_routes import router
except ModuleNotFoundError:
	router = None


__all__ = ["router", "register_flask_routes"]
