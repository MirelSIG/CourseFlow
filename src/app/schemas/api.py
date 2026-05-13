from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel


class CategoriaOut(BaseModel):
    id_categoria: int
    nombre: str
    descripcion: Optional[str] = None


class CursoOut(BaseModel):
    id_curso: int
    nombre: str
    descripcion: Optional[str] = None
    categoria: str
    capacidad: int
    plazas_disponibles: int
    fecha_inicio: date
    fecha_fin: date
    estado: str


class SolicitudCreateIn(BaseModel):
    id_usuario: int
    id_curso: int


class SolicitudEstadoIn(BaseModel):
    estado: str


class SolicitudOut(BaseModel):
    id_solicitud: int
    curso: str
    estado: str
    fecha_solicitud: datetime
    posicion_espera: Optional[int] = None


class SolicitudAdminOut(BaseModel):
    id_solicitud: int
    usuario: str
    curso: str
    estado: str
    fecha_solicitud: datetime
