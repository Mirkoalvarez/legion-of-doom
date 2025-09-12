extends Node2D
class_name Spawner

## Spawner con Oleadas (compatible con tu escena actual)
## - Si hay Camera2D en camera_path, spawnea FUERA de la pantalla (mejor “entrada a escena”).
## - Si no hay cámara, usa spawn_area (tu comportamiento actual).
## - Soporta múltiples tipos de enemigo y límite de simultáneos.
## - Avanza a la siguiente ola cuando no quedan enemigos del grupo "enemy".

signal wave_started(index: int)
signal wave_cleared(index: int)
signal all_waves_cleared()

# ---- CÁMARA / ÁREA ----
@export var camera_path: NodePath
@export var spawn_margin: float = 96.0           # distancia extra fuera de pantalla
@export var spawn_area: Rect2                     # fallback si no hay cámara
@export var min_distance: float = 200.0           # distancia mínima al player (para spawn_area fallback)

# ---- CONTROL ----
@export var auto_start: bool = true
@export var max_concurrent: int = 30

# ---- ENEMIGOS ----
@export var enemy_scenes: Array[PackedScene] = [] # pool de escenas (índices 0..n)

# ---- OLEADAS ----
# Por ola: count (int), spawn_rate (float), enemy_scene_idx (int) o enemy_scene (String ruta opcional)
@export var waves: Array[Dictionary] = [
	{ "count": 8,  "spawn_rate": 0.8, "enemy_scene_idx": 0 },
	{ "count": 12, "spawn_rate": 0.6, "enemy_scene_idx": 0 },
	{ "count": 16, "spawn_rate": 0.5, "enemy_scene_idx": 0 }
]

var _current_wave: int = -1
var _camera: Camera2D

func _ready() -> void:
	# randomize()
	_camera = get_node_or_null(camera_path) as Camera2D
	if auto_start and waves.size() > 0:
		start_waves()

func start_waves() -> void:
	_current_wave = -1
	_run_next_wave()

func _run_next_wave() -> void:
	_current_wave += 1
	if _current_wave >= waves.size():
		emit_signal("all_waves_cleared")
		return

	var w: Dictionary = waves[_current_wave]
	var count: int = int(w.get("count", 10))
	var rate: float = float(w.get("spawn_rate", 1.0))

	emit_signal("wave_started", _current_wave)
	_spawn_wave(count, rate, w)

func _spawn_wave(count: int, rate: float, w: Dictionary) -> void:
	var spawned: int = 0
	await get_tree().process_frame

	while spawned < count:
		# límite de enemigos simultáneos
		while _enemy_alive_count() >= max_concurrent:
			await get_tree().create_timer(0.25).timeout

		var scene: PackedScene = _pick_enemy_scene_for_wave(w)
		if scene == null:
			break

		var pos: Vector2 = _pick_spawn_point()
		var e: Node2D = scene.instantiate() as Node2D
		if e == null:
			break

		get_parent().add_child(e)
		e.global_position = pos

		# conectar señal "died" si existe (no obligatorio)
		if e.has_signal("died") and not e.is_connected("died", Callable(self, "_on_enemy_died")):
			e.connect("died", Callable(self, "_on_enemy_died"))

		spawned += 1
		await get_tree().create_timer(max(0.01, rate)).timeout

	# esperar a que mueran los enemigos de la ola
	while _enemy_alive_count() > 0:
		await get_tree().create_timer(0.25).timeout

	emit_signal("wave_cleared", _current_wave)
	_run_next_wave()

# ---------- helpers ----------

func _resolve_enemy_scene(w: Dictionary) -> PackedScene:
	# Opción 1: ruta directa en la ola
	if w.has("enemy_scene"):
		var path: String = String(w["enemy_scene"])
		var ps: PackedScene = load(path) as PackedScene
		if ps != null:
			return ps

	# Opción 2: índice a enemy_scenes exportado
	if w.has("enemy_scene_idx"):
		var idx: int = int(w["enemy_scene_idx"])
		if idx >= 0 and idx < enemy_scenes.size():
			return enemy_scenes[idx]

	# fallback: primer elemento
	if enemy_scenes.size() > 0:
		return enemy_scenes[0]

	return null

