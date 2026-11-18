# MediAgenda — Diccionario de datos

**Proyecto:** MediAgenda (app móvil) · Equipo 6
**Base de datos:** MySQL / MariaDB en Hostinger · Motor InnoDB · `utf8mb4_general_ci`
**Script:** `database/mediagenda.sql` · **Diagrama:** `database/diagrama_er.png`
**Fecha:** 17/11/2026 (actualizado con la duración del token y la definición de «Reprogramada», Requisitos v8)

**Abreviaturas:** PK = llave primaria · FK = llave foránea · UQ = valor único · AI = autoincremental · NN = no nulo · CK = restricción CHECK

## Resumen de tablas

| N° | Tabla | Área | Descripción | Requisitos |
|---|---|---|---|---|
| 1 | `usuario` | Usuarios | Cuenta para iniciar sesión, común a pacientes y médicos | RF-02, RF-03, RNF-01 |
| 2 | `paciente` | Usuarios | Datos personales y de contacto del paciente | RF-01, RF-08 |
| 3 | `historial_medico` | Usuarios | Información clínica capturada en el registro | RF-01, RF-17, RNF-24 |
| 4 | `medico` | Usuarios | Datos del médico, su especialidad y consultorio | RF-06, RF-20 |
| 5 | `especialidad` | Catálogos | Especialidades médicas | RF-06 |
| 6 | `consultorio` | Catálogos | Consultorios donde se dan las citas | RF-09, RF-20 |
| 7 | `horario_medico` | Catálogos | Horario de atención del médico por día | RF-07, RF-20 |
| 8 | `cita` | Citas | Citas entre paciente y médico | RF-09 a RF-16, RF-24 |
| 9 | `cambio_cita` | Citas | Historial de cancelaciones y reprogramaciones | RF-14, RF-23, RF-25 |
| 10 | `bitacora` | Seguridad | Registro de las operaciones de los usuarios | RF-26, RNF-20 |
| 11 | `codigo_recuperacion` | Seguridad | Códigos para recuperar la contraseña | RF-05, RNF-21 |
| 12 | `token_sesion` | Seguridad | Tokens que autentican las peticiones de la app | RNF-03, RNF-04 |

## Relaciones

| Tabla padre | Tabla hija (FK) | Cardinalidad | Al borrar el padre |
|---|---|---|---|
| `usuario` | `paciente` (`id_usuario`) | 1 : 0..1 | Se impide |
| `usuario` | `medico` (`id_usuario`) | 1 : 0..1 | Se impide |
| `paciente` | `historial_medico` (`id_paciente`) | 1 : 0..1 | Se borra en cascada |
| `especialidad` | `medico` (`id_especialidad`) | 1 : N | Se impide |
| `consultorio` | `medico` (`id_consultorio`) | 1 : N | Se impide |
| `medico` | `horario_medico` (`id_medico`) | 1 : N | Se impide |
| `paciente` | `cita` (`id_paciente`) | 1 : N | Se impide |
| `medico` | `cita` (`id_medico`) | 1 : N | Se impide |
| `consultorio` | `cita` (`id_consultorio`) | 1 : N | Se impide |
| `cita` | `cambio_cita` (`id_cita`) | 1 : N | Se impide |
| `usuario` | `cambio_cita` (`id_usuario`) | 1 : N | Se impide |
| `usuario` | `bitacora` (`id_usuario`) | 1 : N | Se impide |
| `usuario` | `codigo_recuperacion` (`id_usuario`) | 1 : N | Se borra en cascada |
| `usuario` | `token_sesion` (`id_usuario`) | 1 : N | Se borra en cascada |

Todas las llaves foráneas usan `ON UPDATE CASCADE`: si cambia el `id` del padre, se actualiza en la hija.

---

## 1. `usuario`
Cuenta para iniciar sesión. Pacientes y médicos usan la misma tabla; el campo `rol` decide qué módulo ve cada uno.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del usuario |
| `usuario` | VARCHAR(50) | No | UQ | — | Nombre de usuario para iniciar sesión |
| `correo` | VARCHAR(100) | No | UQ | — | Correo electrónico; también sirve para iniciar sesión y recuperar la contraseña |
| `contrasena` | VARCHAR(255) | No | — | — | Hash de la contraseña generado con `password_hash()` (bcrypt). Nunca en texto plano |
| `rol` | ENUM('paciente', 'medico') | No | — | — | Rol del usuario |
| `activo` | TINYINT(1) | No | — | 1 | 1 = cuenta activa, 0 = desactivada |
| `fecha_registro` | DATETIME | No | — | CURRENT_TIMESTAMP | Fecha y hora en que se creó la cuenta |

