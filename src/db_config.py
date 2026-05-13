import os


class DatabaseConfig:
    DOCKER_CONFIG = {
        'driver': 'postgresql',
        'host': 'postgres',
        'port': 5432,
        'user': 'courseflow_user',
        'password': 'courseflow_pass',
        'database': 'courseflow',
    }

    LOCAL_CONFIG = {
        'driver': 'postgresql',
        'host': 'localhost',
        'port': 5433,
        'user': 'courseflow_user',
        'password': 'courseflow_pass',
        'database': 'courseflow',
    }

    PRODUCTION_CONFIG = {
        'driver': 'postgresql',
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': int(os.getenv('DB_PORT', 5433)),
        'user': os.getenv('DB_USER', 'courseflow_user'),
        'password': os.getenv('DB_PASSWORD', 'courseflow_pass'),
        'database': os.getenv('DB_NAME', 'courseflow'),
    }

    @staticmethod
    def get_config(environment: str = 'local') -> dict:
        if environment == 'docker':
            return DatabaseConfig.DOCKER_CONFIG
        if environment == 'production':
            return DatabaseConfig.PRODUCTION_CONFIG
        return DatabaseConfig.LOCAL_CONFIG

    @staticmethod
    def get_connection_string(environment: str = 'local', driver: str = 'psycopg2') -> str:
        config = DatabaseConfig.get_config(environment)
        return (
            f"{config['driver']}+{driver}://{config['user']}:{config['password']}"
            f"@{config['host']}:{config['port']}/{config['database']}"
        )

    @staticmethod
    def get_psycopg2_dsn(environment: str = 'local') -> str:
        config = DatabaseConfig.get_config(environment)
        return (
            f"host={config['host']} user={config['user']} password={config['password']} "
            f"dbname={config['database']} port={config['port']}"
        )


FLASK_SQLALCHEMY_CONFIG = {
    'SQLALCHEMY_DATABASE_URI': DatabaseConfig.get_connection_string(environment='local', driver='psycopg2'),
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
}

FASTAPI_DATABASE_URL = DatabaseConfig.get_connection_string(environment='local', driver='asyncpg')
