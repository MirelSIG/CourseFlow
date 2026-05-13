-- ==========================================
-- INICIALIZACIÓN DE BASE DE DATOS COURSEFLOW
-- PostgreSQL 16
-- ==========================================

-- ==========================================
-- TABLA: USUARIOS
-- ==========================================
CREATE TABLE usuarios (
  id_usuario SERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  contraseña VARCHAR(255) NOT NULL,
  rol VARCHAR(50) NOT NULL CHECK (rol IN ('usuario','administrador')) DEFAULT 'usuario',
  estado VARCHAR(50) NOT NULL CHECK (estado IN ('activo','inactivo')) DEFAULT 'activo',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_email ON usuarios(email);
CREATE INDEX idx_rol ON usuarios(rol);

-- ==========================================
-- TABLA: CATEGORIAS
-- ==========================================
CREATE TABLE categorias (
  id_categoria SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activo_categoria ON categorias(activo);

-- ==========================================
-- TABLA: CURSOS
-- ==========================================
CREATE TABLE cursos (
  id_curso SERIAL PRIMARY KEY,
  id_categoria INTEGER NOT NULL REFERENCES categorias(id_categoria) ON DELETE RESTRICT,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  capacidad INTEGER NOT NULL,
  capacidad_adicional INTEGER DEFAULT 0,
  estado VARCHAR(50) NOT NULL CHECK (estado IN ('activo','inactivo','en_curso','finalizado')) DEFAULT 'activo',
  visibilidad VARCHAR(50) NOT NULL CHECK (visibilidad IN ('publica','privada')) DEFAULT 'publica',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categoria ON cursos(id_categoria);
CREATE INDEX idx_estado ON cursos(estado);
CREATE INDEX idx_visibilidad ON cursos(visibilidad);
CREATE INDEX idx_fecha_inicio ON cursos(fecha_inicio);

-- ==========================================
-- TABLA: SOLICITUDES
-- ==========================================
CREATE TABLE solicitudes (
  id_solicitud SERIAL PRIMARY KEY,
  id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_curso INTEGER NOT NULL REFERENCES cursos(id_curso) ON DELETE CASCADE,
  estado VARCHAR(50) NOT NULL CHECK (estado IN ('pendiente','aceptado','rechazado','cancelado','no_presentado')) DEFAULT 'pendiente',
  fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_respuesta TIMESTAMP,
  comentarios TEXT
);

CREATE INDEX idx_estado_solicitud ON solicitudes(estado);
CREATE INDEX idx_usuario_solicitud ON solicitudes(id_usuario);
CREATE INDEX idx_curso_solicitud ON solicitudes(id_curso);
CREATE UNIQUE INDEX idx_usuario_curso_unique ON solicitudes(id_usuario, id_curso);

-- ==========================================
-- VISTA: CATÁLOGO DE CURSOS PARA USUARIOS
-- ==========================================
CREATE VIEW vista_catalogo_cursos AS
SELECT 
  c.id_curso,
  c.nombre AS curso,
  cat.id_categoria,
  cat.nombre AS categoria,
  c.descripcion,
  c.fecha_inicio,
  c.fecha_fin,
  c.capacidad,
  c.capacidad_adicional,
  COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END) AS aceptados,
  GREATEST(c.capacidad - COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END), 0) AS plazas_disponibles,
  CASE 
    WHEN COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END) >= c.capacidad THEN 'LLENO'
    WHEN COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END) >= (c.capacidad - 2) THEN 'CASI_LLENO'
    ELSE 'DISPONIBLE'
  END AS disponibilidad
FROM cursos c
INNER JOIN categorias cat ON c.id_categoria = cat.id_categoria
LEFT JOIN solicitudes s ON c.id_curso = s.id_curso
WHERE c.estado = 'activo' AND c.visibilidad = 'publica' AND cat.activo = TRUE
GROUP BY c.id_curso, c.nombre, cat.id_categoria, cat.nombre, c.descripcion, c.fecha_inicio, c.fecha_fin, c.capacidad, c.capacidad_adicional;

-- ==========================================
-- TABLA: LISTA_ESPERA
-- ==========================================
CREATE TABLE lista_espera (
  id_espera SERIAL PRIMARY KEY,
  id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  id_curso INTEGER NOT NULL REFERENCES cursos(id_curso) ON DELETE CASCADE,
  id_solicitud INTEGER NOT NULL REFERENCES solicitudes(id_solicitud) ON DELETE CASCADE,
  posicion INTEGER NOT NULL,
  fecha_inscripcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(50) NOT NULL CHECK (estado IN ('en_espera','promovido','rechazado')) DEFAULT 'en_espera',
  fecha_promocion TIMESTAMP
);

