-- =====================================================================
--  MediAgenda (app móvil) — Script de la base de datos
--  Punto 2.1 de la bitácora · Equipo 6
--
--  Motor: InnoDB · Juego de caracteres: utf8mb4_general_ci
--  Compatible con MySQL 8.0.16+ y MariaDB 10.4+ (Hostinger)
--
--  Cómo importarlo en Hostinger:
--    1. hPanel → Bases de datos → Bases de datos MySQL: crear la base y su usuario.
--    2. Abrir phpMyAdmin, seleccionar la base (u906011863_MediAgenda) a la izquierda.
--    3. Pestaña "Importar" → elegir este archivo → "Importar".
--  El script NO crea la base de datos porque Hostinger la crea desde hPanel.
--  Si la base ya está importada y tiene datos, usa en su lugar
--  database/migracion_v9_modulo_medico.sql.
--
--  Contraseñas de prueba (guardadas con password_hash de PHP / bcrypt):
--    Médicos  → Medico123
--    Paciente → Paciente123
--
--  17/11/2026: las especialidades se alinean con la guía de estilos y Figma
--  (Medicina interna, Pediatría, Cirugía y Traumatología).
--  19/11/2026 (Requisitos v9): el médico ya no cambia el estado de las citas.
--  La cita tiene 4 estados (Programada, Reprogramada, Atendida y Cancelada);
--  «No asistió» se elimina y la API pasa a «Atendida» las citas activas
--  cuya hora de fin ya pasó (RF-27).
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Se borran las tablas si ya existen, para poder volver a importar el script.
DROP TABLE IF EXISTS token_sesion;
DROP TABLE IF EXISTS codigo_recuperacion;
DROP TABLE IF EXISTS bitacora;
DROP TABLE IF EXISTS cambio_cita;
DROP TABLE IF EXISTS cita;
DROP TABLE IF EXISTS horario_medico;
DROP TABLE IF EXISTS medico;
DROP TABLE IF EXISTS historial_medico;
DROP TABLE IF EXISTS paciente;
DROP TABLE IF EXISTS consultorio;
DROP TABLE IF EXISTS especialidad;
DROP TABLE IF EXISTS usuario;

SET FOREIGN_KEY_CHECKS = 1;


-- =====================================================================
--  1. USUARIOS
-- =====================================================================