## 2. `paciente`
Datos personales (paso 1 del registro) y de contacto (paso 2). Todos los campos son obligatorios.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del paciente |
| `id_usuario` | INT | No | FK, UQ | — | Cuenta del paciente → `usuario.id` |
| `nombres` | VARCHAR(60) | No | — | — | Nombre(s) |
| `apellidos` | VARCHAR(80) | No | — | — | Apellido(s) |
| `fecha_nacimiento` | DATE | No | — | — | Fecha de nacimiento |
| `genero` | VARCHAR(20) | No | — | — | Género |
| `telefono` | CHAR(10) | No | CK | — | Teléfono de 10 dígitos, solo números |
| `codigo_postal` | CHAR(5) | No | CK | — | Código postal de 5 dígitos, solo números |
| `ciudad` | VARCHAR(60) | No | — | — | Ciudad |
| `estado` | VARCHAR(60) | No | — | — | Estado de la república |
| `direccion` | VARCHAR(150) | No | — | — | Calle, número y colonia |

**Restricciones:** `ck_paciente_telefono` (`^[0-9]{10}$`), `ck_paciente_cp` (`^[0-9]{5}$`).

## 3. `historial_medico`
Información clínica que el paciente captura en el paso 3 del registro. Solo la consulta el médico que tiene con él al menos una cita no cancelada. Si un dato no aplica, se guarda «Ninguna».

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del historial |
| `id_paciente` | INT | No | FK, UQ | — | Paciente dueño del historial → `paciente.id` |
| `tipo_sangre` | VARCHAR(15) | No | — | — | Tipo de sangre (p. ej. O+) |
| `peso` | DECIMAL(5,2) | No | — | — | Peso en kilogramos |
| `estatura` | DECIMAL(3,2) | No | — | — | Estatura en metros |
| `alergias` | VARCHAR(255) | No | — | — | Alergias conocidas |
| `enfermedades_cronicas` | VARCHAR(255) | No | — | — | Enfermedades crónicas o preexistentes |
| `medicamentos_actuales` | VARCHAR(255) | No | — | — | Medicamentos que toma actualmente |
| `cirugias_previas` | VARCHAR(255) | No | — | — | Cirugías anteriores |
| `antecedentes_familiares` | VARCHAR(255) | No | — | — | Enfermedades en la familia |
| `tabaquismo` | VARCHAR(100) | No | — | — | Consumo de tabaco |
| `consumo_alcohol` | VARCHAR(100) | No | — | — | Consumo de alcohol |

## 4. `medico`
Datos del médico. La app solo los lee.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del médico |
| `id_usuario` | INT | No | FK, UQ | — | Cuenta del médico → `usuario.id` |
| `nombres` | VARCHAR(60) | No | — | — | Nombre(s) |
| `apellidos` | VARCHAR(80) | No | — | — | Apellido(s) |
| `telefono` | CHAR(10) | No | — | — | Teléfono de contacto |
| `cedula_profesional` | VARCHAR(20) | No | UQ | — | Cédula profesional |
| `id_especialidad` | INT | No | FK | — | Especialidad → `especialidad.id` |
| `id_consultorio` | INT | No | FK | — | Consultorio asignado → `consultorio.id` |

## 5. `especialidad`
Catálogo de especialidades médicas. La app solo lo lee.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador de la especialidad |
| `nombre` | VARCHAR(80) | No | UQ | — | Nombre de la especialidad |

## 6. `consultorio`
Catálogo de consultorios. La app solo lo lee.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del consultorio |
| `nombre` | VARCHAR(50) | No | UQ | — | Nombre o número del consultorio |
| `ubicacion` | VARCHAR(150) | No | — | — | Piso y pasillo donde se encuentra |

## 7. `horario_medico`
Horario de atención del médico. Un registro por día y turno. La app solo lo lee.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del horario |
| `id_medico` | INT | No | FK | — | Médico → `medico.id` |
| `dia_semana` | TINYINT | No | CK | — | Día: 1 = lunes … 7 = domingo |
| `hora_inicio` | TIME | No | — | — | Hora en que empieza a atender |
| `hora_fin` | TIME | No | CK | — | Hora en que termina de atender |

**Restricciones:** `uq_horario` (`id_medico`, `dia_semana`, `hora_inicio`); `ck_horario_dia` (1 a 7); `ck_horario_horas` (`hora_fin` mayor que `hora_inicio`).

## 8. `cita`
Cita de 30 minutos entre un paciente y un médico.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador de la cita |
| `id_paciente` | INT | No | FK | — | Paciente → `paciente.id` |
| `id_medico` | INT | No | FK | — | Médico → `medico.id` |
| `id_consultorio` | INT | No | FK | — | Consultorio donde se da la cita → `consultorio.id`. Se guarda para conservarlo aunque el médico cambie de consultorio |
| `fecha` | DATE | No | — | — | Fecha de la cita |
| `hora` | TIME | No | CK | — | Hora de inicio; solo en punto o y media (:00 o :30) |
| `estado` | ENUM('Programada', 'Atendida', 'No asistió', 'Cancelada', 'Reprogramada') | No | — | 'Programada' | Estado actual de la cita. "Reprogramada" = cita activa que ya se movió una vez; no se puede volver a reprogramar |
| `fecha_creacion` | DATETIME | No | — | CURRENT_TIMESTAMP | Fecha y hora en que se agendó |
| `bloque_activo` | TINYINT (calculada) | Sí | — | — | Vale 1 si el estado es Programada o Reprogramada, y NULL en los demás. La calcula MySQL; no se escribe |

