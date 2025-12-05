extends "res://src/components/Weapon/Weapon.gd"
class_name SlowAuraWeapon

@export var radius: float = 120.0
@export var slow_pct: float = 0.5            # 0.5 = 50% de velocidad
@export var slow_duration: float = 2.0
@export var damage: int = 5
@export var aura_lifetime: float = 1.0
@export var auto_only: bool = true           # evita disparo manual si se usa este flag
@export var aura_scene: PackedScene          # opcional: escena visual (Area2D); si no, se crea simple

func _fire(_dir: Vector2, owner_node: Node) -> void:
	if owner_node == null:
		return
	# solo dispara si hay un enemigo cerca (radio = radius)
	var owner2d := owner_node as Node2D
	if owner2d and not _has_enemy_in_radius(owner2d.global_position, radius):
		return

	var aura := _make_aura(owner_node)
	if aura == null:
		return
	owner_node.get_parent().add_child(aura)
	if aura is Node2D:
		(aura as Node2D).global_position = (owner_node as Node2D).global_position

func _make_aura(owner_node: Node) -> Area2D:
	var aura: Area2D = null
	if aura_scene:
		var inst := aura_scene.instantiate()
		if inst is Area2D:
			aura = inst as Area2D
		else:
			return null
	else:
		aura = Area2D.new()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		aura.add_child(shape)

	aura.monitoring = true
	aura.monitorable = true
	aura.collision_layer = 0
	aura.collision_mask = 0
	aura.collision_mask = 0xFFFFFFFF # dependerá de tus layers; ajusta si usas máscaras

	# Animación si la escena tiene AnimatedSprite2D o AnimationPlayer
	var anim_sprite := aura.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.play()
	var anim_player := aura.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player:
		anim_player.play()

	# Excluir al owner y sus hijos en consultas
	var exclude: Array = [owner_node]
	for c in owner_node.get_children():
		exclude.append(c)

	if not aura.area_entered.is_connected(_on_area_or_body_entered.bind(owner_node, exclude)):
		aura.area_entered.connect(_on_area_or_body_entered.bind(owner_node, exclude))
	if not aura.body_entered.is_connected(_on_area_or_body_entered.bind(owner_node, exclude)):
		aura.body_entered.connect(_on_area_or_body_entered.bind(owner_node, exclude))

	# Lifetime
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = aura_lifetime
	t.timeout.connect(aura.queue_free)
	aura.add_child(t)
	t.autostart = true

	return aura

func _on_area_or_body_entered(other: Node, owner_node: Node, exclude: Array) -> void:
	if other == null:
		return
	if exclude.has(other):
		return
	if owner_node.has_method("is_ancestor_of") and owner_node.is_ancestor_of(other):
		return
	if owner_node.is_in_group("player") and other.is_in_group("player"):
		return

	var target := other
	if target is Area2D:
		var parent := target.get_parent()
		if parent and parent.has_method("take_damage"):
			target = parent

	# daño opcional
	if target and target.has_method("take_damage"):
		target.call("take_damage", damage, owner_node)

	# aplicar slow
	_apply_slow(target)

func _apply_slow(target: Node) -> void:
	if target == null:
		return
	var sp: Variant = null
	if target.has_method("get"):
		sp = target.get("speed")
	if sp == null:
		return
	if target.has_meta("slow_restore_speed"):
		# ya está slowed, no volver a aplicar
		return

	var tval: float = float(sp)
	var new_speed := tval * slow_pct
	target.set("speed", new_speed)
	target.set_meta("slow_restore_speed", tval)

	# Timer para restaurar
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = slow_duration
	timer.timeout.connect(func():
		if is_instance_valid(target):
			var orig: Variant = target.get_meta("slow_restore_speed")
			if orig != null:
				target.set("speed", float(orig))
				target.remove_meta("slow_restore_speed")
		timer.queue_free()
	)
	target.add_child(timer)
	timer.start()

func _has_enemy_in_radius(pos: Vector2, r: float) -> bool:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			if pos.distance_to((e as Node2D).global_position) <= r:
				return true
	return false
