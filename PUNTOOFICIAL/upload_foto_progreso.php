<?php
header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/db.php';

function responder($ok, $mensaje, $extra = []) {
    echo json_encode(array_merge([
        'ok' => $ok,
        'mensaje' => $mensaje
    ], $extra));
    exit;
}

function obtenerConexion() {
    global $pdo, $conn, $conexion, $mysqli, $db;

    if (isset($pdo) && $pdo instanceof PDO) {
        return ['tipo' => 'pdo', 'cn' => $pdo];
    }

    if (isset($conn) && $conn instanceof mysqli) {
        return ['tipo' => 'mysqli', 'cn' => $conn];
    }

    if (isset($conexion) && $conexion instanceof mysqli) {
        return ['tipo' => 'mysqli', 'cn' => $conexion];
    }

    if (isset($mysqli) && $mysqli instanceof mysqli) {
        return ['tipo' => 'mysqli', 'cn' => $mysqli];
    }

    if (isset($db) && $db instanceof mysqli) {
        return ['tipo' => 'mysqli', 'cn' => $db];
    }

    responder(false, 'No se encontró una conexión válida en db.php');
}

function obtenerColumnas($tabla) {
    $db = obtenerConexion();

    if ($db['tipo'] === 'pdo') {
        $stmt = $db['cn']->query("SHOW COLUMNS FROM `$tabla`");
        $cols = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $cols[] = $row['Field'];
        }
        return $cols;
    }

    $res = $db['cn']->query("SHOW COLUMNS FROM `$tabla`");

    if (!$res) {
        responder(false, 'No se pudieron leer las columnas de la tabla ' . $tabla);
    }

    $cols = [];

    while ($row = $res->fetch_assoc()) {
        $cols[] = $row['Field'];
    }

    return $cols;
}

function ejecutar($sql, $tipos, $params) {
    $db = obtenerConexion();

    if ($db['tipo'] === 'pdo') {
        $stmt = $db['cn']->prepare($sql);
        return $stmt->execute($params);
    }

    $stmt = $db['cn']->prepare($sql);

    if (!$stmt) {
        responder(false, 'Error preparando consulta: ' . $db['cn']->error);
    }

    if (!empty($params)) {
        $refs = [];
        $refs[] = $tipos;

        foreach ($params as $k => $v) {
            $refs[] = &$params[$k];
        }

        call_user_func_array([$stmt, 'bind_param'], $refs);
    }

    $ok = $stmt->execute();

    if (!$ok) {
        responder(false, 'Error ejecutando consulta: ' . $stmt->error);
    }

    return $ok;
}

$cliente_id = $_POST['cliente_id'] ?? $_POST['id_cliente'] ?? $_POST['id'] ?? null;

if (!$cliente_id) {
    responder(false, 'Falta el ID del cliente');
}

$archivo = null;

if (isset($_FILES['foto'])) {
    $archivo = $_FILES['foto'];
} elseif (isset($_FILES['foto_progreso'])) {
    $archivo = $_FILES['foto_progreso'];
} elseif (isset($_FILES['progreso'])) {
    $archivo = $_FILES['progreso'];
}

if (!$archivo) {
    responder(false, 'No se recibió ninguna foto de progreso');
}

if ($archivo['error'] !== UPLOAD_ERR_OK) {
    responder(false, 'Error al subir la imagen');
}

$maxSize = 5 * 1024 * 1024;

if ($archivo['size'] > $maxSize) {
    responder(false, 'La imagen es demasiado grande. Máximo 5 MB');
}

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $archivo['tmp_name']);
finfo_close($finfo);

$extensiones = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp'
];

if (!isset($extensiones[$mime])) {
    responder(false, 'Formato no permitido. Usa JPG, PNG o WEBP');
}

$carpeta = __DIR__ . '/uploads/progreso';

if (!is_dir($carpeta)) {
    mkdir($carpeta, 0777, true);
}

$extension = $extensiones[$mime];
$nombreArchivo = 'progreso_' . $cliente_id . '_' . time() . '_' . rand(1000, 9999) . '.' . $extension;
$rutaFisica = $carpeta . '/' . $nombreArchivo;
$rutaBD = 'uploads/progreso/' . $nombreArchivo;

if (!move_uploaded_file($archivo['tmp_name'], $rutaFisica)) {
    responder(false, 'No se pudo guardar la imagen en la carpeta uploads/progreso');
}

$columnas = obtenerColumnas('fotos_progreso');

$columnaCliente = null;

foreach (['cliente_id', 'id_cliente', 'cliente'] as $posible) {
    if (in_array($posible, $columnas)) {
        $columnaCliente = $posible;
        break;
    }
}

if (!$columnaCliente) {
    responder(false, 'No se encontró columna de cliente en fotos_progreso');
}

if (!in_array('ruta_foto', $columnas)) {
    responder(false, 'La tabla fotos_progreso no tiene la columna ruta_foto');
}

$campos = [];
$placeholders = [];
$params = [];
$tipos = '';

$campos[] = "`$columnaCliente`";
$placeholders[] = '?';
$params[] = $cliente_id;
$tipos .= 'i';

$campos[] = "`ruta_foto`";
$placeholders[] = '?';
$params[] = $rutaBD;
$tipos .= 's';

if (in_array('descripcion', $columnas)) {
    $descripcion = $_POST['descripcion'] ?? '';
    $campos[] = '`descripcion`';
    $placeholders[] = '?';
    $params[] = $descripcion;
    $tipos .= 's';
}

if (in_array('fecha', $columnas)) {
    $fecha = $_POST['fecha'] ?? date('Y-m-d');
    $campos[] = '`fecha`';
    $placeholders[] = '?';
    $params[] = $fecha;
    $tipos .= 's';
}

if (in_array('fecha_subida', $columnas)) {
    $fechaSubida = date('Y-m-d H:i:s');
    $campos[] = '`fecha_subida`';
    $placeholders[] = '?';
    $params[] = $fechaSubida;
    $tipos .= 's';
}

if (in_array('created_at', $columnas)) {
    $createdAt = date('Y-m-d H:i:s');
    $campos[] = '`created_at`';
    $placeholders[] = '?';
    $params[] = $createdAt;
    $tipos .= 's';
}

$sql = "INSERT INTO fotos_progreso (" . implode(', ', $campos) . ") VALUES (" . implode(', ', $placeholders) . ")";
ejecutar($sql, $tipos, $params);

responder(true, 'Foto de progreso subida correctamente', [
    'ruta' => $rutaBD
]);