func _enemy_alive_count() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

func _pick_spawn_point() -> Vector2:
	# Si hay cámara, spawnear fuera de pantalla
	if _camera != null:
		return _random_point_around_screen(_camera, spawn_margin)

	# Fallback: tu lógica original con spawn_area + distancia al player
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var spawn_pos: Vector2 = Vector2.ZERO
	var attempts: int = 0
	var valid: bool = false
	while attempts < 10 and not valid:
		var x: float = randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
		var y: float = randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
		spawn_pos = Vector2(x, y)
		if player == null or spawn_pos.distance_to(player.global_position) >= min_distance:
			valid = true
		else:
			attempts += 1
	return spawn_pos

func _pick_enemy_scene_for_wave(w: Dictionary) -> PackedScene:
	# enemy_pool: Array[{idx:int?, path:String?, weight:float?}]
	if w.has("enemy_pool"):
		var pool := w["enemy_pool"] as Array
		if pool.size() > 0:
			var total := 0.0
			for e in pool:
				total += float((e as Dictionary).get("weight", 1.0))
			var roll := randf() * total
			for e in pool:
				var weight := float((e as Dictionary).get("weight", 1.0))
				roll -= weight
				if roll <= 0.0:
					return _scene_from_pool_entry(e)
			# fallback por si no entró en el bucle
			return _scene_from_pool_entry(pool[0])

	# enemy_scene_idxs: Array[int] → elección uniforme entre índices
	if w.has("enemy_scene_idxs"):
		var idxs := w["enemy_scene_idxs"] as Array
		if idxs.size() > 0:
			var pick := int(idxs[randi() % idxs.size()])
			return _scene_from_idx_or_path(pick, null)

	# Soporte original: idx o path único
	return _scene_from_idx_or_path(int(w.get("enemy_scene_idx", -1)), w.get("enemy_scene", null))


func _scene_from_pool_entry(entry: Dictionary) -> PackedScene:
	if entry.has("path"):
		var ps := load(String(entry["path"])) as PackedScene
		if ps != null:
			return ps
	if entry.has("idx"):
		var idx := int(entry["idx"])
		if idx >= 0 and idx < enemy_scenes.size():
			return enemy_scenes[idx]
	# fallback general
	return enemy_scenes[0] if enemy_scenes.size() > 0 else null


func _scene_from_idx_or_path(idx: int, path_var: Variant) -> PackedScene:
	if path_var != null:
		var ps := load(String(path_var)) as PackedScene
		if ps != null:
			return ps
	if idx >= 0 and idx < enemy_scenes.size():
		return enemy_scenes[idx]
	return enemy_scenes[0] if enemy_scenes.size() > 0 else null


# --- utilidades de cámara ---
func _screen_world_rect(cam: Camera2D) -> Rect2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5

	if cam == null:
		return Rect2(-half, vp_size)

	# si hay cámara, recalculamos half con zoom
	half = half * cam.zoom
	var top_left: Vector2 = cam.global_position - half
	return Rect2(top_left, half * 2.0)

func _random_point_around_screen(cam: Camera2D, margin: float) -> Vector2:
	var r: Rect2 = _screen_world_rect(cam).grow(margin)
	var side: int = randi() % 4  # 0=top,1=right,2=bottom,3=left
	match side:
		0:
			return Vector2(randf_range(r.position.x, r.position.x + r.size.x), r.position.y)
		1:
			return Vector2(r.position.x + r.size.x, randf_range(r.position.y, r.position.y + r.size.y))
		2:
			return Vector2(randf_range(r.position.x, r.position.x + r.size.x), r.position.y + r.size.y)
		3:
			return Vector2(r.position.x, randf_range(r.position.y, r.position.y + r.size.y))
		_:
			return cam.global_position if cam != null else Vector2.ZERO
func _on_enemy_died() -> void:
	# hook opcional
	pass
