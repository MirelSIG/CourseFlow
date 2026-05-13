from __future__ import annotations

from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

from src.db_config import FLASK_SQLALCHEMY_CONFIG
from src.models_sqlalchemy import Base
from src.routes import crear_rutas


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.update(FLASK_SQLALCHEMY_CONFIG)

    CORS(app, resources={r"/api/*": {"origins": "*"}})

    db = SQLAlchemy(app)
    crear_rutas(app, db)

    with app.app_context():
        Base.metadata.create_all(bind=db.engine)

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)