**Restricciones:**
- `uq_cita_medico_bloque` (`id_medico`, `fecha`, `hora`, `bloque_activo`): un médico no puede tener dos citas activas en el mismo bloque.
- `uq_cita_paciente_bloque` (`id_paciente`, `fecha`, `hora`, `bloque_activo`): un paciente no puede tener dos citas activas a la misma hora.
- `ck_cita_hora`: minutos en 0 o 30 y segundos en 0.
- Índices `ix_cita_fecha` e `ix_cita_estado` para las búsquedas de agenda y reportes.

## 9. `cambio_cita`
Historial de cambios. Guarda cada cancelación y reprogramación. Solo se inserta; nunca se modifica ni se borra.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del cambio |
| `id_cita` | INT | No | FK | — | Cita afectada → `cita.id` |
| `tipo` | ENUM('cancelacion', 'reprogramacion') | No | — | — | Tipo de cambio |
| `fecha_anterior` | DATE | No | — | — | Fecha que tenía la cita antes del cambio |
| `hora_anterior` | TIME | No | — | — | Hora que tenía la cita antes del cambio |
| `fecha_nueva` | DATE | Sí | — | NULL | Fecha nueva (solo en reprogramaciones) |
| `hora_nueva` | TIME | Sí | — | NULL | Hora nueva (solo en reprogramaciones) |
| `motivo` | VARCHAR(255) | Sí | — | NULL | Motivo del cambio |
| `id_usuario` | INT | No | FK | — | Quién hizo el cambio → `usuario.id` |
| `fecha_cambio` | DATETIME | No | — | CURRENT_TIMESTAMP | Cuándo se hizo el cambio |

**Índice:** `ix_cambio_fecha` para los reportes y estadísticas por periodo.

## 10. `bitacora`
Registro de operaciones: inicio de sesión, registro, recuperación de contraseña, agendado, cancelación, reprogramación, cambio de estado, consulta de historial de otras especialidades y reportes. Solo se inserta; nunca se modifica ni se borra.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del registro |
| `id_usuario` | INT | No | FK | — | Usuario que hizo la operación → `usuario.id` |
| `operacion` | VARCHAR(50) | No | — | — | Clave de la operación (p. ej. `INICIO_SESION`, `AGENDAR_CITA`) |
| `descripcion` | VARCHAR(255) | Sí | — | NULL | Detalle de la operación |
| `fecha_hora` | DATETIME | No | — | CURRENT_TIMESTAMP | Fecha y hora de la operación |

**Índice:** `ix_bitacora_fecha`.

## 11. `codigo_recuperacion`
Código de 6 dígitos para recuperar la contraseña. Es válido si `usado = 0`, `intentos < 3` y `fecha_expiracion` todavía no pasa.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del código |
| `id_usuario` | INT | No | FK | — | Usuario que pidió el código → `usuario.id` |
| `codigo_hash` | VARCHAR(255) | No | — | — | Hash del código con `password_hash()`; se compara con `password_verify()` |
| `intentos` | TINYINT | No | — | 0 | Intentos fallidos (máximo 3) |
| `usado` | TINYINT(1) | No | — | 0 | 1 = ya se usó para cambiar la contraseña |
| `fecha_creacion` | DATETIME | No | — | CURRENT_TIMESTAMP | Cuándo se generó |
| `fecha_expiracion` | DATETIME | No | — | — | `fecha_creacion` + 30 minutos |

## 12. `token_sesion`
Token que la app envía en cada petición para identificar al usuario.

| Campo | Tipo | Nulo | Llave | Predeterminado | Descripción |
|---|---|---|---|---|---|
| `id` | INT | No | PK, AI | — | Identificador del token |
| `id_usuario` | INT | No | FK | — | Usuario dueño de la sesión → `usuario.id` |
| `token` | CHAR(64) | No | UQ | — | Token aleatorio: `bin2hex(random_bytes(32))` en PHP |
| `activo` | TINYINT(1) | No | — | 1 | 1 = sesión activa, 0 = sesión cerrada |
| `fecha_creacion` | DATETIME | No | — | CURRENT_TIMESTAMP | Cuándo se inició la sesión |
| `fecha_expiracion` | DATETIME | Sí | — | NULL | Cuándo vence: la fecha de inicio de sesión más 30 minutos. Cada petición válida la renueva a la hora actual más 30 minutos. Un token con `fecha_expiracion` vencida se rechaza con 401. Aunque la columna admite NULL, la API siempre le pone un valor |
