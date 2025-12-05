extends Node2D
class_name Spawner

# Spawner con dos modos:
# 1) Endless por tiempo (tipo Vampire Survivors): fases por minuto, sin limpiar enemigos previos.
# 2) Waves legacy (opcional, si quieres el comportamiento anterior).

signal wave_started(index: int)
signal wave_cleared(index: int)
signal all_waves_cleared()
signal end_reached()

# ---- CAMARA / AREA ----
@export var camera_path: NodePath
@export var spawn_margin: float = 96.0           # distancia extra fuera de pantalla
@export var spawn_area: Rect2 = Rect2(-600, -600, 1200, 1200) # fallback si no hay camara
@export var min_distance: float = 200.0          # distancia minima al player (para spawn_area fallback)
@export var bounds_path: NodePath                # arrastra el nodo ArenaBounds aqui

# ---- CONTROL ----
@export var auto_start: bool = true
@export var max_concurrent: int = 30
@export var end_time: float = -1.0 # segundos; <0 desactivado

# ---- ENEMIGOS ----
@export var enemy_scenes: Array[PackedScene] = [] # pool de escenas (indices 0..n)

# ---- MODO ENDLESS (tiempo) ----
@export var use_endless: bool = true
# Cada fase empieza en "time" (segundos) y define rate y pool de enemigos
@export var phases: Array[Dictionary] = [
	{
		"time": 0.0,
		"spawn_rate": 1.0, # segundos entre spawns
		"max_concurrent": 25,
		"enemy_pool": [
			{ "path": "res://scenes/actors/enemies/EnemyBasic.tscn", "weight": 1.0 }
		],
		"hp_mult": 1.0,
		"speed_mult": 1.0
	},
	{
		"time": 60.0,
		"spawn_rate": 0.7,
		"max_concurrent": 35,
		"enemy_pool": [
			{ "path": "res://scenes/actors/enemies/EnemyBasic.tscn", "weight": 0.6 },
			{ "path": "res://scenes/actors/enemies/Goblin/goblin.tscn", "weight": 0.4 }
		],
		"hp_mult": 1.2,
		"speed_mult": 1.05
	}
]

# ---- OLEADAS LEGACY (opcional) ----
# Por ola: count (int), spawn_rate (float), enemy_scene_idx (int) o enemy_scene (String ruta opcional)
@export var waves: Array[Dictionary] = [
	{ "count": 8,  "spawn_rate": 0.8, "enemy_scene_idx": 0 },
	{ "count": 12, "spawn_rate": 0.6, "enemy_scene_idx": 0 },
	{ "count": 16, "spawn_rate": 0.5, "enemy_scene_idx": 0 }
]

var _current_wave: int = -1
var _camera: Camera2D
var _phase_idx: int = -1
var _elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _current_phase: Dictionary = {}
var _current_max_concurrent: int = 30
var _endless_running: bool = false
var _ended: bool = false

func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D

	if not auto_start:
		set_process(false)
		return

	if use_endless and phases.size() > 0:
		start_endless()
	elif waves.size() > 0:
		start_waves()
	else:
		set_process(false)

# ------------------- ENDLESS -------------------

func start_endless() -> void:
	_phase_idx = -1
	_elapsed = 0.0
	_endless_running = true
	set_process(true)
	_advance_phase() # inicial

func _process(dt: float) -> void:
	if not _endless_running:
		return

	_elapsed += dt

	# Fin por tiempo total
	if not _ended and end_time > 0.0 and _elapsed >= end_time:
		_ended = true
		_endless_running = false
		set_process(false)
		emit_signal("end_reached")
		return

	# avanzar fase si llega el siguiente umbral de tiempo
	if _phase_idx + 1 < phases.size():
		var next_t: float = float(phases[_phase_idx + 1].get("time", 0.0))
		if _elapsed >= next_t:
			_advance_phase()

	_spawn_timer -= dt
	if _spawn_timer <= 0.0:
		if _enemy_alive_count() < _current_max_concurrent:
			_spawn_one_from_phase(_current_phase)
		_spawn_timer = float(_current_phase.get("spawn_rate", 1.0))

func _advance_phase() -> void:
	_phase_idx += 1
	if _phase_idx < 0 or _phase_idx >= phases.size():
		_endless_running = false
		set_process(false)
		return
	_current_phase = phases[_phase_idx]
	_spawn_timer = 0.0
	_current_max_concurrent = int(_current_phase.get("max_concurrent", max_concurrent))

func _spawn_one_from_phase(p: Dictionary) -> void:
	var scene := _pick_enemy_scene_for_phase(p)
	if scene == null:
		return

	var pos: Vector2 = _pick_spawn_point()
	var e: Node2D = scene.instantiate() as Node2D
	if e == null:
		return

	get_parent().add_child(e)
	e.global_position = pos
	_apply_phase_scaling(e, p)

	if e.has_signal("died") and not e.is_connected("died", Callable(self, "_on_enemy_died")):
		e.connect("died", Callable(self, "_on_enemy_died"))

