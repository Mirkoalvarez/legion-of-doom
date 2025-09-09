# res://src/actors/enemy/EnemyBasic.gd
extends CharacterBody2D
class_name EnemyBasic

# --- MOVIMIENTO ---
@export var speed: float = 90.0
@export var acceleration: float = 1600.0
@export var friction: float = 1600.0

# --- VIDA / DAÑO ---
@export var max_hp: int = 20
@export var i_frames_time: float = 0.2
var hp: int = 0
var _invulnerable: bool = false
var _i_frames_timer: Timer

# --- XP DROP ---
@export var xp_orb_scene: PackedScene
@export var xp_drop: int = 10

# --- DROPS EXTRA ---
@export var health_pickup_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var health_drop_chance: float = 0.2

@export var speed_pickup_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var speed_drop_chance: float = 0.15

@export var projdam_pickup_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var projdam_drop_chance: float = 0.15


# --- SEÑALES ---
signal hp_changed(current: int, max_value: int)
signal died

# --- ESTADO ---
var _move_dir: Vector2 = Vector2.ZERO
var _player: Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)
	add_to_group("enemy")

	_player = get_tree().get_first_node_in_group("player") as Node2D

	_i_frames_timer = Timer.new()
	_i_frames_timer.one_shot = true
	_i_frames_timer.wait_time = i_frames_time
	_i_frames_timer.timeout.connect(_on_i_frames_timeout)
	add_child(_i_frames_timer)

	if anim:
		anim.play("front")

func _physics_process(dt: float) -> void:
	if _player != null and is_instance_valid(_player):
		_move_dir = (_player.global_position - global_position).normalized()
	else:
		_move_dir = Vector2.ZERO

	if _move_dir != Vector2.ZERO:
		var desired: Vector2 = _move_dir * speed
		velocity = velocity.move_toward(desired, acceleration * dt)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * dt)

	move_and_slide()
	_update_animation()

# --- VIDA / DAÑO ---
func take_damage(amount: int, _source: Node = null) -> void:
	if amount <= 0: return
	if _invulnerable: return

	hp = clamp(hp - amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)

	_invulnerable = true
	_i_frames_timer.start()
	_blink_start()

	if hp <= 0:
		_die()

func _on_i_frames_timeout() -> void:
	_invulnerable = false
	_blink_stop()

func _die() -> void:
	emit_signal("died")
	# Spawnear orbe de XP en diferido para evitar "flushing queries"
	var pos: Vector2 = global_position
	call_deferred("_spawn_xp_orb_at", pos)
	call_deferred("_try_spawn_health_pickup", pos)
	call_deferred("_try_spawn_speed_pickup", pos)
	call_deferred("_try_spawn_projdam_pickup", pos)
	queue_free()

# --- DROPS ---
func _spawn_xp_orb_at(pos: Vector2) -> void:
	if xp_orb_scene == null:
		return
	var orb: Node2D = xp_orb_scene.instantiate() as Node2D
	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(orb)
	orb.global_position = pos
	# Pasar cantidad de XP si el orbe expone esa propiedad
	if "xp_amount" in orb:
		orb.set("xp_amount", xp_drop)

func _try_spawn_health_pickup(pos: Vector2) -> void:
	if health_pickup_scene == null: 
		return
	# tirada
	if randf() <= health_drop_chance:
		var drop: Node2D = health_pickup_scene.instantiate() as Node2D
		var parent: Node = get_parent()
		if parent == null: return
		parent.add_child(drop)
		drop.global_position = pos

func _try_spawn_speed_pickup(pos: Vector2) -> void:
	if speed_pickup_scene != null and randf() <= speed_drop_chance:
		var drop: Node2D = speed_pickup_scene.instantiate() as Node2D
		get_parent().add_child(drop)
		drop.global_position = pos

func _try_spawn_projdam_pickup(pos: Vector2) -> void:
	if projdam_pickup_scene != null and randf() <= projdam_drop_chance:
		var drop: Node2D = projdam_pickup_scene.instantiate() as Node2D
		get_parent().add_child(drop)
		drop.global_position = pos

# --- ANIMACIÓN ---
func _update_animation() -> void:
	if anim == null:
		return
	if velocity.length() < 1.0:
		anim.stop()
		anim.frame = 0
		return
	var dir := velocity
	if abs(dir.x) > abs(dir.y):
		anim.play("right" if dir.x > 0.0 else "left")
	else:
		anim.play("back" if dir.y < 0.0 else "front")

# --- BLINK ---
func _blink_start() -> void:
	if anim:
		anim.modulate.a = 0.5

func _blink_stop() -> void:
	if anim:
		anim.modulate.a = 1.0
