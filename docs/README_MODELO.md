#  Modelo de Base de Datos CourseFlow

##  Resumen Rápido

Se ha diseñado un **modelo entidad-relación completo** para la plataforma CourseFlow, basado en los requerimientos del proyecto pedagógico de Somos F5. El modelo incluye una **entidad dedicada a la lista de espera** que permite gestionar automáticamente las promociones cuando hay bajas de usuarios.

###  Características Principales
-  6 tablas principales con relaciones 1:N
-  Entidad **CATEGORIAS** para clasificar cursos y filtrar desde el panel de usuarios
-  Entidad **LISTA_ESPERA** para gestión automática de candidatos
-  Sistema de roles (usuario, administrador)
-  Auditoría completa de operaciones
-  Índices optimizados para rendimiento
-  4 vistas SQL para reportes comunes
-  Compatible con PostgreSQL, MySQL y MariaDB

---

##  Archivos Generados

| Archivo | Formato | Descripción |
|---------|---------|-------------|
| **modelo_er_courseflow.json** | JSON | Importable directamente en drawDB |
| **modelo_er_courseflow.sql** | SQL | Script con tablas, índices y vistas |
| **MODELO_ER.md** | Markdown | Documentación técnica completa |
| **DIAGRAMA_ER_MERMAID.md** | Mermaid | Diagramas visuales y flujos |
| **drawdb_formato_yaml.yml** | YAML | Referencia alternativa para drawDB |
| **README_MODELO.md** | Markdown | Esta guía |

---

## Cómo Usar

### Opción 1: Importar en drawDB (RECOMENDADO)

