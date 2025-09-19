extends CharacterBody2D

# --- MOVIMIENTO ---
@export var speed: float = 260.0
@export var acceleration: float = 2000.0
@export var friction: float = 2000.0

# --- DASH ---
@export var dash_speed_mult: float = 3.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.45
@export var dash_gives_iframes: bool = true
var _dash_time_left: float = 0.0
var _dash_cd_left: float = 0.0
var _is_dashing: bool = false

# --- VIDA / DAÑO ---
@export var max_hp: int = 100
@export var i_frames_time: float = 0.5
var hp: int
var _invulnerable: bool = false
var _i_frames_timer: Timer

# --- ARMAS / COMPONENTES ---
@export var melee_weapon: Node           # MeleeWeapon.gd
@export var ranged_weapon: Node          # ProjectileWeapon.gd
@export var health: Node                 # Health.gd 
@export var enemy_detector: Area2D       

# - - - UPGRADES - - -
@export var upgrade_manager: UpgradeManager
@export var upgrade_picker: UpgradePicker

# --- SEÑALES ---
signal hp_changed(current: int, max_value: int)
signal died

# --- ESTADO ---
var _input_dir: Vector2 = Vector2.ZERO
var _aim_dir: Vector2 = Vector2.RIGHT
var enemy_close: Array[Node2D] = []

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var experience: Experience = $Experience

func _ready() -> void:
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)
	add_to_group("player")

	_i_frames_timer = Timer.new()
	_i_frames_timer.one_shot = true
	_i_frames_timer.wait_time = i_frames_time
	_i_frames_timer.timeout.connect(_on_i_frames_timeout)
	add_child(_i_frames_timer)

	if enemy_detector:
		if not enemy_detector.body_entered.is_connected(_on_enemy_enter):
			enemy_detector.body_entered.connect(_on_enemy_enter)
		if not enemy_detector.body_exited.is_connected(_on_enemy_exit):
			enemy_detector.body_exited.connect(_on_enemy_exit)

	# Hurtbox opcional: solo para HUD/SFX
	var hb := get_node_or_null("Hurtbox")
	if hb and not hb.is_connected("hurt", Callable(self, "_on_hurtbox_hurt")):
		hb.connect("hurt", Callable(self, "_on_hurtbox_hurt"))

	if experience:
		if not experience.level_up.is_connected(_on_level_up):
			experience.level_up.connect(_on_level_up)

func _process(_dt: float) -> void:
	_input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	if _input_dir != Vector2.ZERO:
		_aim_dir = _input_dir

	_update_animation()

	if Input.is_action_just_pressed("attack_melee") and melee_weapon:
		var dir: Vector2 = _aim_dir
		var closest := _get_closest_enemy()
		if closest:
			dir = (closest.global_position - global_position).normalized()
		melee_weapon.try_fire(dir, self)

	if Input.is_action_pressed("attack_ranged") and ranged_weapon:
		var dir: Vector2 = _aim_dir
		var closest := _get_closest_enemy()
		if closest:
			dir = (closest.global_position - global_position).normalized()
		ranged_weapon.try_fire(dir, self)

func _physics_process(dt: float) -> void:
	if _input_dir != Vector2.ZERO:
		var desired := _input_dir * speed
		velocity = velocity.move_toward(desired, acceleration * dt)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * dt)

	# --- DASH / MOVIMIENTO ---
	if _dash_cd_left > 0.0:
		_dash_cd_left = max(0.0, _dash_cd_left - dt)
	if Input.is_action_just_pressed("dash"):
		_try_start_dash()

	if _is_dashing:
		velocity = _input_dir * speed * dash_speed_mult
		_dash_time_left -= dt
		if _dash_time_left <= 0.0:
			_end_dash()
	else:
		if _input_dir != Vector2.ZERO:
			var desired := _input_dir * speed
			velocity = velocity.move_toward(desired, acceleration * dt)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * dt)
	move_and_slide()

# --- ENEMIGOS CERCANOS ---
func _on_enemy_enter(body: Node) -> void:
	if body.is_in_group("enemy") and body is Node2D and not enemy_close.has(body):
		enemy_close.append(body)
		if not body.is_connected("tree_exited", Callable(self, "_on_enemy_tree_exited")):
			body.connect("tree_exited", Callable(self, "_on_enemy_tree_exited").bind(body))

func _on_enemy_exit(body: Node) -> void:
	if enemy_close.has(body):
		enemy_close.erase(body)

func _on_enemy_tree_exited(body: Node) -> void:
	if enemy_close.has(body):
		enemy_close.erase(body)

func _get_closest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in enemy_close:
		if not is_instance_valid(e): continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

# --- VIDA / DAÑO ---
func heal(amount: int) -> void:
	if amount <= 0: return
	hp = clamp(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)

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
	queue_free()

# --- HURTBOX (opcional HUD/SFX) ---
func _on_hurtbox_hurt(_amount: int) -> void:
	# Solo feedback: el daño real ya llega por take_damage() desde hitbox/proyectil
	pass

# - - - DASH MOVIMIENTO - - -
func _try_start_dash() -> void:
	if _is_dashing or _dash_cd_left > 0.0:
		return
	if _input_dir == Vector2.ZERO:
		return
	_is_dashing = true
	_dash_time_left = dash_time
	_dash_cd_left = dash_cooldown
	if dash_gives_iframes:
		_invulnerable = true
	_blink_start()

func _end_dash() -> void:
	_is_dashing = false
	if dash_gives_iframes:
		_invulnerable = false
	_blink_stop()

# --- ANIMACIÓN ---
func _update_animation() -> void:
	if anim == null:
		return
	if _input_dir == Vector2.ZERO:
		anim.stop()
		anim.frame = 0
		return
	if abs(_input_dir.x) > abs(_input_dir.y):
		anim.play("right" if _input_dir.x > 0 else "left")
	else:
		anim.play("back" if _input_dir.y < 0 else "front")

func _blink_start() -> void:
	if anim:
		anim.modulate.a = 0.5

func _blink_stop() -> void:
	if anim:
		anim.modulate.a = 1.0

# - - - HANDLERS DE UPGRADE - - - 
func _on_level_up(_lvl: int) -> void:
	# Mostrar 3 opciones
	if upgrade_manager and upgrade_picker:
		var options := upgrade_manager.get_random_options(3)
		upgrade_picker.show_options(options, upgrade_manager)
		if not upgrade_picker.is_connected("picked", Callable(self, "_on_upgrade_picked")):
			upgrade_picker.connect("picked", Callable(self, "_on_upgrade_picked"))

func _on_upgrade_picked(id: String) -> void:
	if upgrade_manager:
		upgrade_manager.apply_upgrade(id, self)
