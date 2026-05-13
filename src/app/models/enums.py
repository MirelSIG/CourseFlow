from enum import Enum


class RolEnum(str, Enum):
    USUARIO = "usuario"
    ADMINISTRADOR = "administrador"


class EstadoUsuarioEnum(str, Enum):
    ACTIVO = "activo"
    INACTIVO = "inactivo"


class EstadoCursoEnum(str, Enum):
    ACTIVO = "activo"
    INACTIVO = "inactivo"
    EN_CURSO = "en_curso"
    FINALIZADO = "finalizado"


class VisibilidadCursoEnum(str, Enum):
    PUBLICA = "publica"
    PRIVADA = "privada"


class EstadoSolicitudEnum(str, Enum):
    PENDIENTE = "pendiente"
    ACEPTADO = "aceptado"
    RECHAZADO = "rechazado"
    CANCELADO = "cancelado"
    NO_PRESENTADO = "no_presentado"


class EstadoListaEsperaEnum(str, Enum):
    EN_ESPERA = "en_espera"
    PROMOVIDO = "promovido"
    RECHAZADO = "rechazado"
