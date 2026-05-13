-- ==========================================
-- DATOS DE PRUEBA - COURSEFLOW
-- ==========================================

-- ==========================================
-- USUARIOS DE PRUEBA
-- ==========================================

INSERT INTO usuarios (nombre, email, contraseña, rol, estado) VALUES
('Admin Somos F5', 'admin@somosf5.com', '$2b$12$...hashed_password...', 'administrador', 'activo'),
('Juan García López', 'juan@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo'),
('María Rodríguez Silva', 'maria@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo'),
('Carlos Martínez Ruiz', 'carlos@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo'),
('Ana Fernández Díaz', 'ana@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo'),
('Pedro López García', 'pedro@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo'),
('Sofia González Torres', 'sofia@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo'),
('David Sánchez Martín', 'david@example.com', '$2b$12$...hashed_password...', 'usuario', 'activo');

-- ==========================================
-- CURSOS DE PRUEBA
-- ==========================================

INSERT INTO categorias (nombre, descripcion, activo) VALUES
('Programación', 'Cursos orientados a lógica, lenguaje y desarrollo backend', TRUE),
('Frontend', 'Cursos para interfaces y experiencias de usuario', TRUE),
('Bases de Datos', 'Modelado, consulta y optimización de datos', TRUE),
('DevOps', 'Infraestructura, despliegue y contenedores', TRUE),
('Fullstack', 'Cursos con stack completo frontend y backend', TRUE),
('Seguridad', 'Buenas prácticas y protección de aplicaciones', TRUE);

INSERT INTO cursos (id_categoria, nombre, descripcion, fecha_inicio, fecha_fin, capacidad, capacidad_adicional, estado, visibilidad) VALUES
(1, 'Python Avanzado', 'Curso de programación Python nivel avanzado con frameworks modernos', '2026-06-01', '2026-06-30', 20, 5, 'activo', 'publica'),
(2, 'JavaScript y React', 'Desarrollo frontend con React.js y JavaScript moderno', '2026-06-15', '2026-07-15', 15, 3, 'activo', 'publica'),
(3, 'Bases de Datos SQL', 'Diseño y optimización de bases de datos relacionales', '2026-07-01', '2026-07-31', 25, 5, 'activo', 'publica'),
(4, 'DevOps y Docker', 'Contenedorización y orquestación de aplicaciones', '2026-06-10', '2026-07-10', 12, 2, 'activo', 'publica'),
(5, 'Desarrollo Fullstack', 'Stack completo: Backend Python + Frontend Vue.js', '2026-06-20', '2026-08-20', 18, 4, 'inactivo', 'publica'),
(6, 'Seguridad Web', 'OWASP, SSL/TLS, autenticación y autorización', '2026-07-15', '2026-08-15', 10, 2, 'activo', 'privada');

-- ==========================================
-- SOLICITUDES DE PRUEBA
-- ==========================================

-- Curso 1: Python Avanzado (20 plazas + 5 adicionales)
INSERT INTO solicitudes (id_usuario, id_curso, estado, fecha_solicitud) VALUES
(2, 1, 'aceptado', '2026-05-01 10:00:00'),
(3, 1, 'aceptado', '2026-05-02 11:00:00'),
(4, 1, 'aceptado', '2026-05-03 12:00:00'),
(5, 1, 'aceptado', '2026-05-04 13:00:00'),
(6, 1, 'aceptado', '2026-05-05 14:00:00'),
(7, 1, 'aceptado', '2026-05-06 15:00:00'),
(8, 1, 'pendiente', '2026-05-07 16:00:00'),
(2, 2, 'aceptado', '2026-05-01 09:00:00'),
(3, 2, 'aceptado', '2026-05-02 10:00:00'),
(4, 2, 'rechazado', '2026-05-03 11:00:00'),
(5, 3, 'aceptado', '2026-05-01 08:00:00'),
(6, 3, 'pendiente', '2026-05-02 09:00:00'),
(7, 4, 'cancelado', '2026-05-01 07:00:00'),
(8, 4, 'aceptado', '2026-05-03 10:00:00');

-- ==========================================
-- LISTA DE ESPERA DE PRUEBA
-- ==========================================

-- Lista de espera para Curso 1 (Python) - cuando se llena
INSERT INTO lista_espera (id_usuario, id_curso, id_solicitud, posicion, estado, fecha_inscripcion) VALUES
(5, 1, 5, 1, 'en_espera', '2026-05-05 14:30:00'),
(6, 1, 6, 2, 'en_espera', '2026-05-06 15:30:00');

-- Ejemplo de promoción anterior (simulado)
-- (Si existiera un usuario que fue promovido)

-- ==========================================
-- COMENTARIO
-- ==========================================

/*
NOTAS SOBRE LOS DATOS DE PRUEBA:

1. USUARIOS:
   - 1 usuario administrador
   - 7 usuarios regulares para pruebas
   - Las contraseñas están hasheadas (usar bcrypt en la aplicación)

2. CURSOS:
   - 6 cursos de ejemplo con diferentes capacidades
   - Algunos activos, otros inactivos
   - Mezcla de visibilidad pública y privada

3. SOLICITUDES:
   - Aceptadas: Usuarios inscritos en cursos
   - Pendientes: Solicitudes que aún no se procesan
   - Rechazadas: Usuarios no aceptados
   - Canceladas: Usuarios que se dieron de baja

4. LISTA DE ESPERA:
   - Candidatos esperando una plaza disponible
   - Ordenados por posición
   - Puede haber promociones cuando hay bajas

PARA GENERAR CONTRASEÑAS HASHEADAS:
pip install bcrypt
python -c "import bcrypt; print(bcrypt.hashpw(b'password123', bcrypt.gensalt()).decode())"

O usar en la aplicación Flask/FastAPI:
from werkzeug.security import generate_password_hash
hash = generate_password_hash('password123')
*/
