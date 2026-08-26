<?php
/**
 * El Punto Acapulco — Conexión a Base de Datos
 * Propietario: Peter Saloz
 *
 * Uso:
 *   require_once 'db.php';
 *   $db = DB::getInstance();
 *   $socios = $db->fetchAll("SELECT * FROM v_socios_activos");
 */

declare(strict_types=1);

// ─── Cargar variables de entorno ──────────────────────────────
if (file_exists(__DIR__ . '/.env')) {
    $lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with(trim($line), '#') || !str_contains($line, '=')) {
            continue;
        }
        [$key, $value] = explode('=', $line, 2);
        $_ENV[trim($key)] = trim($value);
    }
}

function env(string $key, mixed $default = null): mixed
{
    return $_ENV[$key] ?? getenv($key) ?: $default;
}

// ─── Clase DB (Singleton PDO) ─────────────────────────────────
class DB
{
    private static ?DB $instance = null;
    private PDO $pdo;

    private function __construct()
    {
        $host    = env('DB_HOST',    '127.0.0.1');
        $port    = env('DB_PORT',    '3306');
        $name    = env('DB_NAME',    'elpunto_gym');
        $user    = env('DB_USER',    'root');
        $pass    = env('DB_PASS',    '');
        $charset = env('DB_CHARSET', 'utf8mb4');

        $dsn = "mysql:host={$host};port={$port};dbname={$name};charset={$charset}";

        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET time_zone='+00:00'",
        ];

        try {
            $this->pdo = new PDO($dsn, $user, $pass, $options);
        } catch (PDOException $e) {
            if (env('APP_DEBUG', 'false') === 'true') {
                throw new RuntimeException('DB Connection failed: ' . $e->getMessage());
            }
            throw new RuntimeException('No se pudo conectar a la base de datos.');
        }
    }

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function pdo(): PDO
    {
        return $this->pdo;
    }

    // ─── HELPERS DE CONSULTA ──────────────────────────────────

    /**
     * Ejecutar consulta y devolver todos los resultados.
     */
    public function fetchAll(string $sql, array $params = []): array
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    /**
     * Ejecutar consulta y devolver una sola fila.
     */
    public function fetchOne(string $sql, array $params = []): array|false
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetch();
    }

    /**
     * Ejecutar consulta y devolver un solo valor escalar.
     */
    public function fetchValue(string $sql, array $params = []): mixed
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchColumn();
    }

    /**
     * Ejecutar INSERT / UPDATE / DELETE.
     * Devuelve el número de filas afectadas.
     */
    public function execute(string $sql, array $params = []): int
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->rowCount();
    }

    /**
     * Insertar fila y devolver el ID generado.
     */
    public function insert(string $table, array $data): string
    {
        $cols = implode(', ', array_keys($data));
        $placeholders = implode(', ', array_fill(0, count($data), '?'));
        $sql = "INSERT INTO `{$table}` ({$cols}) VALUES ({$placeholders})";
        $this->execute($sql, array_values($data));
        return $this->pdo->lastInsertId();
    }

    /**
     * Actualizar filas con condición WHERE.
     * $where = ['id' => 5]  →  WHERE id = ?
     */
    public function update(string $table, array $data, array $where): int
    {
        $set   = implode(', ', array_map(fn($k) => "`{$k}` = ?", array_keys($data)));
        $cond  = implode(' AND ', array_map(fn($k) => "`{$k}` = ?", array_keys($where)));
        $sql   = "UPDATE `{$table}` SET {$set} WHERE {$cond}";
        return $this->execute($sql, [...array_values($data), ...array_values($where)]);
    }

    /**
     * Eliminar fila/s.
     */
    public function delete(string $table, array $where): int
    {
        $cond = implode(' AND ', array_map(fn($k) => "`{$k}` = ?", array_keys($where)));
        return $this->execute("DELETE FROM `{$table}` WHERE {$cond}", array_values($where));
    }

    // ─── TRANSACCIONES ────────────────────────────────────────

    public function beginTransaction(): void
    {
        $this->pdo->beginTransaction();
    }

    public function commit(): void
    {
        $this->pdo->commit();
    }

    public function rollback(): void
    {
        if ($this->pdo->inTransaction()) {
            $this->pdo->rollBack();
        }
    }

    /**
     * Ejecutar un bloque dentro de una transacción.
     * Hace commit si no lanza excepción; rollback si lanza.
     */
    public function transaction(callable $callback): mixed
    {
        $this->beginTransaction();
        try {
            $result = $callback($this);
            $this->commit();
            return $result;
        } catch (Throwable $e) {
            $this->rollback();
            throw $e;
        }
    }

    // Evitar clonación y deserialización del Singleton
    private function __clone() {}
    public function __wakeup(): void
    {
        throw new RuntimeException('No se permite deserializar DB.');
    }
}

