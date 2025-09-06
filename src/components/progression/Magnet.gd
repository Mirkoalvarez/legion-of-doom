extends Area2D
class_name Magnet

# ---- Básicos ----
@export var pull_speed: float = 480.0          # velocidad inicial de tirón (px/s)
@export var pull_accel: float = 800.0          # aceleración del tirón (px/s^2). 0 = constante
@export var max_speed: float = 1200.0          # tope

# ---- Snap (agarre al final) ----
@export var snap_on_close: bool = true
@export var snap_distance: float = 12.0        # distancia para hacer snap (px)
@export var snap_give_direct: bool = true      # intenta “dar” el pickup al jugador al snap

# ---- Swirl (trayectoria curvada) ----
# Si swirl_amount > 0, aplica un desplazamiento perpendicular para una trayectoria curva
@export var swirl_amount: float = 0.0          # 0 = sin swirl (recomendado: 0.0 .. 0.3)
@export var swirl_freq: float = 6.0            # Hz de la oscilación

# ---- Seguridad ----
@export var max_track: int = 64                # máximo de objetivos simultáneos

# ---- Estado interno ----
var _targets: Array[Node2D] = []               # objetivos actuales
var _speeds: Array[float] = []                 # velocidad individual por objetivo
var _time: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("magnet")
	
	# Conexiones
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	_time += delta
	var my_pos: Vector2 = global_position

	for i in range(_targets.size()):
		var n: Node2D = _targets[i]
		if n == null or not is_instance_valid(n):
			continue

		# Dirección base hacia el centro del imán
		var to_me: Vector2 = my_pos - n.global_position
		var dist: float = to_me.length()
		if dist <= 0.001:
			continue

		var dir: Vector2 = to_me / dist

		# Swirl (curvatura) opcional: mezclamos un vector perpendicular
		if swirl_amount > 0.0:
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			var sway: float = sin(_time * TAU * (swirl_freq / 2.0)) * swirl_amount
			dir = (dir + perp * sway).normalized()

		# Acelerar velocidad del objetivo i
		if pull_accel > 0.0:
			_speeds[i] = min(max_speed, _speeds[i] + pull_accel * delta)
		else:
			_speeds[i] = clamp(_speeds[i], 0.0, max_speed)

		var step: float = _speeds[i] * delta

		# Snap (agarre final)
		if snap_on_close and dist <= snap_distance:
			# posiciona en el centro del magnet (Player)
			n.global_position = my_pos
			# intentar entregar al instante (XPOrb/otros pickups)
			if snap_give_direct:
				_try_give_direct(n)
			continue

		# Avance normal hacia el magnet (clamp para no pasarse)
		if step >= dist:
			n.global_position = my_pos
			if snap_give_direct:
				_try_give_direct(n)
		else:
			n.global_position = n.global_position + dir * step

# ----------------- Gestión de objetivos -----------------

func _on_area_entered(a: Area2D) -> void:
	_try_add(a)

func _on_area_exited(a: Area2D) -> void:
	_try_remove(a)

func _on_body_entered(b: Node) -> void:
	_try_add(b)

func _on_body_exited(b: Node) -> void:
	_try_remove(b)

func _try_add(node: Node) -> void:
	if _targets.size() >= max_track:
		return
	if node is Node2D:
		var n2d: Node2D = node as Node2D
		if not _targets.has(n2d):
			_targets.append(n2d)
			_speeds.append(pull_speed)
			# limpiar si se destruye
			if not n2d.is_connected("tree_exited", Callable(self, "_on_target_tree_exited")):
				n2d.connect("tree_exited", Callable(self, "_on_target_tree_exited").bind(n2d))

func _try_remove(node: Node) -> void:
	if node is Node2D:
		var n2d: Node2D = node as Node2D
		var idx: int = _targets.find(n2d)
		if idx != -1:
			_targets.remove_at(idx)
			_speeds.remove_at(idx)

func _on_target_tree_exited(node_gone: Node) -> void:
	if node_gone is Node2D:
		var n2d: Node2D = node_gone as Node2D
		var idx: int = _targets.find(n2d)
		if idx != -1:
			_targets.remove_at(idx)
			_speeds.remove_at(idx)

# ----------------- Entrega directa opcional -----------------

func _try_give_direct(n: Node2D) -> void:
	# Si el pickup es un XPOrb, intenta “dárselo” al Player inmediatamente
	# Asumimos que el Magnet cuelga del Player:
	var player: Node = get_parent()
	if n.has_method("_try_give_to"):
		n.call("_try_give_to", player)
	elif n.has_method("collect"):
		n.call("collect")
	# Si no tiene método, al estar encima del Player normalmente su colisión terminará recogiendo igual.
