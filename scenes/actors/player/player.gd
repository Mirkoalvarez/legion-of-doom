extends CharacterBody2D
##
## Player.gd (Godot 4, 2D)
## - Movimiento con WASD (aceleración/frenado suave)
## - Vida y daño con invulnerabilidad breve (i-frames)
## - Animación por dirección con AnimatedSprite2D (front/left/right/back)
## - Señales para HUD
## - Hooks para Hurtbox/Magnet si existen
##

# --- MOVIMIENTO ---
@export var speed: float = 260.0           # velocidad base (px/s)
@export var acceleration: float = 2000.0   # acelera hacia el input (suave)
@export var friction: float = 2000.0       # frena cuando no hay input
@onready var enemy_detector = $EnemyDetector
@export var projectile_scene: PackedScene

# --- VIDA / DAÑO ---
@export var max_hp: int = 100
@export var i_frames_time: float = 0.5     # invulnerabilidad tras recibir daño (segundos)
var hp: int

# --- DEBUG ---
@export var print_collisions: bool = false # imprime colisiones al chocar

# --- SEÑALES ---
signal hp_changed(current: int, max_value: int)
signal died

# --- ESTADO INTERNO ---
var _input_dir := Vector2.RIGHT
var _facing_dir := Vector2.RIGHT
var _invulnerable := false
var enemy_close: Array[Node2D] = []

# Timers internos
var _i_frames_timer: Timer

# --- NODOS (ajustá la ruta si tu nodo animado se llama distinto) ---
@onready var anim: AnimatedSprite2D = $Sprite

func _ready() -> void:
	# Vida
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)

	# Grupo
	add_to_group("player")

	# Timer de invulnerabilidad
	_i_frames_timer = Timer.new()
	_i_frames_timer.wait_time = i_frames_time
	_i_frames_timer.one_shot = true
	_i_frames_timer.timeout.connect(_on_i_frames_timeout)
	add_child(_i_frames_timer)

	# Conexiones opcionales si existen nodos hijos (no rompen si no están)
	# Hurtbox: Area2D para recibir contacto de enemigos
	if has_node("Hurtbox"):
		var hb := get_node("Hurtbox")
		if hb.has_signal("body_entered"):
			hb.body_entered.connect(_on_hurtbox_body_entered)
		if hb.has_signal("area_entered"):
			hb.area_entered.connect(_on_hurtbox_area_entered)

	# Magnet: Area2D grande para atraer/recoger pickups
		# Magnet: Area2D grande para atraer/recoger pickups
		if has_node("Magnet"):
			var mg := get_node("Magnet")
			if mg.has_signal("area_entered"):
				mg.area_entered.connect(_on_magnet_area_entered)

		# EnemyDetector: mantiene lista de enemigos cercanos
			if enemy_detector:
				enemy_detector.body_entered.connect(_on_enemy_detection_area_body_entered)
				enemy_detector.body_exited.connect(_on_enemy_detection_area_body_exited)

func _process(_dt: float) -> void:
	# Leer input en _process (más reactivo), mover en _physics_process
		_input_dir = Vector2(
				Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
				Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
		).normalized()
		if _input_dir != Vector2.ZERO:
				_facing_dir = _input_dir
		_update_animation()
		if Input.is_action_just_pressed("shoot"):
				_shoot()


func _physics_process(dt: float) -> void:
	# Movimiento suave con aceleración/frenado
	if _input_dir != Vector2.ZERO:
		var desired := _input_dir * speed
		velocity = velocity.move_toward(desired, acceleration * dt)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * dt)

	move_and_slide()

	# Debug de colisiones contra mundo/cuerpos
	if print_collisions and get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			if col and col.get_collider():
				print("Colisioné con: ", col.get_collider())

# DISPAROS PROJECTILES
func get_closest_enemy(from_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in enemy_close:
		if not is_instance_valid(e):
			continue
		var d := from_pos.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _on_enemy_detection_area_body_entered(body: Node):
		# Asegurate que tus enemigos estén en el grupo "enemy"
	if body.is_in_group("enemy") and not enemy_close.has(body):
		enemy_close.append(body)
			# Limpia automáticamente si el enemigo desaparece del árbol
		if not body.is_connected("tree_exited", Callable(self, "_on_enemy_tree_exited")):
				body.connect("tree_exited", Callable(self, "_on_enemy_tree_exited").bind(body))
		call_deferred("_shoot")

func _on_enemy_detection_area_body_exited(body: Node):
	if enemy_close.has(body):
		enemy_close.erase(body)

func _on_enemy_tree_exited(body: Node):
	# Evita referencias colgantes
	if enemy_close.has(body):
		enemy_close.erase(body)

func _shoot() -> void:
	if projectile_scene == null:
		return
	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position

	var target = enemy_detector.get_target()
	if target and is_instance_valid(target):
		bullet.target = target
		bullet.direction = (target.global_position - global_position).normalized()
	else:
		bullet.direction = _facing_dir

	get_parent().add_child(bullet)

# --- ANIMACIÓN ---
func _update_animation() -> void:
	if anim == null:
		return

	if _input_dir == Vector2.ZERO:
		anim.stop()
		anim.frame = 0
		return

	# Elegimos anim por componente dominante
	if abs(_input_dir.x) > abs(_input_dir.y):
		anim.play("right" if _input_dir.x > 0 else "left")
	else:
		anim.play("back" if _input_dir.y < 0 else "front")

# --- API PÚBLICA ---

func heal(amount: int) -> void:
	if amount <= 0: return
	hp = clamp(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)

func take_damage(amount: int) -> void:
	if amount <= 0: return
	if _invulnerable: return

	hp = clamp(hp - amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)
	print(hp)
	
	# activar i-frames
	_invulnerable = true
	_i_frames_timer.start()
	_blink_start()

	if hp <= 0:
		_die()

# --- HANDLERS DE ÁREAS (opcionales) ---

func _on_hurtbox_body_entered(body: Node) -> void:
	# Si un enemigo (con grupo "enemy") me toca, recibir daño fijo de contacto
	if body.is_in_group("enemy"):
		take_damage(10)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Si un área de daño enemigo me toca
	if area.is_in_group("enemy_hitbox"):
		if area.has_method("get_damage"):
			take_damage(int(area.get_damage()))
		else:
			take_damage(10)

func _on_hurtbox_hurt(amount: int) -> void:
	take_damage(amount)

func _on_magnet_area_entered(area: Area2D) -> void:
	# Recoger XP/monedas si las pickups usan grupo "pickup"
	if area.is_in_group("pickup"):
		if area.has_method("collect"):
			area.collect()
		else:
			area.queue_free()

# --- PRIVADO ---

func _on_i_frames_timeout() -> void:
	_invulnerable = false
	_blink_stop()

func _die() -> void:
	emit_signal("died")
	queue_free()

func _blink_start() -> void:
	# Parpadeo simple del nodo animado durante i-frames
	if anim:
		anim.modulate.a = 0.5

func _blink_stop() -> void:
	if anim:
		anim.modulate.a = 1.0