// ─── FUNCIONES AUXILIARES DE SEGURIDAD ───────────────────────

/**
 * Hashear contraseña con bcrypt cost 12.
 */
function hashPassword(string $plain): string
{
    return password_hash($plain, PASSWORD_BCRYPT, ['cost' => 12]);
}

/**
 * Verificar contraseña contra el hash almacenado.
 */
function verifyPassword(string $plain, string $hash): bool
{
    return password_verify($plain, $hash);
}

/**
 * Sanitizar entrada de texto (prevenir XSS).
 */
function clean(string $input): string
{
    return htmlspecialchars(trim($input), ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

/**
 * Validar formato de correo electrónico.
 */
function validEmail(string $email): bool
{
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Registrar acción en el log de auditoría.
 */
function logActividad(
    string $accion,
    ?int   $usuario_id = null,
    ?int   $cliente_id = null,
    ?string $entidad = null,
    ?int   $entidad_id = null,
    array  $detalle = []
): void {
    try {
        DB::getInstance()->insert('actividad_log', [
            'usuario_id' => $usuario_id,
            'cliente_id' => $cliente_id,
            'accion'     => $accion,
            'entidad'    => $entidad,
            'entidad_id' => $entidad_id,
            'detalle'    => $detalle ? json_encode($detalle, JSON_UNESCAPED_UNICODE) : null,
            'ip'         => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);
    } catch (Throwable) {
        // El log nunca debe romper el flujo principal
    }
}

// ─── EJEMPLOS DE USO ─────────────────────────────────────────
/*
require_once 'db.php';
$db = DB::getInstance();

// 1. Listar socios activos
$socios = $db->fetchAll("SELECT * FROM v_socios_activos ORDER BY dias_restantes ASC");

// 2. Buscar cliente por correo
$cliente = $db->fetchOne(
    "SELECT * FROM clientes WHERE correo = ? AND activo = 1",
    ['carlos@mail.com']
);

// 3. Login de usuario (staff)
$usuario = $db->fetchOne(
    "SELECT u.*, r.nombre AS rol_nombre, r.permisos
     FROM usuarios u
     JOIN roles r ON r.id = u.rol_id
     WHERE u.correo = ? AND u.activo = 1",
    ['peter.saloz@elpunto.mx']
);
if ($usuario && verifyPassword('peter123', $usuario['password_hash'])) {
    $db->update('usuarios', ['ultimo_acceso' => date('Y-m-d H:i:s')], ['id' => $usuario['id']]);
    logActividad('login', $usuario['id']);
    // → sesión iniciada
}

// 4. Registrar pago con transacción
$db->transaction(function (DB $db) {
    $db->execute("CALL sp_procesar_pago(1, 4, 700.00, 'Efectivo', 1)");
});

// 5. Ingresos del mes actual
$ingresos = $db->fetchValue(
    "SELECT COALESCE(SUM(monto),0) FROM pagos
     WHERE YEAR(fecha_pago)=YEAR(CURDATE())
       AND MONTH(fecha_pago)=MONTH(CURDATE())
       AND estatus='Completado'"
);

// 6. Asistencias de hoy
$asistencias = $db->fetchAll("SELECT * FROM v_asistencias_hoy");

// 7. Insertar cliente nuevo
$nuevoId = $db->insert('clientes', [
    'codigo'        => '011',
    'nombre'        => 'Ana',
    'apellido'      => 'López',
    'fecha_nac'     => '2001-03-10',
    'telefono'      => '7441234567',
    'correo'        => 'ana@mail.com',
    'password_hash' => hashPassword('ana123'),
    'genero'        => 'Femenino',
]);
logActividad('registro_cliente', null, (int)$nuevoId);
*/
