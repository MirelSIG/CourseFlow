from __future__ import annotations

from flask import jsonify, request

from src.app.models import Categoria, Curso, ListaEspera, Solicitud
from src.app.services import ServicioSolicitudes


def register_flask_routes(app, db):
    @app.route('/api/categorias', methods=['GET'])
    def get_categorias():
        categorias = db.session.query(Categoria).filter_by(activo=True).all()
        return {
            'success': True,
            'data': [
                {
                    'id_categoria': c.id_categoria,
                    'nombre': c.nombre,
                    'descripcion': c.descripcion,
                }
                for c in categorias
            ],
        }

    @app.route('/api/cursos', methods=['GET'])
    def get_cursos():
        categoria_id = request.args.get('categoria_id', type=int)
        query = db.session.query(Curso).filter_by(estado='activo', visibilidad='publica')

        if categoria_id:
            query = query.filter_by(id_categoria=categoria_id)

        cursos = query.all()
        return {
            'success': True,
            'data': [
                {
                    'id_curso': c.id_curso,
                    'nombre': c.nombre,
                    'descripcion': c.descripcion,
                    'categoria': c.categoria.nombre,
                    'capacidad': c.capacidad,
                    'plazas_disponibles': c.capacidad - len([s for s in c.solicitudes if s.estado == 'aceptado']),
                    'fecha_inicio': c.fecha_inicio.isoformat(),
                    'fecha_fin': c.fecha_fin.isoformat(),
                    'estado': c.estado,
                }
                for c in cursos
            ],
        }

    @app.route('/api/solicitudes', methods=['POST'])
    def crear_solicitud():
        data = request.get_json() or {}
        id_usuario = data.get('id_usuario')
        id_curso = data.get('id_curso')

        if not id_usuario or not id_curso:
            return jsonify({'success': False, 'error': 'Faltan campos requeridos'}), 400

        existente = db.session.query(Solicitud).filter_by(id_usuario=id_usuario, id_curso=id_curso).first()
        if existente:
            return jsonify({'success': False, 'error': 'Ya existe solicitud para este curso'}), 409

        solicitud = Solicitud(id_usuario=id_usuario, id_curso=id_curso)
        db.session.add(solicitud)
        db.session.commit()

        return jsonify({'success': True, 'data': {'id_solicitud': solicitud.id_solicitud, 'estado': solicitud.estado}}), 201

    @app.route('/api/mis-solicitudes/<int:id_usuario>', methods=['GET'])
    def get_mis_solicitudes(id_usuario: int):
        solicitudes = db.session.query(Solicitud).filter_by(id_usuario=id_usuario).all()
        return {
            'success': True,
            'data': [
                {
                    'id_solicitud': s.id_solicitud,
                    'curso': s.curso.nombre,
                    'estado': s.estado,
                    'fecha_solicitud': s.fecha_solicitud.isoformat(),
                    'posicion_espera': s.lista_espera[0].posicion if s.lista_espera else None,
                }
                for s in solicitudes
            ],
        }

    @app.route('/api/solicitudes/<int:id_solicitud>', methods=['PUT'])
    def actualizar_solicitud(id_solicitud: int):
        data = request.get_json() or {}
        nuevo_estado = data.get('estado')

        solicitud = db.session.query(Solicitud).filter_by(id_solicitud=id_solicitud).first()
        if not solicitud:
            return jsonify({'success': False, 'error': 'Solicitud no encontrada'}), 404

        if nuevo_estado == 'aceptado':
            ServicioSolicitudes.aceptar_solicitud(db.session, solicitud)
        elif nuevo_estado == 'rechazado':
            ServicioSolicitudes.rechazar_solicitud(solicitud)
        elif nuevo_estado == 'cancelado':
            ServicioSolicitudes.cancelar_solicitud(db.session, solicitud)

        db.session.commit()
        return jsonify({'success': True, 'data': {'estado': solicitud.estado}})

    @app.route('/api/admin/solicitudes', methods=['GET'])
    def get_solicitudes_admin():
        solicitudes = db.session.query(Solicitud).all()
        return {
            'success': True,
            'data': [
                {
                    'id_solicitud': s.id_solicitud,
                    'usuario': s.usuario.nombre,
                    'curso': s.curso.nombre,
                    'estado': s.estado,
                    'fecha_solicitud': s.fecha_solicitud.isoformat(),
                }
                for s in solicitudes
            ],
        }

    @app.route('/api/admin/lista-espera/<int:id_curso>', methods=['GET'])
    def get_lista_espera_admin(id_curso: int):
        lista = (
            db.session.query(ListaEspera)
            .filter_by(id_curso=id_curso, estado='en_espera')
            .order_by(ListaEspera.posicion)
            .all()
        )
        return {
            'success': True,
            'data': [
                {
                    'id_espera': le.id_espera,
                    'usuario': le.usuario.nombre,
                    'posicion': le.posicion,
                    'fecha': le.fecha_inscripcion.isoformat(),
                }
                for le in lista
            ],
        }
