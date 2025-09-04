extends CharacterBody2D
## Player.gd (Godot 4.4)
## - Movimiento suave (aceleración/frenado)
## - i-frames básicos
## - AnimatedSprite2D con anims: front/left/right/back
## - Armas: melee_weapon + ranged_weapon (ProjectileWeapon)
## - EnemyDetector opcional para auto-aim

# --- MOVIMIENTO ---
@export var speed: float = 260.0
@export var acceleration: float = 2000.0
@export var friction: float = 2000.0

# --- VIDA / DAÑO ---
@export var max_hp: int = 100
@export var i_frames_time: float = 0.5
var hp: int
var _invulnerable := false
var _i_frames_timer: Timer

# --- ARMAS / COMPONENTES (arrastrá los nodos hijos en el inspector) ---
@export var melee_weapon: Node            # MeleeWeapon.gd
@export var ranged_weapon: Node           # ProjectileWeapon.gd
@export var health: Node                  # Health.gd (opcional, si lo usás)
@export var enemy_detector: Area2D        # opcional (puede ser null)

# --- SEÑALES ---
signal hp_changed(current: int, max_value: int)
signal died

# --- ESTADO ---
var _input_dir := Vector2.ZERO
var _aim_dir := Vector2.RIGHT
var enemy_close: Array[Node2D] = []

# --- ANIMACIÓN ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Vida inicial
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)
	add_to_group("player")

	# Timer i-frames
	_i_frames_timer = Timer.new()
	_i_frames_timer.one_shot = true
	_i_frames_timer.wait_time = i_frames_time
	_i_frames_timer.timeout.connect(_on_i_frames_timeout)
	add_child(_i_frames_timer)

	# EnemyDetector (opcional)
	if enemy_detector:
		if not enemy_detector.body_entered.is_connected(_on_enemy_enter):
			enemy_detector.body_entered.connect(_on_enemy_enter)
		if not enemy_detector.body_exited.is_connected(_on_enemy_exit):
			enemy_detector.body_exited.connect(_on_enemy_exit)

	# Hurtbox opcional
	var hb := get_node_or_null("Hurtbox")
	if hb:
		if hb.has_signal("body_entered"): hb.body_entered.connect(_on_hurtbox_body_entered)
		if hb.has_signal("area_entered"): hb.area_entered.connect(_on_hurtbox_area_entered)
		if not hb.is_connected("hurt", Callable(self, "_on_hurtbox_hurt")):
			hb.connect("hurt", Callable(self, "_on_hurtbox_hurt"))
	
	# Magnet opcional
	var mg := get_node_or_null("Magnet")
	if mg and mg.has_signal("area_entered"):
		mg.area_entered.connect(_on_magnet_area_entered)

func _process(_dt: float) -> void:
	# Input direccional (más responsivo)
	_input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	if _input_dir != Vector2.ZERO:
		_aim_dir = _input_dir

	_update_animation()

	# Ataques por input
	if Input.is_action_just_pressed("attack_melee") and melee_weapon:
		melee_weapon.try_fire(_aim_dir, self)

	if Input.is_action_pressed("attack_ranged") and ranged_weapon:
		var dir := _aim_dir
		var closest := _get_closest_enemy()
		if closest:
			dir = (closest.global_position - global_position).normalized()
		ranged_weapon.try_fire(dir, self)

func _physics_process(dt: float) -> void:
	# Movimiento con aceleración/frenado
	if _input_dir != Vector2.ZERO:
		var desired := _input_dir * speed
		velocity = velocity.move_toward(desired, acceleration * dt)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * dt)
	move_and_slide()

# -------------------------
# ENEMIGOS CERCANOS (opcional)
# -------------------------
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
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

# -------------------------
# VIDA / DAÑO / I-FRAMES
# -------------------------
func heal(amount: int) -> void:
	if amount <= 0: return
	hp = clamp(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)

func take_damage(amount: int) -> void:
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

# -------------------------
# HURTBOX / MAGNET (opcionales)
# -------------------------
func _on_hurtbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		take_damage(10)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		if area.has_method("get_damage"):
			take_damage(int(area.get_damage()))
		else:
			take_damage(10)

func _on_magnet_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickup"):
		if area.has_method("collect"):
			area.collect()
		else:
			area.queue_free()

func _on_hurtbox_hurt(amount: int) -> void:
	# Usa el amount que envía la señal de Hurtbox
	take_damage(amount)

# -------------------------
# ANIMACIÓN
# -------------------------
func _update_animation() -> void:
	if anim == null:
		return
	if _input_dir == Vector2.ZERO:
		anim.stop()
		anim.frame = 0
		return
	if abs(_input_dir.x) > abs(_input_dir.y):
		if _input_dir.x > 0:
			anim.play("right")
		else:
			anim.play("left")
	else:
		if _input_dir.y < 0:
			anim.play("back")
		else:
			anim.play("front")

func _blink_start() -> void:
	if anim:
		anim.modulate.a = 0.5

func _blink_stop() -> void:
	if anim:
		anim.modulate.a = 1.0