#### Paso 1: Abrir drawDB
1. Ve a [drawdb.app](https://drawdb.app)
2. Haz clic en el icono de menú (esquina superior izquierda)

#### Paso 2: Importar JSON
1. Selecciona **File → Import**
2. Elige el archivo `modelo_er_courseflow.json`
3. ¡Listo! Tu modelo aparecerá con todas las entidades y relaciones

#### Paso 3: Personalizar (opcional)
- Ajusta posiciones de las tablas
- Modifica colores
- Agrega notas o comentarios
- Exporta en PNG/PDF

### Opción 2: Crear Base de Datos

#### Usando MySQL/PostgreSQL:
```bash
# Conectar a tu base de datos
mysql -u usuario -p nombre_bd < modelo_er_courseflow.sql

# O con PostgreSQL
psql -U usuario -d nombre_bd -f modelo_er_courseflow.sql
```

#### Usando pgAdmin o Adminer:
1. Abre tu gestor de bases de datos
2. Copia el contenido de `modelo_er_courseflow.sql`
3. Ejecuta como nueva consulta
4. Se crearán automáticamente:
   - 6 tablas
   - 16 índices
   - 4 vistas

### Opción 3: Crear Manualmente (Frontend)

Si usas una interfaz gráfica:

1. **Crea las tablas:**
   - `usuarios`
   - `categorias`
   - `cursos`
   - `solicitudes`
   - `lista_espera`
   - `auditoria`

2. **Define los campos** (ver MODELO_ER.md)

3. **Establece las relaciones:**
   - USUARIOS ← → SOLICITUDES (1:N)
   - CATEGORIAS ← → CURSOS (1:N)
   - CURSOS ← → SOLICITUDES (1:N)
   - USUARIOS ← → LISTA_ESPERA (1:N)
   - CURSOS ← → LISTA_ESPERA (1:N)
   - SOLICITUDES ← → LISTA_ESPERA (1:N)
   - USUARIOS ← → AUDITORIA (1:N)

---

##  Descripción de Entidades Principales

### USUARIOS
Almacena datos de usuarios del sistema.
- Roles: `usuario` o `administrador`
- Estados: `activo` o `inactivo`

### CURSOS
Información de cursos disponibles.
- Estados: `activo`, `inactivo`, `en_curso`, `finalizado`
- Capacidad: número de plazas + sobre-reserva opcional

### SOLICITUDES
Solicitudes de inscripción en cursos.
- Estados: `pendiente`, `aceptado`, `rechazado`, `cancelado`, `no_presentado`
- Registro de cuándo se solicitó y se respondió

### LISTA_ESPERA  **(Entidad Nueva)**
Gestión de candidatos en lista de espera.
- Ordenados por posición
- Estados: `en_espera`, `promovido`, `rechazado`
- Timestamp de promoción automática

### AUDITORIA
Registro de todas las operaciones (INSERT, UPDATE, DELETE).
- Almacena datos anteriores y nuevos en JSON
- Permite trazabilidad completa

---

##  Flujo de Negocio Principal

```
1. Usuario solicita inscripción
   ↓
2. Se crea registro en SOLICITUDES (estado='pendiente')
   ↓
3. Admin revisa solicitud
   ↓
4. Si hay plaza disponible → ACEPTADO
   Si no hay plaza         → Insertar en LISTA_ESPERA
   ↓
5. Si hay cancelación
   ↓
6. Promover automáticamente el primer candidato
   → UPDATE SOLICITUDES (estado='aceptado')
   → UPDATE LISTA_ESPERA (estado='promovido')
   → Reordenar posiciones del resto
```

---

##  Relaciones del Modelo

```
┌──────────────┐
│   USUARIOS   │ (1)
└──────┬───────┘
       │ realiza (N)
       │
       ├──→ SOLICITUDES ←── CURSOS
       │         │ (N)      (1)
       │         │ registra
       │         │
       │    LISTA_ESPERA ←── (tiene)
       │         │
       └──→ AUDITORIA
```

---

##  Vistas SQL Disponibles

El archivo SQL incluye 4 vistas útiles:

### 1. `vista_ocupacion_cursos`
Resumen de ocupación por curso con disponibilidad.

```sql
SELECT * FROM vista_ocupacion_cursos;
```

### 2. `vista_candidatos_por_curso`
Listado de candidatos con sus estados y posiciones en lista.

```sql
SELECT * FROM vista_candidatos_por_curso WHERE id_curso = 5;
```

### 3. `vista_mis_solicitudes_usuario`
Panel de usuario para ver su estado en todos los cursos.

```sql
SELECT * FROM vista_mis_solicitudes_usuario WHERE id_usuario = 10;
```

---

##  Índices para Rendimiento

Se han incluido **16 índices** optimizados para:
- Búsquedas de login (email)
- Filtros por estado
- Ordenamiento por posición (lista de espera)
- Evitar duplicados (UNIQUE)
- Auditoría eficiente

**Resultado:** Consultas rápidas incluso con miles de registros.

---

##  Estadísticas del Modelo

| Métrica | Valor |
|---------|-------|
| Total de tablas | 5 |
| Total de campos | 47 |
| Total de relaciones | 6 |
| Total de índices | 14 |
| Vistas SQL | 3 |
| Estados diferentes | 13 |
| Niveles de cardinalidad | Solo 1:N |

---

##  Seguridad e Integridad

### Restricciones Implementadas:
-  Claves primarias en todas las tablas
-  Claves foráneas con integridad referencial
-  Índices UNIQUE para evitar duplicados
-  Restricción UNIQUE en (usuario, curso)
-  Acciones CASCADE y SET NULL en deletes
-  Campos NOT NULL donde es necesario
-  ENUM para valores controlados

### Auditoria:
-  Tabla AUDITORIA con JSON para antes/después
-  Registro de qué usuario hizo cada operación
-  Timestamp automático de cada cambio
-  Tipo de operación registrado

---

##  Próximos Pasos

### Para Desarrolladores:

1. **Backend (Python/Flask/FastAPI)**
   - Crear modelos ORM (SQLAlchemy)
   - Implementar endpoints de CRUD
   - Lógica de promoción de lista de espera
   - Autenticación y autorización

2. **Frontend (Vue.js)**
   - Formulario de solicitud de inscripción
   - Panel de usuario para ver estado
   - Panel admin para gestionar solicitudes
   - Notificaciones de promoción

3. **API REST**
   - GET /api/cursos
   - POST /api/solicitudes
   - GET /api/mis-solicitudes
   - PUT /api/solicitudes/:id
   - GET /api/admin/solicitudes

### Para DBA:

1.  Crear base de datos (ejecutar SQL)
2.  Definir backups regulares
3.  Monitorear crecimiento de AUDITORIA
4.  Crear índices adicionales si es necesario
5.  Configurar archivos de log

### Para QA:

1.  Testear todos los estados de solicitud
2.  Validar promoción automática
3.  Verificar reorden de posiciones
4.  Testear integridad referencial
5.  Validar auditoria

---

##  Documentación Adicional

Para información detallada, consulta:
- **MODELO_ER.md** → Especificación técnica completa
- **DIAGRAMA_ER_MERMAID.md** → Diagramas visuales
- **modelo_er_courseflow.sql** → SQL con índices
- **modelo_er_courseflow.json** → Formato drawDB

---

##  Preguntas Frecuentes

### ¿Cómo funciona la lista de espera?

Cuando se acepta una solicitud y no hay plaza disponible:
1. Se inserta en LISTA_ESPERA con una posición
2. Si se cancela un usuario aceptado:
3. El primer candidato se promueve automáticamente
4. Su estado en SOLICITUDES cambia a 'aceptado'
5. El resto recibe nuevas posiciones

### ¿Se puede cambiar de estado múltiples veces?

Sí, el modelo permite:
- pendiente → aceptado (o rechazado)
- aceptado → cancelado
- en_lista_espera → promovido (o rechazado)

La AUDITORIA registra todos los cambios.

### ¿Cómo se garantiza que no haya duplicados?

Índice UNIQUE en `(id_usuario, id_curso)` evita:
- Dos solicitudes del mismo usuario en el mismo curso
- Dos registros en lista de espera del mismo usuario

### ¿Qué pasa si borro un usuario?

Con ON DELETE CASCADE:
- Se borran sus solicitudes
- Se borran sus registros de lista de espera
- Se borra su entrada en auditoria (si es autor)

---

##  Notas Importantes

1. **Seguridad:** Las contraseñas deben hashearse en la aplicación (bcrypt, argon2)
2. **Rendimiento:** Ejecutar ANALYZE en vistas después de grandes cambios
3. **Notificaciones:** Implementar sistema de notificaciones para promociones
4. **Escalabilidad:** Particionar tabla AUDITORIA si crece mucho
5. **Backups:** Realizar backups diarios de la base de datos

---

##  Información del Proyecto

- **Plataforma:** CourseFlow
- **Organización:** Somos F5
- **Formadores:** Equipo pedagógico F5
- **Alcance:** Gestión de cursos y solicitudes
- **Stack:** Python/Flask + Vue.js + PostgreSQL
- **Metodología:** Scrum (sprints de 2 semanas)

---

##  Checklist de Implementación

- [ ] Crear base de datos en servidor
- [ ] Ejecutar script SQL
- [ ] Verificar tablas e índices
- [ ] Crear modelos ORM (backend)
- [ ] Implementar autenticación
- [ ] Desarrollar endpoints de cursos
- [ ] Desarrollar endpoints de solicitudes
- [ ] Programar lógica de lista de espera
- [ ] Crear formularios (frontend)
- [ ] Implementar panel de usuario
- [ ] Crear panel de administrador
- [ ] Agregar sistema de notificaciones
- [ ] Implementar auditoría en código
- [ ] Testing completo
- [ ] Documentación de API
- [ ] Deployment

---

**Última actualización:** 13 de mayo de 2026  
**Versión:** 1.0 - Modelo Base  
**Estado:** Listo para Implementación

---

*Para preguntas o mejoras, contacta al equipo de desarrollo.*
