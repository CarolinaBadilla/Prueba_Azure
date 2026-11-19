import os

import psycopg2
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from psycopg2.extras import RealDictCursor
from pydantic import BaseModel

app = FastAPI(title="Cloud Portfolio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DATABASE_URL = os.getenv("DATABASE_URL")

def get_db_connection():
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)

@app.on_event("startup")
def startup():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS notas (
            id SERIAL PRIMARY KEY,
            titulo TEXT NOT NULL
        );
    """)
    conn.commit()
    cur.close()
    conn.close()

class NotaIn(BaseModel):
    titulo: str

@app.get("/health")
def health_check():
    return {"status": "healthy", "environment": os.getenv("ENVIRONMENT", "local")}

@app.get("/api/notas")
def listar_notas():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM notas ORDER BY id DESC;")
    notas = cur.fetchall()
    cur.close()
    conn.close()
    return notas

@app.post("/api/notas")
def crear_nota(nota: NotaIn):
    if not nota.titulo.strip():
        raise HTTPException(status_code=400, detail="El título no puede estar vacío")
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO notas (titulo) VALUES (%s) RETURNING *;", (nota.titulo,))
    nueva = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return nueva