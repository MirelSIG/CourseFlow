from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "CourseFlow API")
    app_env: str = os.getenv("APP_ENV", "development")
    app_host: str = os.getenv("APP_HOST", "0.0.0.0")
    app_port_flask: int = int(os.getenv("APP_PORT_FLASK", 5000))
    app_port_fastapi: int = int(os.getenv("APP_PORT_FASTAPI", 8000))

    db_host: str = os.getenv("DB_HOST", "localhost")
    db_port: int = int(os.getenv("DB_PORT", 5433))
    db_user: str = os.getenv("DB_USER", "courseflow_user")
    db_password: str = os.getenv("DB_PASSWORD", "courseflow_pass")
    db_name: str = os.getenv("DB_NAME", "courseflow")

    @property
    def sync_database_url(self) -> str:
        return (
            f"postgresql+psycopg2://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def async_database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )


settings = Settings()
