from __future__ import annotations

from datetime import datetime
from typing import List

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, relationship
from sqlalchemy.sql import func

from src.app.db.base import Base
from src.app.models.enums import (
    EstadoCursoEnum,
    EstadoListaEsperaEnum,
    EstadoSolicitudEnum,
    EstadoUsuarioEnum,
    RolEnum,
    VisibilidadCursoEnum,
)


class Categoria(Base):
    __tablename__ = "categorias"
    __table_args__ = (Index("idx_activo_categoria", "activo"),)

    id_categoria = Column(Integer, primary_key=True, autoincrement=True)
    nombre = Column(String(100), nullable=False, unique=True)
    descripcion = Column(Text)
    activo = Column(Boolean, nullable=False, default=True)
    fecha_creacion = Column(DateTime, nullable=False, default=func.now())

    cursos: Mapped[List["Curso"]] = relationship("Curso", back_populates="categoria")


class Usuario(Base):
    __tablename__ = "usuarios"
    __table_args__ = (
        Index("idx_email", "email"),
        Index("idx_rol", "rol"),
    )

    id_usuario = Column(Integer, primary_key=True, autoincrement=True)
    nombre = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False, unique=True)
    contraseña = Column(String(255), nullable=False)
    rol = Column(String(50), nullable=False, default=RolEnum.USUARIO.value)
    estado = Column(String(50), nullable=False, default=EstadoUsuarioEnum.ACTIVO.value)
    fecha_creacion = Column(DateTime, nullable=False, default=func.now())

    solicitudes: Mapped[List["Solicitud"]] = relationship(
        "Solicitud", back_populates="usuario", cascade="all, delete-orphan"
    )
    lista_espera: Mapped[List["ListaEspera"]] = relationship(
        "ListaEspera", back_populates="usuario", cascade="all, delete-orphan"
    )


class Curso(Base):
    __tablename__ = "cursos"
    __table_args__ = (
        Index("idx_categoria", "id_categoria"),
        Index("idx_estado", "estado"),
        Index("idx_visibilidad", "visibilidad"),
        Index("idx_fecha_inicio", "fecha_inicio"),
    )

    id_curso = Column(Integer, primary_key=True, autoincrement=True)
    id_categoria = Column(
        Integer, ForeignKey("categorias.id_categoria", ondelete="RESTRICT"), nullable=False
    )
    nombre = Column(String(255), nullable=False)
    descripcion = Column(Text)
    fecha_inicio = Column(Date, nullable=False)
    fecha_fin = Column(Date, nullable=False)
    capacidad = Column(Integer, nullable=False)
    capacidad_adicional = Column(Integer, nullable=False, default=0)
    estado = Column(String(50), nullable=False, default=EstadoCursoEnum.ACTIVO.value)
    visibilidad = Column(String(50), nullable=False, default=VisibilidadCursoEnum.PUBLICA.value)
    fecha_creacion = Column(DateTime, nullable=False, default=func.now())

    categoria: Mapped["Categoria"] = relationship("Categoria", back_populates="cursos")
    solicitudes: Mapped[List["Solicitud"]] = relationship(
        "Solicitud", back_populates="curso", cascade="all, delete-orphan"
    )
    lista_espera: Mapped[List["ListaEspera"]] = relationship(
        "ListaEspera", back_populates="curso", cascade="all, delete-orphan"
    )

    def plazas_disponibles(self) -> int:
        aceptados = len([s for s in self.solicitudes if s.estado == EstadoSolicitudEnum.ACEPTADO.value])
        return self.capacidad - aceptados

    def esta_lleno(self) -> bool:
        return self.plazas_disponibles() <= 0


class Solicitud(Base):
    __tablename__ = "solicitudes"
    __table_args__ = (
        Index("idx_estado_solicitud", "estado"),
        Index("idx_usuario_solicitud", "id_usuario"),
        Index("idx_curso_solicitud", "id_curso"),
        UniqueConstraint("id_usuario", "id_curso", name="idx_usuario_curso_unique"),
    )

    id_solicitud = Column(Integer, primary_key=True, autoincrement=True)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    id_curso = Column(Integer, ForeignKey("cursos.id_curso", ondelete="CASCADE"), nullable=False)
    estado = Column(String(50), nullable=False, default=EstadoSolicitudEnum.PENDIENTE.value)
    fecha_solicitud = Column(DateTime, nullable=False, default=func.now())
    fecha_respuesta = Column(DateTime)
    comentarios = Column(Text)

    usuario: Mapped["Usuario"] = relationship("Usuario", back_populates="solicitudes")
    curso: Mapped["Curso"] = relationship("Curso", back_populates="solicitudes")
    lista_espera: Mapped[List["ListaEspera"]] = relationship(
        "ListaEspera", back_populates="solicitud", cascade="all, delete-orphan"
    )

    def en_lista_espera(self) -> bool:
        return any(le.estado == EstadoListaEsperaEnum.EN_ESPERA.value for le in self.lista_espera)


class ListaEspera(Base):
    __tablename__ = "lista_espera"
    __table_args__ = (
        Index("idx_posicion", "posicion"),
        Index("idx_estado_espera", "estado"),
        Index("idx_usuario_espera", "id_usuario"),
        Index("idx_curso_espera", "id_curso"),
        UniqueConstraint("id_usuario", "id_curso", name="idx_usuario_curso_espera_unique"),
    )

    id_espera = Column(Integer, primary_key=True, autoincrement=True)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    id_curso = Column(Integer, ForeignKey("cursos.id_curso", ondelete="CASCADE"), nullable=False)
    id_solicitud = Column(Integer, ForeignKey("solicitudes.id_solicitud", ondelete="CASCADE"), nullable=False)
    posicion = Column(Integer, nullable=False)
    fecha_inscripcion = Column(DateTime, nullable=False, default=func.now())
    estado = Column(String(50), nullable=False, default=EstadoListaEsperaEnum.EN_ESPERA.value)
    fecha_promocion = Column(DateTime)

    usuario: Mapped["Usuario"] = relationship("Usuario", back_populates="lista_espera")
    curso: Mapped["Curso"] = relationship("Curso", back_populates="lista_espera")
    solicitud: Mapped["Solicitud"] = relationship("Solicitud", back_populates="lista_espera")
