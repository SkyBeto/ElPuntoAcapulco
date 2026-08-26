-- ============================================================
--  EL PUNTO ACAPULCO · Base de Datos
--  Propietario: Peter Saloz
--  Compatible: MariaDB 10.4 / MySQL 8.0
-- ============================================================

CREATE DATABASE IF NOT EXISTS elpunto_gym
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE elpunto_gym;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
--  roles
-- ============================================================
CREATE TABLE IF NOT EXISTS roles (
  id         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre     VARCHAR(30)  NOT NULL,
  etiqueta   VARCHAR(50)  NOT NULL,
  color_hex  VARCHAR(10)  NOT NULL DEFAULT '#888888',
  permisos   LONGTEXT     NOT NULL COMMENT 'JSON array de permisos',
  activo     TINYINT(1)   NOT NULL DEFAULT 1,
  creado_en  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO roles (nombre, etiqueta, color_hex, permisos) VALUES
('OWNER',         'Propietario',   '#f87171', '["todo"]'),
('Dueño',         'Dueño',         '#f87171', '["todo"]'),
('Coach',         'Entrenador',    '#4ade80', '["clientes","asistencia","rutinas","progreso","reportes"]'),
('Administrador', 'Administrador', '#facc15', '["clientes","asistencia","pagos","membresias","reportes"]'),
('Recepcionista', 'Recepcionista', '#60a5fa', '["asistencia","clientes"]');

-- ============================================================
--  usuarios  (personal del gimnasio)
-- ============================================================
CREATE TABLE IF NOT EXISTS usuarios (
  id             SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(100) NOT NULL,
  usuario        VARCHAR(60)  NOT NULL,
  correo         VARCHAR(150) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,
  rol_id         TINYINT UNSIGNED NOT NULL DEFAULT 5,
  activo         TINYINT(1)   NOT NULL DEFAULT 1,
  ultimo_acceso  DATETIME     NULL,
  creado_en      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuario (usuario),
  UNIQUE KEY uq_correo  (correo),
  FOREIGN KEY (rol_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hashes placeholder — se actualizan con: php generate_hashes.php
INSERT INTO usuarios (nombre, usuario, correo, password_hash, rol_id) VALUES
('Peter Saloz',    'peter.saloz',     'peter.saloz@elpunto.mx',    '$2y$12$placeholder', 1),
('Edson Luna',     'edson.luna',      'edson.luna@elpunto.mx',     '$2y$12$placeholder', 3),
('Viriada Santos', 'viriada.santos',  'viriada.santos@elpunto.mx', '$2y$12$placeholder', 3),
('Mario García',   'mario.garcia',    'mario@elpunto.mx',          '$2y$12$placeholder', 4),
('Dana Martínez',  'dana.martinez',   'dana@elpunto.mx',           '$2y$12$placeholder', 5);

-- ============================================================
--  membresias
-- ============================================================
CREATE TABLE IF NOT EXISTS membresias (
  id          SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(80)  NOT NULL,
  dias        SMALLINT     NOT NULL,
  precio      DECIMAL(8,2) NOT NULL,
  color_hex   VARCHAR(10)  NOT NULL DEFAULT '#888888',
  descripcion VARCHAR(255) NOT NULL DEFAULT '',
  activo      TINYINT(1)   NOT NULL DEFAULT 1,
  creado_en   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO membresias (nombre, dias, precio, color_hex, descripcion) VALUES
('Visita libre',       1,    50.00, '#60a5fa', '1 dia acceso libre'),
('Visita con Coach',   1,    80.00, '#a78bfa', '1 dia con coach certificado'),
('Semanal',            7,   250.00, '#facc15', '7 dias ilimitados'),
('Mensual Individual', 30,  700.00, '#d8d8d8', 'Un mes acceso ilimitado'),
('Mensual Pareja',     30, 1100.00, '#b8b8b8', '2 personas por un mes'),
('Anualidad',         365, 7000.00, '#f0f0f0', '12 meses + beneficios');

-- ============================================================
--  clientes
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes (
  id               INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  codigo           VARCHAR(10)     NOT NULL,
  nombre           VARCHAR(100)    NOT NULL,
  apellido         VARCHAR(100)    NOT NULL DEFAULT '',
  fecha_nac        DATE            NOT NULL,
  telefono         VARCHAR(20)     NOT NULL DEFAULT '',
  correo           VARCHAR(150)    NOT NULL,
  password_hash    VARCHAR(255)    NOT NULL,
  genero           VARCHAR(15)     NOT NULL DEFAULT 'Masculino',
  membresia_id     SMALLINT UNSIGNED NULL,
  membresia_inicio DATE            NULL,
  membresia_vence  DATE            NULL,
  notas            TEXT            NULL,
  activo           TINYINT(1)      NOT NULL DEFAULT 1,
  creado_en        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_codigo  (codigo),
  UNIQUE KEY uq_correo  (correo),
  FOREIGN KEY (membresia_id) REFERENCES membresias(id) ON DELETE SET NULL,
  INDEX idx_vence (membresia_vence)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO clientes (codigo, nombre, apellido, fecha_nac, telefono, correo, password_hash, genero, membresia_id, membresia_inicio, membresia_vence) VALUES
('001','Carlos',    'Mendoza',  '1990-03-15','7440001111','carlos@mail.com', '$2y$12$placeholder','Masculino',4, DATE_SUB(CURDATE(),INTERVAL 20 DAY), DATE_ADD(CURDATE(),INTERVAL 10  DAY)),
('002','Sofia',     'Ramirez',  '2000-07-22','7440002222','sofia@mail.com',  '$2y$12$placeholder','Femenino', 4, DATE_SUB(CURDATE(),INTERVAL 28 DAY), DATE_ADD(CURDATE(),INTERVAL 2   DAY)),
('003','Luis',      'Torres',   '1985-11-05','7440003333','luis@mail.com',   '$2y$12$placeholder','Masculino',3, DATE_SUB(CURDATE(),INTERVAL 14 DAY), DATE_ADD(CURDATE(),INTERVAL 1   DAY)),
('004','Andrea',    'Castro',   '2006-01-18','7440004444','andrea@mail.com', '$2y$12$placeholder','Femenino', 3, DATE_SUB(CURDATE(),INTERVAL 5  DAY), DATE_ADD(CURDATE(),INTERVAL 2   DAY)),
('005','Roberto',   'Silva',    '1978-09-30','7440005555','roberto@mail.com','$2y$12$placeholder','Masculino',6, DATE_SUB(CURDATE(),INTERVAL 60 DAY), DATE_ADD(CURDATE(),INTERVAL 305 DAY)),
('006','Valentina', 'Morales',  '1995-05-12','7440006666','val@mail.com',    '$2y$12$placeholder','Femenino', 4, DATE_SUB(CURDATE(),INTERVAL 3  DAY), DATE_ADD(CURDATE(),INTERVAL 27  DAY)),
('007','Diego',     'Hernandez','2004-12-01','7440007777','diego@mail.com',  '$2y$12$placeholder','Masculino',3, DATE_SUB(CURDATE(),INTERVAL 2  DAY), DATE_ADD(CURDATE(),INTERVAL 5   DAY)),
('008','Patricia',  'Vega',     '1968-04-25','7440008888','patri@mail.com',  '$2y$12$placeholder','Femenino', 4, DATE_SUB(CURDATE(),INTERVAL 1  DAY), DATE_ADD(CURDATE(),INTERVAL 29  DAY)),
('009','Miguel',    'Ruiz',     '1992-08-14','7440009999','miguel@mail.com', '$2y$12$placeholder','Masculino',1, CURDATE(),                           CURDATE()),
('010','Fernanda',  'Diaz',     '1997-02-28','7440010000','fer@mail.com',    '$2y$12$placeholder','Femenino', 6, DATE_SUB(CURDATE(),INTERVAL 100 DAY),DATE_ADD(CURDATE(),INTERVAL 265 DAY));

-- ============================================================
--  pagos
-- ============================================================
CREATE TABLE IF NOT EXISTS pagos (
  id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  folio         VARCHAR(15)     NOT NULL,
  cliente_id    INT UNSIGNED    NOT NULL,
  membresia_id  SMALLINT UNSIGNED NOT NULL,
  monto         DECIMAL(10,2)   NOT NULL,
  fecha_pago    DATE            NOT NULL,
  fecha_vence   DATE            NOT NULL,
  metodo        VARCHAR(20)     NOT NULL DEFAULT 'Efectivo',
  estatus       VARCHAR(15)     NOT NULL DEFAULT 'Completado',
  usuario_cobro SMALLINT UNSIGNED NULL,
  notas         VARCHAR(255)    NULL,
  creado_en     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_folio (folio),
  FOREIGN KEY (cliente_id)    REFERENCES clientes(id),
  FOREIGN KEY (membresia_id)  REFERENCES membresias(id),
  FOREIGN KEY (usuario_cobro) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_fecha    (fecha_pago),
  INDEX idx_cliente  (cliente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO pagos (folio, cliente_id, membresia_id, monto, fecha_pago, fecha_vence, metodo, estatus, usuario_cobro) VALUES
('P001', 1,  4,  700.00, DATE_SUB(CURDATE(),INTERVAL 20  DAY), DATE_ADD(CURDATE(),INTERVAL 10  DAY), 'Efectivo',      'Completado', 1),
('P002', 2,  4,  700.00, DATE_SUB(CURDATE(),INTERVAL 28  DAY), DATE_ADD(CURDATE(),INTERVAL 2   DAY), 'Tarjeta',       'Completado', 1),
('P003', 3,  3,  250.00, DATE_SUB(CURDATE(),INTERVAL 14  DAY), DATE_ADD(CURDATE(),INTERVAL 1   DAY), 'Efectivo',      'Completado', 4),
('P004', 4,  3,  250.00, DATE_SUB(CURDATE(),INTERVAL 5   DAY), DATE_ADD(CURDATE(),INTERVAL 2   DAY), 'Transferencia', 'Completado', 4),
('P005', 5,  6, 7000.00, DATE_SUB(CURDATE(),INTERVAL 60  DAY), DATE_ADD(CURDATE(),INTERVAL 305 DAY), 'Tarjeta',       'Completado', 1),
('P006', 6,  4,  700.00, DATE_SUB(CURDATE(),INTERVAL 3   DAY), DATE_ADD(CURDATE(),INTERVAL 27  DAY), 'Efectivo',      'Completado', 4),
('P007', 7,  3,  250.00, DATE_SUB(CURDATE(),INTERVAL 2   DAY), DATE_ADD(CURDATE(),INTERVAL 5   DAY), 'Efectivo',      'Completado', 5),
('P008', 10, 6, 7000.00, DATE_SUB(CURDATE(),INTERVAL 100 DAY), DATE_ADD(CURDATE(),INTERVAL 265 DAY), 'Transferencia', 'Completado', 1);

-- ============================================================
--  asistencias
-- ============================================================
CREATE TABLE IF NOT EXISTS asistencias (
  id             INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  cliente_id     INT UNSIGNED    NOT NULL,
  fecha          DATE            NOT NULL,
  hora           TIME            NOT NULL,
  turno          VARCHAR(10)     NOT NULL DEFAULT 'Manana',
  registrado_por SMALLINT UNSIGNED NULL,
  creado_en      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cliente_id)     REFERENCES clientes(id),
  FOREIGN KEY (registrado_por) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_fecha   (fecha),
  INDEX idx_cliente (cliente_id),
  UNIQUE KEY uq_asist (cliente_id, fecha, turno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO asistencias (cliente_id, fecha, hora, turno) VALUES
(1,  DATE_SUB(CURDATE(),INTERVAL 2 DAY), '07:15:00', 'Manana'),
(5,  DATE_SUB(CURDATE(),INTERVAL 2 DAY), '08:30:00', 'Manana'),
(1,  DATE_SUB(CURDATE(),INTERVAL 1 DAY), '06:00:00', 'Manana'),
(2,  DATE_SUB(CURDATE(),INTERVAL 1 DAY), '07:20:00', 'Manana'),
(6,  DATE_SUB(CURDATE(),INTERVAL 1 DAY), '08:00:00', 'Manana'),
(5,  CURDATE(), '06:45:00', 'Manana'),
(10, CURDATE(), '07:00:00', 'Manana'),
(8,  CURDATE(), '08:15:00', 'Manana');

-- ============================================================
--  horarios
-- ============================================================
CREATE TABLE IF NOT EXISTS horarios (
  id         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  clave      VARCHAR(10)  NOT NULL,
  etiqueta   VARCHAR(30)  NOT NULL,
  dias       VARCHAR(50)  NOT NULL,
  hora_texto VARCHAR(30)  NOT NULL,
  icono      VARCHAR(30)  NOT NULL DEFAULT 'fa-clock',
  activo     TINYINT(1)   NOT NULL DEFAULT 1,
  orden      TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_clave (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO horarios (clave, etiqueta, dias, hora_texto, icono, activo, orden) VALUES
('man', 'Manana',  'Lun - Vie', '7:00 - 9:00 am',  'fa-sun',       1, 1),
('tar', 'Tarde',   'Lun - Vie', '6:00 - 9:00 pm',  'fa-cloud-sun', 1, 2),
('sab', 'Sabado',  'Sabado',    'Cerrado',          'fa-moon',      0, 3),
('dom', 'Domingo', 'Domingo',   'Cerrado',          'fa-moon',      0, 4);

-- ============================================================
--  confirmaciones_horario
-- ============================================================
CREATE TABLE IF NOT EXISTS confirmaciones_horario (
  id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  cliente_id    INT UNSIGNED    NOT NULL,
  horario_id    TINYINT UNSIGNED NOT NULL,
  fecha         DATE            NOT NULL,
  confirmado_en DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (horario_id) REFERENCES horarios(id),
  UNIQUE KEY uq_conf (cliente_id, horario_id, fecha),
  INDEX idx_fecha (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  rutinas
-- ============================================================
CREATE TABLE IF NOT EXISTS rutinas (
  id           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(120)    NOT NULL,
  descripcion  TEXT            NULL,
  nivel        VARCHAR(20)     NOT NULL DEFAULT 'Principiante',
  objetivo     VARCHAR(80)     NULL,
  duracion_min SMALLINT        NOT NULL DEFAULT 60,
  coach_id     SMALLINT UNSIGNED NULL,
  activa       TINYINT(1)      NOT NULL DEFAULT 1,
  creado_en    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (coach_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO rutinas (nombre, descripcion, nivel, objetivo, duracion_min, coach_id) VALUES
('Full Body Principiante',  'Rutina completa para comenzar en el gym',      'Principiante', 'Acondicionamiento', 60, 2),
('Hipertrofia Upper/Lower', 'Division superior e inferior para ganar masa',  'Intermedio',   'Hipertrofia',       75, 2),
('Cardio HIIT 30',          '30 minutos de intervalos de alta intensidad',   'Intermedio',   'Perdida de peso',   30, 3),
('Fuerza Powerlifting',     'Sentadilla peso muerto y press banca pesados',  'Avanzado',     'Fuerza maxima',     90, 2);

-- ============================================================
--  rutinas_ejercicios
-- ============================================================
CREATE TABLE IF NOT EXISTS rutinas_ejercicios (
  id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  rutina_id     INT UNSIGNED    NOT NULL,
  nombre        VARCHAR(100)    NOT NULL,
  series        TINYINT         NOT NULL DEFAULT 3,
  repeticiones  VARCHAR(20)     NOT NULL DEFAULT '10-12',
  descanso_seg  SMALLINT        NOT NULL DEFAULT 60,
  musculos      VARCHAR(150)    NULL,
  orden         TINYINT         NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  FOREIGN KEY (rutina_id) REFERENCES rutinas(id) ON DELETE CASCADE,
  INDEX idx_rutina (rutina_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO rutinas_ejercicios (rutina_id, nombre, series, repeticiones, descanso_seg, musculos, orden) VALUES
(1,'Sentadilla libre',       3,'12',   90,'Cuadriceps glúteos',1),
(1,'Press de pecho maquina', 3,'12',   60,'Pectoral triceps',  2),
(1,'Jalón al pecho',         3,'12',   60,'Espalda biceps',    3),
(1,'Caminadora',             1,'20min',60,'Cardio',            4),
(2,'Sentadilla barra',       4,'8-10', 120,'Cuadriceps glúteos',1),
(2,'Press banca',            4,'8-10', 120,'Pectoral triceps',  2),
(2,'Peso muerto rumano',     3,'10',   90,'Isquios glúteos',   3),
(2,'Remo con barra',         3,'10',   90,'Espalda biceps',    4);

-- ============================================================
--  rutinas_clientes
-- ============================================================
CREATE TABLE IF NOT EXISTS rutinas_clientes (
  id           INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  cliente_id   INT UNSIGNED    NOT NULL,
  rutina_id    INT UNSIGNED    NOT NULL,
  asignado_por SMALLINT UNSIGNED NULL,
  fecha_inicio DATE            NOT NULL,
  activa       TINYINT(1)      NOT NULL DEFAULT 1,
  notas        VARCHAR(255)    NULL,
  creado_en    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cliente_id)   REFERENCES clientes(id),
  FOREIGN KEY (rutina_id)    REFERENCES rutinas(id),
  FOREIGN KEY (asignado_por) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_cliente (cliente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  fotos_progreso
-- ============================================================
CREATE TABLE IF NOT EXISTS fotos_progreso (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  cliente_id  INT UNSIGNED    NOT NULL,
  ruta_foto   VARCHAR(300)    NOT NULL,
  descripcion VARCHAR(255)    NULL,
  peso_kg     DECIMAL(5,2)    NULL,
  grasa_pct   DECIMAL(4,1)    NULL,
  subido_por  SMALLINT UNSIGNED NULL,
  creado_en   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (subido_por) REFERENCES usuarios(id) ON DELETE SET NULL,
  INDEX idx_cliente (cliente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  galeria
-- ============================================================
CREATE TABLE IF NOT EXISTS galeria (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  titulo      VARCHAR(120)    NOT NULL,
  subtitulo   VARCHAR(200)    NULL,
  ruta_foto   VARCHAR(300)    NOT NULL,
  orden       SMALLINT        NOT NULL DEFAULT 0,
  visible_web TINYINT(1)      NOT NULL DEFAULT 1,
  subido_por  SMALLINT UNSIGNED NULL,
  creado_en   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (subido_por) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO galeria (titulo, subtitulo, ruta_foto, orden, visible_web, subido_por) VALUES
('Area de entrenamiento','Equipos de alto rendimiento',   '21d4f2a9-b657-4cd3-b93f-6aa16684b770.jpg',1,1,1),
('Zona de pesas',        'Maquinas premium',              '2889aae1-8de4-4a92-8da6-ed5bf692935d.jpg',2,1,1),
('Espacio funcional',    'Cardio y funcional',            '61a35b95-2a85-4d27-a549-411ebe3be2ca.jpg',3,1,1),
('Instalaciones',        'Ambiente profesional',          '86d26908-6254-4e5c-a88b-28061bc930f2.jpg',4,1,1),
('Area de workout',      'Entrena sin limites',           '9182a0fd-4242-4428-961b-54fbbc1ebf97.jpg',5,1,1),
('Equipos modernos',     'Tecnologia fitness',            'a120c691-4e23-417a-b2d7-6d326d5bf076.jpg',6,1,1),
('El Punto',             'Tu espacio para transformarte', 'f08c27fe-29f6-45a0-a5a5-7d0dd77ce4aa.jpg',7,1,1),
('Comunidad activa',     'La familia mas activa',         'WhatsApp Image 2026-06-02 at 9.17.56 AM.jpeg',8,1,1);

-- ============================================================
--  actividad_log
-- ============================================================
CREATE TABLE IF NOT EXISTS actividad_log (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id  SMALLINT UNSIGNED NULL,
  cliente_id  INT UNSIGNED    NULL,
  accion      VARCHAR(80)     NOT NULL,
  entidad     VARCHAR(40)     NULL,
  entidad_id  INT UNSIGNED    NULL,
  detalle     LONGTEXT        NULL,
  ip          VARCHAR(45)     NULL,
  user_agent  VARCHAR(300)    NULL,
  creado_en   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
  INDEX idx_accion (accion),
  INDEX idx_fecha  (creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  configuracion
-- ============================================================
CREATE TABLE IF NOT EXISTS configuracion (
  clave       VARCHAR(60)  NOT NULL,
  valor       TEXT         NOT NULL,
  tipo        VARCHAR(10)  NOT NULL DEFAULT 'string',
  descripcion VARCHAR(200) NULL,
  PRIMARY KEY (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO configuracion (clave, valor, tipo, descripcion) VALUES
('gym_nombre',        'El Punto Acapulco',             'string',  'Nombre del gimnasio'),
('gym_propietario',   'Peter Saloz',                   'string',  'Nombre del propietario'),
('gym_correo',        'contacto@elpunto.mx',           'string',  'Correo de contacto'),
('gym_telefono',      '744-000-0000',                  'string',  'Telefono'),
('gym_direccion',     'Acapulco de Juarez, Guerrero',  'string',  'Direccion'),
('gym_instagram',     '@elpunto.acapulco',             'string',  'Instagram'),
('aforo_maximo',      '30',                            'integer', 'Max personas por turno'),
('dias_alerta_vence', '5',                             'integer', 'Dias anticipacion alerta'),
('version_db',        '3.0',                           'string',  'Version del esquema'),
('moneda',            'MXN',                           'string',  'Moneda'),
('zona_horaria',      'America/Mexico_City',           'string',  'Zona horaria');

-- ============================================================
--  VISTAS
-- ============================================================

CREATE OR REPLACE VIEW v_socios_activos AS
SELECT
  c.id,
  c.codigo,
  CONCAT(c.nombre,' ',c.apellido) AS nombre_completo,
  c.correo,
  c.telefono,
  c.genero,
  m.nombre  AS plan,
  m.precio  AS precio_plan,
  c.membresia_inicio AS inicio,
  c.membresia_vence  AS vence,
  DATEDIFF(c.membresia_vence, CURDATE()) AS dias_restantes,
  CASE
    WHEN DATEDIFF(c.membresia_vence, CURDATE()) < 0  THEN 'Vencido'
    WHEN DATEDIFF(c.membresia_vence, CURDATE()) <= 5 THEN 'Por vencer'
    ELSE 'Activo'
  END AS estatus
FROM clientes c
LEFT JOIN membresias m ON m.id = c.membresia_id
WHERE c.activo = 1;

CREATE OR REPLACE VIEW v_ingresos_mes AS
SELECT
  YEAR(fecha_pago)  AS anio,
  MONTH(fecha_pago) AS mes,
  COUNT(*)          AS total_pagos,
  SUM(monto)        AS total_ingresos,
  AVG(monto)        AS ticket_promedio
FROM pagos
WHERE estatus = 'Completado'
GROUP BY YEAR(fecha_pago), MONTH(fecha_pago)
ORDER BY anio DESC, mes DESC;

CREATE OR REPLACE VIEW v_asistencias_hoy AS
SELECT
  a.id,
  a.hora,
  a.turno,
  CONCAT(c.nombre,' ',c.apellido) AS cliente,
  c.codigo,
  m.nombre AS plan
FROM asistencias a
JOIN clientes  c ON c.id = a.cliente_id
LEFT JOIN membresias m ON m.id = c.membresia_id
WHERE a.fecha = CURDATE()
ORDER BY a.hora DESC;

-- ============================================================
--  STORED PROCEDURES
-- ============================================================

DROP PROCEDURE IF EXISTS sp_registrar_asistencia;
DROP PROCEDURE IF EXISTS sp_procesar_pago;

DELIMITER //

CREATE PROCEDURE sp_registrar_asistencia(
  IN  p_cliente_id INT,
  IN  p_turno      VARCHAR(10),
  IN  p_usuario_id SMALLINT,
  OUT p_resultado  VARCHAR(50)
)
BEGIN
  DECLARE v_vence DATE;
  SELECT membresia_vence INTO v_vence FROM clientes WHERE id = p_cliente_id;

  IF v_vence IS NULL OR v_vence < CURDATE() THEN
    SET p_resultado = 'ERROR_MEMBRESIA_VENCIDA';
  ELSEIF EXISTS(
    SELECT 1 FROM asistencias
    WHERE cliente_id = p_cliente_id AND fecha = CURDATE() AND turno = p_turno
  ) THEN
    SET p_resultado = 'YA_REGISTRADO';
  ELSE
    INSERT INTO asistencias (cliente_id, fecha, hora, turno, registrado_por)
    VALUES (p_cliente_id, CURDATE(), CURTIME(), p_turno, p_usuario_id);
    SET p_resultado = 'OK';
  END IF;
END//

CREATE PROCEDURE sp_procesar_pago(
  IN p_cliente_id   INT,
  IN p_membresia_id SMALLINT,
  IN p_monto        DECIMAL(10,2),
  IN p_metodo       VARCHAR(20),
  IN p_usuario_id   SMALLINT
)
BEGIN
  DECLARE v_dias   SMALLINT;
  DECLARE v_inicio DATE;
  DECLARE v_vence  DATE;
  DECLARE v_folio  VARCHAR(15);
  DECLARE v_pago_id INT;

  SELECT dias INTO v_dias FROM membresias WHERE id = p_membresia_id;
  SET v_inicio = CURDATE();
  SET v_vence  = DATE_ADD(v_inicio, INTERVAL v_dias DAY);
  SET v_folio  = CONCAT('P', LPAD((SELECT IFNULL(MAX(id),0)+1 FROM pagos), 4, '0'));

  INSERT INTO pagos (folio, cliente_id, membresia_id, monto, fecha_pago, fecha_vence, metodo, estatus, usuario_cobro)
  VALUES (v_folio, p_cliente_id, p_membresia_id, p_monto, v_inicio, v_vence, p_metodo, 'Completado', p_usuario_id);

  SET v_pago_id = LAST_INSERT_ID();

  UPDATE clientes
  SET membresia_id      = p_membresia_id,
      membresia_inicio  = v_inicio,
      membresia_vence   = v_vence
  WHERE id = p_cliente_id;

  INSERT INTO actividad_log (usuario_id, accion, entidad, entidad_id, detalle)
  VALUES (p_usuario_id, 'pago', 'pagos', v_pago_id,
          CONCAT('{"folio":"', v_folio, '","monto":', p_monto, ',"cliente_id":', p_cliente_id, '}'));

  SELECT v_folio AS folio, v_vence AS vence;
END//

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  FIN · elpunto_gym lista para usar
-- ============================================================
