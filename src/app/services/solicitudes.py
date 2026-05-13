from __future__ import annotations

from datetime import datetime

from sqlalchemy import func
from sqlalchemy.orm import Session

from src.app.models import EstadoListaEsperaEnum, EstadoSolicitudEnum, ListaEspera, Solicitud


class ServicioSolicitudes:
    @staticmethod
    def aceptar_solicitud(db_session: Session, solicitud: Solicitud) -> tuple[bool, ListaEspera | None]:
        solicitud.estado = EstadoSolicitudEnum.ACEPTADO.value
        solicitud.fecha_respuesta = datetime.utcnow()

        aceptados = (
            db_session.query(Solicitud)
            .filter(
                Solicitud.id_curso == solicitud.id_curso,
                Solicitud.estado == EstadoSolicitudEnum.ACEPTADO.value,
            )
            .count()
        )
        if aceptados >= solicitud.curso.capacidad:
            max_posicion = (
                db_session.query(func.max(ListaEspera.posicion))
                .filter(ListaEspera.id_curso == solicitud.id_curso)
                .scalar()
                or 0
            )
            entrada = ListaEspera(
                id_usuario=solicitud.id_usuario,
                id_curso=solicitud.id_curso,
                id_solicitud=solicitud.id_solicitud,
                posicion=max_posicion + 1,
                estado=EstadoListaEsperaEnum.EN_ESPERA.value,
            )
            db_session.add(entrada)
            return True, entrada

        return True, None

    @staticmethod
    def rechazar_solicitud(solicitud: Solicitud) -> None:
        solicitud.estado = EstadoSolicitudEnum.RECHAZADO.value
        solicitud.fecha_respuesta = datetime.utcnow()

    @staticmethod
    def cancelar_solicitud(db_session: Session, solicitud: Solicitud) -> None:
        solicitud.estado = EstadoSolicitudEnum.CANCELADO.value

        siguiente = (
            db_session.query(ListaEspera)
            .filter(
                ListaEspera.id_curso == solicitud.id_curso,
                ListaEspera.estado == EstadoListaEsperaEnum.EN_ESPERA.value,
            )
            .order_by(ListaEspera.posicion)
            .first()
        )

        if not siguiente:
            return

        siguiente.estado = EstadoListaEsperaEnum.PROMOVIDO.value
        siguiente.fecha_promocion = datetime.utcnow()
        siguiente.solicitud.estado = EstadoSolicitudEnum.ACEPTADO.value
        siguiente.solicitud.fecha_respuesta = datetime.utcnow()

        resto = (
            db_session.query(ListaEspera)
            .filter(
                ListaEspera.id_curso == solicitud.id_curso,
                ListaEspera.estado == EstadoListaEsperaEnum.EN_ESPERA.value,
            )
            .order_by(ListaEspera.posicion)
            .all()
        )
        for i, entrada in enumerate(resto, 1):
            entrada.posicion = i