func _pick_enemy_scene_for_phase(p: Dictionary) -> PackedScene:
	if p.has("enemy_pool"):
		var pool := p["enemy_pool"] as Array
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
			return _scene_from_pool_entry(pool[0])

	# fallback: usa enemy_scenes principal
	if enemy_scenes.size() > 0:
		return enemy_scenes[0]
	return null

func _apply_phase_scaling(e: Node2D, p: Dictionary) -> void:
	var hp_mul := float(p.get("hp_mult", 1.0))
	var speed_mul := float(p.get("speed_mult", 1.0))

	if hp_mul != 1.0:
		var hp_val: Variant = e.get("max_hp")
		if typeof(hp_val) == TYPE_INT or typeof(hp_val) == TYPE_FLOAT:
			var new_hp := float(hp_val) * hp_mul
			e.set("max_hp", new_hp)
			if "hp" in e:
				e.set("hp", new_hp)

	if speed_mul != 1.0:
		var sp_val: Variant = e.get("speed")
		if typeof(sp_val) == TYPE_INT or typeof(sp_val) == TYPE_FLOAT:
			e.set("speed", float(sp_val) * speed_mul)

# ------------------- WAVES LEGACY -------------------

func start_waves() -> void:
	set_process(false)
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

		if e.has_signal("died") and not e.is_connected("died", Callable(self, "_on_enemy_died")):
			e.connect("died", Callable(self, "_on_enemy_died"))

		spawned += 1
		await get_tree().create_timer(max(0.01, rate)).timeout

	while _enemy_alive_count() > 0:
		await get_tree().create_timer(0.25).timeout

	emit_signal("wave_cleared", _current_wave)
	_run_next_wave()

# ---------- helpers ----------

func _resolve_enemy_scene(w: Dictionary) -> PackedScene:
	if w.has("enemy_scene"):
		var path: String = String(w["enemy_scene"])
		var ps: PackedScene = load(path) as PackedScene
		if ps != null:
			return ps

	if w.has("enemy_scene_idx"):
		var idx: int = int(w["enemy_scene_idx"])
		if idx >= 0 and idx < enemy_scenes.size():
			return enemy_scenes[idx]

	if enemy_scenes.size() > 0:
		return enemy_scenes[0]

	return null

func _enemy_alive_count() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

func _pick_spawn_point() -> Vector2:
	var arena := _get_arena_rect()

	if _camera != null:
		var p: Vector2 = _random_point_around_screen(_camera, spawn_margin)
		var inner := arena.grow(-32.0) # 32 px margen interno
		return _clamp_point_to_rect(p, inner)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var spawn_pos := Vector2.ZERO
	var attempts := 0
	var valid := false
	while attempts < 10 and not valid:
		var x := randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
		var y := randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
		spawn_pos = Vector2(x, y)
		if player == null or spawn_pos.distance_to(player.global_position) >= min_distance:
			valid = true
		else:
			attempts += 1
	return spawn_pos

func _pick_enemy_scene_for_wave(w: Dictionary) -> PackedScene:
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
			return _scene_from_pool_entry(pool[0])

	if w.has("enemy_scene_idxs"):
		var idxs := w["enemy_scene_idxs"] as Array
		if idxs.size() > 0:
			var pick := int(idxs[randi() % idxs.size()])
			return _scene_from_idx_or_path(pick, null)

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
	return enemy_scenes[0] if enemy_scenes.size() > 0 else null

func _scene_from_idx_or_path(idx: int, path_var: Variant) -> PackedScene:
	if path_var != null:
		var ps := load(String(path_var)) as PackedScene
		if ps != null:
			return ps
	if idx >= 0 and idx < enemy_scenes.size():
		return enemy_scenes[idx]
	return enemy_scenes[0] if enemy_scenes.size() > 0 else null

# --- utilidades de camara ---
func _screen_world_rect(cam: Camera2D) -> Rect2:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var half: Vector2 = vp_size * 0.5

	if cam == null:
		return Rect2(-half, vp_size)

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

func _get_arena_rect() -> Rect2:
	var ab := get_node_or_null(bounds_path) as Node2D
	if ab and ab.has_method("get_rect"):
		return ab.call("get_rect") as Rect2
	return spawn_area

func _clamp_point_to_rect(p: Vector2, r: Rect2) -> Vector2:
	return Vector2(
		clamp(p.x, r.position.x, r.position.x + r.size.x),
		clamp(p.y, r.position.y, r.position.y + r.size.y)
	)