-- Cuenta para iniciar sesión. Es común a pacientes y médicos (RF-02, RF-03).
CREATE TABLE usuario (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    usuario         VARCHAR(50)  NOT NULL,
    correo          VARCHAR(100) NOT NULL,
    contrasena      VARCHAR(255) NOT NULL COMMENT 'Hash de password_hash(), nunca texto plano (RNF-01)',
    rol             ENUM('paciente', 'medico') NOT NULL,
    activo          TINYINT(1)   NOT NULL DEFAULT 1,
    fecha_registro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_usuario UNIQUE (usuario),
    CONSTRAINT uq_usuario_correo  UNIQUE (correo)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- Datos personales y de contacto del paciente (RF-01 pasos 1 y 2).
CREATE TABLE paciente (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT          NOT NULL,
    nombres           VARCHAR(60)  NOT NULL,
    apellidos         VARCHAR(80)  NOT NULL,
    fecha_nacimiento  DATE         NOT NULL,
    genero            VARCHAR(20)  NOT NULL,
    telefono          CHAR(10)     NOT NULL,
    codigo_postal     CHAR(5)      NOT NULL,
    ciudad            VARCHAR(60)  NOT NULL,
    estado            VARCHAR(60)  NOT NULL,
    direccion         VARCHAR(150) NOT NULL,
    CONSTRAINT uq_paciente_usuario UNIQUE (id_usuario),
    CONSTRAINT ck_paciente_telefono CHECK (telefono REGEXP '^[0-9]{10}$'),
    CONSTRAINT ck_paciente_cp       CHECK (codigo_postal REGEXP '^[0-9]{5}$'),
    CONSTRAINT fk_paciente_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- Historial médico capturado en el registro (RF-01 paso 3).
-- Solo lo lee el médico (RF-17, RNF-24). Si un dato no aplica se guarda "Ninguna".
CREATE TABLE historial_medico (
    id                       INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente              INT          NOT NULL,
    tipo_sangre              VARCHAR(15)  NOT NULL,
    peso                     DECIMAL(5,2) NOT NULL COMMENT 'Kilogramos',
    estatura                 DECIMAL(3,2) NOT NULL COMMENT 'Metros',
    alergias                 VARCHAR(255) NOT NULL,
    enfermedades_cronicas    VARCHAR(255) NOT NULL,
    medicamentos_actuales    VARCHAR(255) NOT NULL,
    cirugias_previas         VARCHAR(255) NOT NULL,
    antecedentes_familiares  VARCHAR(255) NOT NULL,
    tabaquismo               VARCHAR(100) NOT NULL,
    consumo_alcohol          VARCHAR(100) NOT NULL,
    CONSTRAINT uq_historial_paciente UNIQUE (id_paciente),
    CONSTRAINT fk_historial_paciente FOREIGN KEY (id_paciente)
        REFERENCES paciente (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- =====================================================================
--  2. CATÁLOGOS (la app solo los lee, RNF-22)
-- =====================================================================

CREATE TABLE especialidad (
    id      INT AUTO_INCREMENT PRIMARY KEY,
    nombre  VARCHAR(80) NOT NULL,
    CONSTRAINT uq_especialidad_nombre UNIQUE (nombre)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


CREATE TABLE consultorio (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nombre     VARCHAR(50)  NOT NULL,
    ubicacion  VARCHAR(150) NOT NULL,
    CONSTRAINT uq_consultorio_nombre UNIQUE (nombre)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


CREATE TABLE medico (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario          INT         NOT NULL,
    nombres             VARCHAR(60) NOT NULL,
    apellidos           VARCHAR(80) NOT NULL,
    telefono            CHAR(10)    NOT NULL,
    cedula_profesional  VARCHAR(20) NOT NULL,
    id_especialidad     INT         NOT NULL,
    id_consultorio      INT         NOT NULL,
    CONSTRAINT uq_medico_usuario UNIQUE (id_usuario),
    CONSTRAINT uq_medico_cedula  UNIQUE (cedula_profesional),
    CONSTRAINT fk_medico_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_medico_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidad (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_medico_consultorio FOREIGN KEY (id_consultorio)
        REFERENCES consultorio (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- Horario de atención por día. dia_semana: 1 = lunes … 7 = domingo.
-- La app lo usa para calcular los horarios disponibles al agendar (RF-07);
-- el médico ya no lo consulta desde la app (v9).
CREATE TABLE horario_medico (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    id_medico    INT     NOT NULL,
    dia_semana   TINYINT NOT NULL,
    hora_inicio  TIME    NOT NULL,
    hora_fin     TIME    NOT NULL,
    CONSTRAINT uq_horario UNIQUE (id_medico, dia_semana, hora_inicio),
    CONSTRAINT ck_horario_dia   CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_horario_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT fk_horario_medico FOREIGN KEY (id_medico)
        REFERENCES medico (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- =====================================================================
--  3. CITAS
-- =====================================================================

-- Cada cita ocupa un bloque de 30 minutos (hora termina en :00 o :30).
-- Estados (v9): Programada, Reprogramada, Atendida y Cancelada.
--   · Atendida la asigna la API automáticamente cuando termina la cita
--     (fecha + hora + 30 min <= hora del servidor); nadie la marca a mano (RF-27).
-- bloque_activo vale 1 si la cita está Programada o Reprogramada, y NULL en
-- los demás estados. Como un UNIQUE permite varios NULL, las restricciones
-- uq_cita_medico_bloque y uq_cita_paciente_bloque solo impiden dos citas
-- ACTIVAS en el mismo bloque; las canceladas no estorban (RF-24, RNF-09).
CREATE TABLE cita (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente     INT  NOT NULL,
    id_medico       INT  NOT NULL,
    id_consultorio  INT  NOT NULL COMMENT 'Consultorio donde se dio la cita',
    fecha           DATE NOT NULL,
    hora            TIME NOT NULL,
    estado          ENUM('Programada', 'Reprogramada', 'Atendida', 'Cancelada')
                    NOT NULL DEFAULT 'Programada'
                    COMMENT 'Atendida la asigna la API al terminar la cita (RF-27)',
    fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bloque_activo   TINYINT AS (IF(estado IN ('Programada', 'Reprogramada'), 1, NULL)) STORED,
    CONSTRAINT uq_cita_medico_bloque   UNIQUE (id_medico, fecha, hora, bloque_activo),
    CONSTRAINT uq_cita_paciente_bloque UNIQUE (id_paciente, fecha, hora, bloque_activo),
    CONSTRAINT ck_cita_hora CHECK (MINUTE(hora) IN (0, 30) AND SECOND(hora) = 0),
    CONSTRAINT fk_cita_paciente FOREIGN KEY (id_paciente)
        REFERENCES paciente (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cita_medico FOREIGN KEY (id_medico)
        REFERENCES medico (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cita_consultorio FOREIGN KEY (id_consultorio)
        REFERENCES consultorio (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX ix_cita_fecha (fecha),
    INDEX ix_cita_estado (estado)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- Historial de cambios: cada cancelación y reprogramación (RF-25).
-- En una cancelación, fecha_nueva y hora_nueva quedan en NULL.
CREATE TABLE cambio_cita (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    id_cita        INT  NOT NULL,
    tipo           ENUM('cancelacion', 'reprogramacion') NOT NULL,
    fecha_anterior DATE NOT NULL,
    hora_anterior  TIME NOT NULL,
    fecha_nueva    DATE NULL,
    hora_nueva     TIME NULL,
    motivo         VARCHAR(255) NULL,
    id_usuario     INT  NOT NULL COMMENT 'Quién hizo el cambio',
    fecha_cambio   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cambio_cita FOREIGN KEY (id_cita)
        REFERENCES cita (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cambio_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX ix_cambio_fecha (fecha_cambio)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- =====================================================================
--  4. SEGURIDAD Y AUDITORÍA
-- =====================================================================

-- Bitácora de operaciones (RF-26). La API solo inserta; nunca modifica ni borra (RNF-20).
CREATE TABLE bitacora (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario   INT          NOT NULL,
    operacion    VARCHAR(50)  NOT NULL COMMENT 'p. ej. INICIO_SESION, AGENDAR_CITA',
    descripcion  VARCHAR(255) NULL,
    fecha_hora   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bitacora_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX ix_bitacora_fecha (fecha_hora)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- Códigos de recuperación de contraseña (RF-05, RNF-21).
-- El código de 6 dígitos se guarda con password_hash() y se compara con password_verify().
-- Es válido si: usado = 0, intentos < 3 y fecha_expiracion > NOW().
CREATE TABLE codigo_recuperacion (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT          NOT NULL,
    codigo_hash       VARCHAR(255) NOT NULL,
    intentos          TINYINT      NOT NULL DEFAULT 0,
    usado             TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_creacion    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion  DATETIME     NOT NULL COMMENT 'fecha_creacion + 30 minutos',
    CONSTRAINT fk_codigo_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- Tokens de sesión que la app envía en cada petición (RNF-03, RNF-04).
-- token = bin2hex(random_bytes(32)) en PHP → 64 caracteres.
-- fecha_expiracion = última petición + 30 minutos; la API la renueva en cada
-- petición válida (P-12). Admite NULL, pero la API siempre le pone un valor.
CREATE TABLE token_sesion (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT        NOT NULL,
    token             CHAR(64)   NOT NULL,
    activo            TINYINT(1) NOT NULL DEFAULT 1,
    fecha_creacion    DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion  DATETIME   NULL,
    CONSTRAINT uq_token UNIQUE (token),
    CONSTRAINT fk_token_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;


-- =====================================================================
--  5. DATOS DE PRUEBA
-- =====================================================================

-- Las mismas especialidades de la guía de estilos y de Figma (fichas de P7).
INSERT INTO especialidad (id, nombre) VALUES
    (1, 'Medicina interna'),
    (2, 'Pediatría'),
    (3, 'Cirugía'),
    (4, 'Traumatología');

INSERT INTO consultorio (id, nombre, ubicacion) VALUES
    (1, 'Consultorio 101', 'Planta baja, pasillo A'),
    (2, 'Consultorio 102', 'Planta baja, pasillo A'),
    (3, 'Consultorio 201', 'Primer piso, pasillo B'),
    (4, 'Consultorio 202', 'Primer piso, pasillo B'),
    (5, 'Consultorio 301', 'Segundo piso, pasillo C');

-- Usuarios: 5 médicos (contraseña Medico123) y 1 paciente (contraseña Paciente123).
INSERT INTO usuario (id, usuario, correo, contrasena, rol) VALUES
    (1, 'dr.hernandez', 'carlos.hernandez@mediagenda.com', '$2y$10$ChPoyM/iLheOWYwiuQp5eeJ2Ul3WXofrs67qibjoIWzUfZZwwyJue', 'medico'),
    (2, 'dra.lopez',    'ana.lopez@mediagenda.com',        '$2y$10$ChPoyM/iLheOWYwiuQp5eeJ2Ul3WXofrs67qibjoIWzUfZZwwyJue', 'medico'),
    (3, 'dr.ramirez',   'jorge.ramirez@mediagenda.com',    '$2y$10$ChPoyM/iLheOWYwiuQp5eeJ2Ul3WXofrs67qibjoIWzUfZZwwyJue', 'medico'),
    (4, 'dra.torres',   'sofia.torres@mediagenda.com',     '$2y$10$ChPoyM/iLheOWYwiuQp5eeJ2Ul3WXofrs67qibjoIWzUfZZwwyJue', 'medico'),
    (5, 'dra.mendoza',  'laura.mendoza@mediagenda.com',    '$2y$10$ChPoyM/iLheOWYwiuQp5eeJ2Ul3WXofrs67qibjoIWzUfZZwwyJue', 'medico'),
    (6, 'juan.perez',   'juan.perez@correo.com',           '$2y$10$9scwfQJoWzF7Ak.UqjSvFeOO8yqUPaepkR.uOF.vf5Orkp66jensO', 'paciente');

-- Medicina interna tiene 2 médicos (Hernández y Mendoza); las demás, 1.
INSERT INTO medico (id, id_usuario, nombres, apellidos, telefono, cedula_profesional, id_especialidad, id_consultorio) VALUES
    (1, 1, 'Carlos', 'Hernández Ruiz',  '5511111111', '12345601', 1, 1),
    (2, 2, 'Ana',    'López García',    '5522222222', '12345602', 2, 2),
    (3, 3, 'Jorge',  'Ramírez Soto',    '5533333333', '12345603', 3, 3),
    (4, 4, 'Sofía',  'Torres Vega',     '5544444444', '12345604', 4, 4),
    (5, 5, 'Laura',  'Mendoza Castro',  '5555555555', '12345605', 1, 5);

-- Horarios: lunes a viernes. Unos por la mañana y otros por la tarde.
INSERT INTO horario_medico (id_medico, dia_semana, hora_inicio, hora_fin) VALUES
    (1, 1, '08:00:00', '14:00:00'), (1, 2, '08:00:00', '14:00:00'), (1, 3, '08:00:00', '14:00:00'),
    (1, 4, '08:00:00', '14:00:00'), (1, 5, '08:00:00', '14:00:00'),
    (2, 1, '09:00:00', '13:00:00'), (2, 3, '09:00:00', '13:00:00'), (2, 5, '09:00:00', '13:00:00'),
    (3, 1, '14:00:00', '19:00:00'), (3, 2, '14:00:00', '19:00:00'), (3, 3, '14:00:00', '19:00:00'),
    (3, 4, '14:00:00', '19:00:00'), (3, 5, '14:00:00', '19:00:00'),
    (4, 2, '10:00:00', '15:00:00'), (4, 4, '10:00:00', '15:00:00'),
    (5, 1, '15:00:00', '20:00:00'), (5, 3, '15:00:00', '20:00:00'), (5, 5, '15:00:00', '20:00:00');

INSERT INTO paciente (id, id_usuario, nombres, apellidos, fecha_nacimiento, genero, telefono, codigo_postal, ciudad, estado, direccion) VALUES
    (1, 6, 'Juan', 'Pérez Martínez', '1998-05-14', 'Masculino', '5566778899', '06700',
     'Ciudad de México', 'Ciudad de México', 'Av. Insurgentes Sur 123, Col. Roma Norte');

INSERT INTO historial_medico (id_paciente, tipo_sangre, peso, estatura, alergias, enfermedades_cronicas,
                              medicamentos_actuales, cirugias_previas, antecedentes_familiares, tabaquismo, consumo_alcohol) VALUES
    (1, 'O+', 72.50, 1.75, 'Penicilina', 'Ninguna', 'Ninguna', 'Apendicectomía (2015)',
     'Diabetes tipo 2 (padre)', 'Ninguna', 'Ocasional');
