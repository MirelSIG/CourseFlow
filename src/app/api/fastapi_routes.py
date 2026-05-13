from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.app.db.session import get_async_session
from src.app.models import Categoria, Curso, ListaEspera, Solicitud

router = APIRouter()


@router.get('/categorias')
async def get_categorias_fastapi(db: AsyncSession = Depends(get_async_session)):
    result = await db.execute(select(Categoria).filter_by(activo=True))
    categorias = result.scalars().all()
    return [
        {
            'id_categoria': c.id_categoria,
            'nombre': c.nombre,
            'descripcion': c.descripcion,
            'activo': c.activo,
        }
        for c in categorias
    ]


@router.get('/cursos')
async def get_cursos_fastapi(
    categoria_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_async_session),
):
    query = select(Curso).filter_by(estado='activo', visibilidad='publica')
    if categoria_id:
        query = query.where(Curso.id_categoria == categoria_id)

    result = await db.execute(query)
    cursos = result.scalars().all()
    return [
        {
            'id_curso': c.id_curso,
            'nombre': c.nombre,
            'descripcion': c.descripcion,
            'categoria': c.categoria.nombre if c.categoria else None,
            'capacidad': c.capacidad,
            'fecha_inicio': c.fecha_inicio.isoformat(),
            'fecha_fin': c.fecha_fin.isoformat(),
            'estado': c.estado,
        }
        for c in cursos
    ]


@router.post('/solicitudes', status_code=201)
async def crear_solicitud_fastapi(payload: dict, db: AsyncSession = Depends(get_async_session)):
    id_usuario = payload.get('id_usuario')
    id_curso = payload.get('id_curso')

    if not id_usuario or not id_curso:
        raise HTTPException(status_code=400, detail='Faltan campos requeridos')

    existente = await db.execute(
        select(Solicitud).where(Solicitud.id_usuario == id_usuario, Solicitud.id_curso == id_curso)
    )
    if existente.scalars().first():
        raise HTTPException(status_code=409, detail='Ya existe solicitud para este curso')

    solicitud = Solicitud(id_usuario=id_usuario, id_curso=id_curso)
    db.add(solicitud)
    await db.commit()
    await db.refresh(solicitud)
    return {'id_solicitud': solicitud.id_solicitud, 'estado': solicitud.estado}


@router.get('/mis-solicitudes/{id_usuario}')
async def get_mis_solicitudes_fastapi(id_usuario: int, db: AsyncSession = Depends(get_async_session)):
    result = await db.execute(select(Solicitud).where(Solicitud.id_usuario == id_usuario))
    solicitudes = result.scalars().all()
    return [
        {
            'id_solicitud': s.id_solicitud,
            'curso': s.curso.nombre,
            'estado': s.estado,
            'fecha_solicitud': s.fecha_solicitud.isoformat(),
            'posicion_espera': s.lista_espera[0].posicion if s.lista_espera else None,
        }
        for s in solicitudes
    ]


@router.put('/solicitudes/{id_solicitud}')
async def actualizar_solicitud_fastapi(id_solicitud: int, payload: dict, db: AsyncSession = Depends(get_async_session)):
    result = await db.execute(select(Solicitud).where(Solicitud.id_solicitud == id_solicitud))
    solicitud = result.scalars().first()

    if not solicitud:
        raise HTTPException(status_code=404, detail='Solicitud no encontrada')

    nuevo_estado = payload.get('estado')
    if nuevo_estado not in {'aceptado', 'rechazado', 'cancelado'}:
        raise HTTPException(status_code=400, detail='Estado inválido')

    solicitud.estado = nuevo_estado
    await db.commit()
    await db.refresh(solicitud)
    return {'id_solicitud': solicitud.id_solicitud, 'estado': solicitud.estado}


@router.get('/admin/solicitudes')
async def get_solicitudes_admin_fastapi(db: AsyncSession = Depends(get_async_session)):
    result = await db.execute(select(Solicitud))
    solicitudes = result.scalars().all()
    return [
        {
            'id_solicitud': s.id_solicitud,
            'usuario': s.usuario.nombre,
            'curso': s.curso.nombre,
            'estado': s.estado,
            'fecha_solicitud': s.fecha_solicitud.isoformat(),
        }
        for s in solicitudes
    ]


@router.get('/admin/lista-espera/{id_curso}')
async def get_lista_espera_admin_fastapi(id_curso: int, db: AsyncSession = Depends(get_async_session)):
    result = await db.execute(
        select(ListaEspera)
        .where(ListaEspera.id_curso == id_curso, ListaEspera.estado == 'en_espera')
        .order_by(ListaEspera.posicion)
    )
    lista = result.scalars().all()
    return [
        {
            'id_espera': le.id_espera,
            'usuario': le.usuario.nombre,
            'posicion': le.posicion,
            'fecha': le.fecha_inscripcion.isoformat(),
        }
        for le in lista
    ]
