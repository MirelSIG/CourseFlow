-- Modelo de Base de Datos para CourseFlow
-- Plataforma de Gestión de Cursos y Solicitudes
-- Fecha: 2026-05-13

-- ==========================================
-- TABLA: USUARIOS
-- ==========================================
CREATE TABLE usuarios (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  contraseña VARCHAR(255) NOT NULL,
  rol ENUM('usuario','administrador') NOT NULL DEFAULT 'usuario',
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para usuarios
CREATE INDEX idx_email ON usuarios(email);
CREATE INDEX idx_rol ON usuarios(rol);

-- ==========================================
-- TABLA: CATEGORIAS
-- ==========================================
CREATE TABLE categorias (
  id_categoria INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activo_categoria ON categorias(activo);

-- ==========================================
-- TABLA: CURSOS
-- ==========================================
CREATE TABLE cursos (
  id_curso INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_categoria INT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  capacidad INT NOT NULL,
  capacidad_adicional INT NOT NULL DEFAULT 0,
  estado ENUM('activo','inactivo','en_curso','finalizado') NOT NULL DEFAULT 'activo',
  visibilidad ENUM('publica','privada') NOT NULL DEFAULT 'publica',
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria) ON DELETE RESTRICT
);

-- Índices para cursos
CREATE INDEX idx_categoria ON cursos(id_categoria);
CREATE INDEX idx_estado ON cursos(estado);
CREATE INDEX idx_visibilidad ON cursos(visibilidad);
CREATE INDEX idx_fecha_inicio ON cursos(fecha_inicio);

-- ==========================================
-- TABLA: SOLICITUDES
-- ==========================================
CREATE TABLE solicitudes (
  id_solicitud INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_usuario INT NOT NULL,
  id_curso INT NOT NULL,
  estado ENUM('pendiente','aceptado','rechazado','cancelado','no_presentado') NOT NULL DEFAULT 'pendiente',
  fecha_solicitud TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_respuesta TIMESTAMP,
  comentarios TEXT,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE
);

-- Índices para solicitudes
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
  id_espera INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  id_usuario INT NOT NULL,
  id_curso INT NOT NULL,
  id_solicitud INT NOT NULL,
  posicion INT NOT NULL,
  fecha_inscripcion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('en_espera','promovido','rechazado') NOT NULL DEFAULT 'en_espera',
  fecha_promocion TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE,
  FOREIGN KEY (id_solicitud) REFERENCES solicitudes(id_solicitud) ON DELETE CASCADE
);

-- Índices para lista_espera
CREATE INDEX idx_posicion ON lista_espera(posicion);
CREATE INDEX idx_estado_espera ON lista_espera(estado);
CREATE INDEX idx_usuario_espera ON lista_espera(id_usuario);
CREATE INDEX idx_curso_espera ON lista_espera(id_curso);
CREATE UNIQUE INDEX idx_usuario_curso_espera_unique ON lista_espera(id_usuario, id_curso);

-- ==========================================
-- TABLA: AUDITORIA
-- ==========================================
CREATE TABLE auditoria (
  id_auditoria INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
  tabla VARCHAR(100) NOT NULL,
  operacion ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  id_usuario INT,
  datos_anteriores JSON,
  datos_nuevos JSON,
  fecha_operacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);

-- Índices para auditoria
CREATE INDEX idx_tabla_auditoria ON auditoria(tabla);
CREATE INDEX idx_operacion_auditoria ON auditoria(operacion);
CREATE INDEX idx_fecha_auditoria ON auditoria(fecha_operacion);

-- ==========================================
-- VISTAS ÚTILES
-- ==========================================

-- Vista: Resumen de ocupación por curso
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

-- Vista: Candidatos por curso con estado
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

-- Vista: Estado de solicitudes por usuario
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
