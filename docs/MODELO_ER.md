# Modelo Entidad-Relación (ER) - CourseFlow
## Plataforma de Gestión de Cursos y Solicitudes

**Versión:** 1.0  
**Fecha:** 13 de mayo de 2026  
**Autor:** Equipo F5  
**Base de Datos:** PostgreSQL / MySQL

---

##  Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Entidades](#entidades)
3. [Relaciones](#relaciones)
4. [Flujos de Negocio](#flujos-de-negocio)
5. [Cómo Importar en drawDB](#cómo-importar-en-drawdb)
6. [Operaciones Principales](#operaciones-principales)

---

## Descripción General

Este modelo ER representa la estructura de datos para la aplicación **CourseFlow**, un sistema integral de gestión de cursos, solicitudes de participación y lista de espera.

### Características Principales:
-  Gestión de usuarios con roles (usuario, administrador)
-  Creación y gestión de cursos
-  Sistema de solicitudes de inscripción
-  **Lista de espera dinámica** (nuevaentidad agregada)
-  Auditoria de operaciones
-  Vistas SQL para reportes

---

## Entidades

### 1. **USUARIOS**
Almacena información de todos los usuarios del sistema.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| `id_usuario` | INT | PK, AI | Identificador único |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre completo |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Email único para login |
| `contraseña` | VARCHAR(255) | NOT NULL | Contraseña hasheada |
| `rol` | ENUM | DEFAULT 'usuario' | 'usuario' o 'administrador' |
| `estado` | ENUM | DEFAULT 'activo' | 'activo' o 'inactivo' |
| `fecha_creacion` | TIMESTAMP | DEFAULT NOW() | Timestamp de creación |

**Índices:**
- `idx_email` - Para búsquedas de login rápidas
- `idx_rol` - Para filtros por rol

---

### 2. **CURSOS**
Información de todos los cursos disponibles.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| `id_curso` | INT | PK, AI | Identificador único |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre del curso |
| `descripcion` | TEXT | NULL | Descripción detallada |
| `fecha_inicio` | DATE | NOT NULL | Inicio de curso |
| `fecha_fin` | DATE | NOT NULL | Fin de curso |
| `capacidad` | INT | NOT NULL | Número de plazas disponibles |
| `capacidad_adicional` | INT | DEFAULT 0 | Plazas extras para sobre-reserva |
| `estado` | ENUM | DEFAULT 'activo' | 'activo', 'inactivo', 'en_curso', 'finalizado' |
| `visibilidad` | ENUM | DEFAULT 'publica' | 'publica' o 'privada' |
| `fecha_creacion` | TIMESTAMP | DEFAULT NOW() | Timestamp de creación |

**Índices:**
- `idx_estado` - Para filtros por estado
- `idx_visibilidad` - Para mostrar cursos públicos
- `idx_fecha_inicio` - Para consultas por fechas

---

### 3. **SOLICITUDES**
Registro de solicitudes de inscripción de usuarios en cursos.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| `id_solicitud` | INT | PK, AI | Identificador único |
| `id_usuario` | INT | FK | Referencia a usuarios |
| `id_curso` | INT | FK | Referencia a cursos |
| `estado` | ENUM | DEFAULT 'pendiente' | 'pendiente', 'aceptado', 'rechazado', 'cancelado', 'no_presentado' |
| `fecha_solicitud` | TIMESTAMP | DEFAULT NOW() | Cuándo se solicitó |
| `fecha_respuesta` | TIMESTAMP | NULL | Cuándo se respondió |
| `comentarios` | TEXT | NULL | Observaciones del admin |

**Índices:**
- `idx_estado_solicitud` - Filtros rápidos por estado
- `idx_usuario_solicitud` - Solicitudes por usuario
- `idx_curso_solicitud` - Solicitudes por curso
- `idx_usuario_curso_unique` - Evita duplicados (usuario + curso únicos)

**Relaciones:**
- FK `id_usuario` → `usuarios.id_usuario` (ON DELETE CASCADE)
- FK `id_curso` → `cursos.id_curso` (ON DELETE CASCADE)

---

### 4. **LISTA_ESPERA** ⭐ (Nueva Entidad)
Control de candidatos en lista de espera para cada curso.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| `id_espera` | INT | PK, AI | Identificador único |
| `id_usuario` | INT | FK | Referencia a usuarios |
| `id_curso` | INT | FK | Referencia a cursos |
| `id_solicitud` | INT | FK | Referencia a solicitudes |
| `posicion` | INT | NOT NULL | Posición en la lista (1, 2, 3...) |
| `fecha_inscripcion` | TIMESTAMP | DEFAULT NOW() | Cuándo entró en lista |
| `estado` | ENUM | DEFAULT 'en_espera' | 'en_espera', 'promovido', 'rechazado' |
| `fecha_promocion` | TIMESTAMP | NULL | Cuándo fue promovido a aceptado |

**Índices:**
- `idx_posicion` - Ordenamiento por posición
- `idx_estado_espera` - Filtros de estado
- `idx_usuario_espera` - Listas de cada usuario
- `idx_curso_espera` - Listas por curso
- `idx_usuario_curso_espera_unique` - Evita duplicados

**Relaciones:**
- FK `id_usuario` → `usuarios.id_usuario` (ON DELETE CASCADE)
- FK `id_curso` → `cursos.id_curso` (ON DELETE CASCADE)
- FK `id_solicitud` → `solicitudes.id_solicitud` (ON DELETE CASCADE)

---

### 5. **AUDITORIA**
Registro de todas las operaciones en el sistema.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| `id_auditoria` | INT | PK, AI | Identificador único |
| `tabla` | VARCHAR(100) | NOT NULL | Tabla modificada |
| `operacion` | ENUM | NOT NULL | 'INSERT', 'UPDATE', 'DELETE' |
| `id_usuario` | INT | FK | Usuario que ejecutó |
| `datos_anteriores` | JSON | NULL | Estado previo (UPDATE/DELETE) |
| `datos_nuevos` | JSON | NULL | Nuevo estado (INSERT/UPDATE) |
| `fecha_operacion` | TIMESTAMP | DEFAULT NOW() | Cuándo ocurrió |

**Índices:**
- `idx_tabla_auditoria` - Auditar tabla específica
- `idx_operacion_auditoria` - Filtrar por tipo de operación
- `idx_fecha_auditoria` - Reportes por período

---

## Relaciones

### Diagrama de Relaciones (Texto)

```
USUARIOS
  ├── 1:N ──→ SOLICITUDES (realiza)
  ├── 1:N ──→ LISTA_ESPERA (espera)
  └── 1:N ──→ AUDITORIA (ejecuta)

CURSOS
  ├── 1:N ──→ SOLICITUDES (recibe)
  └── 1:N ──→ LISTA_ESPERA (tiene)

SOLICITUDES
  └── 1:N ──→ LISTA_ESPERA (registra)
```

### Tabla de Relaciones

| ID | De | A | Cardinalidad | Etiqueta | Acciones |
|----|----|---|--------------|----------|----------|
| rel_usuarios_solicitudes | USUARIOS | SOLICITUDES | 1:N | realiza | CASCADE |
| rel_cursos_solicitudes | CURSOS | SOLICITUDES | 1:N | recibe | CASCADE |
| rel_usuarios_lista_espera | USUARIOS | LISTA_ESPERA | 1:N | espera | CASCADE |
| rel_cursos_lista_espera | CURSOS | LISTA_ESPERA | 1:N | tiene | CASCADE |
| rel_solicitudes_lista_espera | SOLICITUDES | LISTA_ESPERA | 1:N | registra | CASCADE |
| rel_usuarios_auditoria | USUARIOS | AUDITORIA | 1:N | ejecuta | SET NULL |

---

## Flujos de Negocio

### Flujo 1: Solicitud de Inscripción Normal

```
1. Usuario solicita inscripción en curso
   └─ INSERT en SOLICITUDES (estado='pendiente')

2. Admin revisa solicitud
   └─ UPDATE SOLICITUDES (estado='aceptado')
   
3. Sistema verifica capacidad
   └─ Si hay plaza disponible: usuario aceptado
   └─ Si no hay plaza: INSERT en LISTA_ESPERA (posicion=N)
```

### Flujo 2: Promoción desde Lista de Espera

```
1. Usuario aceptado cancela su inscripción
   └─ UPDATE SOLICITUDES (estado='cancelado')

2. Sistema detecta plaza disponible
   └─ SELECT * FROM LISTA_ESPERA 
      WHERE id_curso=X 
      ORDER BY posicion LIMIT 1

3. Sistema promueve primer candidato
   └─ UPDATE SOLICITUDES (estado='aceptado')
   └─ UPDATE LISTA_ESPERA (estado='promovido', fecha_promocion=NOW())
   └─ INSERT en LISTA_ESPERA nuevas posiciones (reordenar)
```

### Flujo 3: Rechazo de Solicitud

```
1. Admin rechaza solicitud
   └─ UPDATE SOLICITUDES (estado='rechazado')

2. Si usuario estaba en lista de espera
   └─ UPDATE LISTA_ESPERA (estado='rechazado')
   └─ Reordenar posiciones de candidatos restantes
```

---

## Vistas SQL Disponibles

### Vista: `vista_ocupacion_cursos`
Resumen de ocupación y disponibilidad de cada curso.

```sql
SELECT * FROM vista_ocupacion_cursos;
```

**Columnas:**
- `id_curso` - ID del curso
- `nombre` - Nombre del curso
- `capacidad` - Plazas disponibles
- `aceptados` - Usuarios aceptados
- `pendientes` - Solicitudes pendientes
- `rechazados` - Solicitudes rechazadas
- `en_lista_espera` - Candidatos en lista
- `disponibilidad` - Estado (DISPONIBLE, CASI_LLENO, LLENO)

---

### Vista: `vista_candidatos_por_curso`
Listado de candidatos con su estado en cada curso.

```sql
SELECT * FROM vista_candidatos_por_curso WHERE id_curso = 5;
```

---

### Vista: `vista_mis_solicitudes_usuario`
Solicitudes de cada usuario (para panel de usuario).

```sql
SELECT * FROM vista_mis_solicitudes_usuario WHERE id_usuario = 10;
```

---

## Cómo Importar en drawDB

### Opción 1: Importar JSON Directamente

1. Abre [drawDB.app](https://drawdb.app)
2. Haz clic en **"File" → "Import"**
3. Selecciona el archivo `modelo_er_courseflow.json`
4. El modelo aparecerá automáticamente con todas las entidades y relaciones

### Opción 2: Importar SQL

1. En drawDB, ve a **"File" → "New from SQL"**
2. Copia el contenido de `modelo_er_courseflow.sql`
3. Pégalo en el editor SQL de drawDB
4. Haz clic en **"Create Tables"**

### Opción 3: Crear Manualmente (si prefieres)

1. Crea 5 tablas:
   - `usuarios`
   - `cursos`
   - `solicitudes`
   - `lista_espera`
   - `auditoria`

2. Agrega los campos según las especificaciones en [Entidades](#entidades)

3. Establece las relaciones según [Relaciones](#relaciones)

---

## Operaciones Principales

### Crear Solicitud
```sql
INSERT INTO solicitudes (id_usuario, id_curso, estado)
VALUES (?, ?, 'pendiente');
```

### Aceptar Solicitud (Sin Lista de Espera)
```sql
UPDATE solicitudes 
SET estado = 'aceptado', fecha_respuesta = NOW()
WHERE id_solicitud = ?;
```

### Aceptar Solicitud (Verificar Capacidad)
```sql
BEGIN;
  DECLARE @aceptados INT = (
    SELECT COUNT(*) FROM solicitudes 
    WHERE id_curso = ? AND estado = 'aceptado'
  );
  
  IF @aceptados < (SELECT capacidad FROM cursos WHERE id_curso = ?)
  THEN
    UPDATE solicitudes SET estado = 'aceptado', fecha_respuesta = NOW()
    WHERE id_solicitud = ?;
  ELSE
    INSERT INTO lista_espera (id_usuario, id_curso, id_solicitud, posicion)
    VALUES (?, ?, ?, 
      (SELECT COUNT(*) + 1 FROM lista_espera WHERE id_curso = ?)
    );
  END IF;
COMMIT;
```

### Cancelar Inscripción y Promover de Lista
```sql
BEGIN;
  UPDATE solicitudes SET estado = 'cancelado'
  WHERE id_solicitud = ?;
  
  -- Promover primer candidato
  UPDATE solicitudes SET estado = 'aceptado', fecha_respuesta = NOW()
  WHERE id_solicitud = (
    SELECT id_solicitud FROM lista_espera 
    WHERE id_curso = ? ORDER BY posicion LIMIT 1
  );
  
  -- Actualizar estado en lista de espera
  UPDATE lista_espera SET estado = 'promovido', fecha_promocion = NOW()
  WHERE id_curso = ? ORDER BY posicion LIMIT 1;
  
  -- Reordenar posiciones
  UPDATE lista_espera SET posicion = posicion - 1
  WHERE id_curso = ? AND posicion > 1;
COMMIT;
```

### Listar Candidatos en Orden de Prioridad
```sql
SELECT u.nombre, u.email, le.posicion, le.fecha_inscripcion
FROM lista_espera le
INNER JOIN usuarios u ON le.id_usuario = u.id_usuario
WHERE le.id_curso = ? AND le.estado = 'en_espera'
ORDER BY le.posicion;
```

---

## Notas Importantes

###  Restricciones de Integridad
- Un usuario solo puede tener una solicitud activa por curso (`UNIQUE KEY`)
- Las claves foráneas tienen `ON DELETE CASCADE` para mantener consistencia
- La tabla de auditoria permite rastrear todos los cambios

###  Mejoras Futuras
- Implementar roles más granulares (moderadores, instructores)
- Añadir sistema de notificaciones
- Implementar feedback y calificaciones de cursos
- Estadísticas y reportes avanzados
- Integración con OAuth/LDAP

###  Consideraciones de Rendimiento
- Índices optimizados para búsquedas frecuentes
- Vistas materializadas recomendadas para reportes grandes
- Considerar particionamiento de `auditoria` si crece mucho

---

## Archivos Generados

1. **`modelo_er_courseflow.json`** - Formato importable en drawDB
2. **`modelo_er_courseflow.sql`** - Script SQL con todas las tablas, índices y vistas
3. **`MODELO_ER.md`** - Este documento (especificación completa)

---

**Última actualización:** 13 de mayo de 2026  
**Proyecto:** CourseFlow - Somos F5  
**Estado:**  Listo para implementar
