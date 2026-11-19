import os
import sqlite3
import pytest

# 1. Establecer DATABASE_URL antes de importar main
os.environ["DATABASE_URL"] = "sqlite:///./test_temp.db"

# Soporte para inicialización de Base y engine (SQLAlchemy)
try:
    from sqlalchemy import create_engine
    from sqlalchemy.orm import declarative_base

    engine = create_engine(os.environ["DATABASE_URL"])
    Base = declarative_base()
except ImportError:
    class _DummyMetadata:
        def create_all(self, bind=None):
            pass

    class _DummyBase:
        metadata = _DummyMetadata()

    Base = _DummyBase()
    engine = None

import main
from main import app
from fastapi.testclient import TestClient

DB_FILE = "./test_temp.db"


class SQLiteDictCursor:
    """Cursor que adapta tipos de datos y consultas PostgreSQL a SQLite y devuelve diccionarios."""

    def __init__(self, cursor):
        self._cursor = cursor

    def execute(self, sql, params=None):
        clean_sql = sql.replace("SERIAL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
        clean_sql = clean_sql.replace("%s", "?")
        has_returning = "RETURNING *" in clean_sql.upper()

        try:
            if params:
                self._cursor.execute(clean_sql, params)
            else:
                self._cursor.execute(clean_sql)
        except sqlite3.OperationalError:
            if has_returning:
                clean_sql_no_ret = clean_sql.replace("RETURNING *", "").replace("returning *", "").strip()
                if clean_sql_no_ret.endswith(";"):
                    clean_sql_no_ret = clean_sql_no_ret[:-1]
                if params:
                    self._cursor.execute(clean_sql_no_ret, params)
                else:
                    self._cursor.execute(clean_sql_no_ret)
                last_id = self._cursor.lastrowid
                self._cursor.execute("SELECT * FROM notas WHERE id = ?", (last_id,))
            else:
                raise

    def fetchone(self):
        row = self._cursor.fetchone()
        return dict(row) if row else None

    def fetchall(self):
        return [dict(row) for row in self._cursor.fetchall()]

    def close(self):
        self._cursor.close()


class SQLiteConnectionWrapper:
    """Wrapper de conexión SQLite compatible con la interfaz esperada por la API."""

    def __init__(self, conn):
        self._conn = conn

    def cursor(self):
        return SQLiteDictCursor(self._conn.cursor())

    def commit(self):
        self._conn.commit()

    def close(self):
        self._conn.close()


@pytest.fixture(scope="session", autouse=True)
def setup_database():
    """Fixture que crea las tablas y limpia la base de datos de prueba al finalizar."""
    if os.path.exists(DB_FILE):
        try:
            os.remove(DB_FILE)
        except OSError:
            pass

    # 2. Crear las tablas mediante Base.metadata.create_all
    Base.metadata.create_all(bind=engine)

    # Configurar el conector de base de datos para SQLite local en pruebas
    def get_test_db():
        conn = sqlite3.connect(DB_FILE, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return SQLiteConnectionWrapper(conn)

    main.get_db_connection = get_test_db
    main.startup()

    yield

    # Eliminar el archivo ./test_temp.db al finalizar
    if os.path.exists(DB_FILE):
        try:
            os.remove(DB_FILE)
        except OSError:
            pass


client = TestClient(app)


def test_health_check():
    """Verifica que GET /health devuelva status 200 y status 'healthy'."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data.get("status") == "healthy"


def test_crear_nota():
    """Hace POST /api/notas y verifica creación exitosa."""
    payload = {"titulo": "Test CI"}
    response = client.post("/api/notas", json=payload)
    assert response.status_code in [200, 201]
    data = response.json()
    assert data.get("titulo") == "Test CI"
    assert "id" in data


def test_listar_notas():
    """Hace GET /api/notas y comprueba que la nota creada esté en la lista."""
    response = client.get("/api/notas")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert any(n.get("titulo") == "Test CI" for n in data)