CREATE INDEX idx_posicion ON lista_espera(posicion);
CREATE INDEX idx_estado_espera ON lista_espera(estado);
CREATE INDEX idx_usuario_espera ON lista_espera(id_usuario);
CREATE INDEX idx_curso_espera ON lista_espera(id_curso);
CREATE UNIQUE INDEX idx_usuario_curso_espera_unique ON lista_espera(id_usuario, id_curso);

-- ==========================================
-- TABLA: AUDITORIA
-- ==========================================
CREATE TABLE auditoria (
  id_auditoria SERIAL PRIMARY KEY,
  tabla VARCHAR(100) NOT NULL,
  operacion VARCHAR(50) NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
  id_usuario INTEGER REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  datos_anteriores JSONB,
  datos_nuevos JSONB,
  fecha_operacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tabla_auditoria ON auditoria(tabla);
CREATE INDEX idx_operacion_auditoria ON auditoria(operacion);
CREATE INDEX idx_fecha_auditoria ON auditoria(fecha_operacion);

-- ==========================================
-- VISTAS SQL
-- ==========================================

-- Vista: Ocupación de cursos
CREATE VIEW vista_ocupacion_cursos AS
SELECT 
  c.id_curso,
  c.nombre,
  c.capacidad,
  c.capacidad_adicional,
  COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END) AS aceptados,
  COUNT(CASE WHEN s.estado = 'pendiente' THEN 1 END) AS pendientes,
  COUNT(CASE WHEN s.estado = 'rechazado' THEN 1 END) AS rechazados,
  COUNT(CASE WHEN le.estado = 'en_espera' THEN 1 END) AS en_lista_espera,
  CASE 
    WHEN COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END) >= c.capacidad THEN 'LLENO'
    WHEN COUNT(CASE WHEN s.estado = 'aceptado' THEN 1 END) >= (c.capacidad - 2) THEN 'CASI_LLENO'
    ELSE 'DISPONIBLE'
  END AS disponibilidad
FROM cursos c
LEFT JOIN solicitudes s ON c.id_curso = s.id_curso
LEFT JOIN lista_espera le ON c.id_curso = le.id_curso
GROUP BY c.id_curso, c.nombre, c.capacidad, c.capacidad_adicional;

-- Vista: Candidatos por curso
CREATE VIEW vista_candidatos_por_curso AS
SELECT 
  c.id_curso,
  c.nombre AS curso,
  u.id_usuario,
  u.nombre AS usuario,
  u.email,
  s.estado,
  s.fecha_solicitud,
  CASE WHEN le.id_espera IS NOT NULL THEN le.posicion ELSE NULL END AS posicion_espera
FROM cursos c
INNER JOIN solicitudes s ON c.id_curso = s.id_curso
INNER JOIN usuarios u ON s.id_usuario = u.id_usuario
LEFT JOIN lista_espera le ON s.id_solicitud = le.id_solicitud
ORDER BY c.id_curso, s.fecha_solicitud;

-- Vista: Mis solicitudes (usuario)
CREATE VIEW vista_mis_solicitudes_usuario AS
SELECT 
  u.id_usuario,
  u.nombre AS usuario,
  c.id_curso,
  c.nombre AS curso,
  s.estado,
  s.fecha_solicitud,
  le.posicion AS posicion_en_lista,
  le.estado AS estado_en_lista
FROM usuarios u
INNER JOIN solicitudes s ON u.id_usuario = s.id_usuario
INNER JOIN cursos c ON s.id_curso = c.id_curso
LEFT JOIN lista_espera le ON s.id_solicitud = le.id_solicitud
ORDER BY u.id_usuario, s.fecha_solicitud DESC;

-- ==========================================
-- FUNCIÓN: Auditoría (trigger helper)
-- ==========================================

CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO auditoria (tabla, operacion, datos_anteriores, datos_nuevos)
  VALUES (
    TG_TABLE_NAME,
    TG_OP::text,
    to_jsonb(OLD),
    to_jsonb(NEW)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers de auditoría
CREATE TRIGGER trigger_audit_usuarios AFTER INSERT OR UPDATE OR DELETE ON usuarios
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER trigger_audit_cursos AFTER INSERT OR UPDATE OR DELETE ON cursos
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER trigger_audit_solicitudes AFTER INSERT OR UPDATE OR DELETE ON solicitudes
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER trigger_audit_lista_espera AFTER INSERT OR UPDATE OR DELETE ON lista_espera
FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();

-- ==========================================
-- FIN DE INICIALIZACIÓN
-- ==========================================
