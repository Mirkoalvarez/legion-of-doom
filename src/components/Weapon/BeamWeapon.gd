extends "res://src/components/Weapon/Weapon.gd"
class_name BeamWeapon

@export var beam_scene: PackedScene              # escena visual del rayo (Area2D + AnimatedSprite2D)
@export var damage: int = 20
@export var range_px: float = 240.0              # hasta dónde alcanza el rayo
@export var lifetime: float = 0.18               # cuánto tiempo se mantiene visible
@export var use_fixed_direction: bool = false    # si true, la rotación visual usa fixed_direction
@export var fixed_direction: Vector2 = Vector2.RIGHT
@export var override_visual_rotation: bool = false  # si true, fuerza un ángulo visual fijo
@export var visual_rotation_degrees: float = 0.0     # ángulo fijo del sprite
@export var sfx_player_path: NodePath = NodePath("SFX_Beam") # hijo con AudioStreamPlayer
@export var auto_only: bool = true  # si true, no dispara en input manual

func _fire(dir: Vector2, owner_node: Node) -> void:
	if beam_scene == null or owner_node == null:
		return
	var fire_dir := dir
	if fire_dir == Vector2.ZERO:
		fire_dir = fixed_direction if fixed_direction != Vector2.ZERO else Vector2.RIGHT
	fire_dir = fire_dir.normalized()

	var rotation_dir := fire_dir
	if use_fixed_direction and fixed_direction != Vector2.ZERO:
		rotation_dir = fixed_direction.normalized()

	var owner2d := owner_node as Node2D
	if owner2d == null:
		return

	var start: Vector2 = owner2d.global_position
	var end: Vector2 = start + fire_dir * range_px

	# --- RAYCAST: busca primer objetivo en la dirección
	var hit_pos: Vector2 = end
	var target: Node = null

	var space: PhysicsDirectSpaceState2D = owner2d.get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(start, end)
	var exclude: Array = [owner_node]
	for c in owner_node.get_children():
		exclude.append(c)
	params.exclude = exclude
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var res: Dictionary = space.intersect_ray(params)
	if not res.is_empty():
		hit_pos = res.position
		var col: Variant = res.collider
		if col is Node:
			target = col
			# si el collider no tiene take_damage, intenta con su padre (útil para hurtbox Area2D)
			if not target.has_method("take_damage") and target.get_parent() and target.get_parent().has_method("take_damage"):
				target = target.get_parent()

	# --- Aplica daño si corresponde
	if target and target.has_method("take_damage"):
		# Evitar fuego amigo: no dañar al owner ni a sus hijos, ni al mismo grupo player
		var skip := false
		if target == owner_node:
			skip = true
		elif owner_node.has_method("is_ancestor_of") and owner_node.is_ancestor_of(target):
			skip = true
		elif owner_node.is_in_group("player") and target.is_in_group("player"):
			skip = true

		if not skip:
			target.call("take_damage", damage, owner_node)

	# --- SFX ---
	_play_sfx(owner_node)

	# --- Instancia el rayo visual en el punto de impacto
	var beam := beam_scene.instantiate() as Node2D
	owner_node.get_parent().add_child(beam)
	beam.global_position = hit_pos
	var rotation_angle := rotation_dir.angle()
	if override_visual_rotation:
		rotation_angle = deg_to_rad(visual_rotation_degrees)
	beam.rotation = rotation_angle

	# Timer para borrar el rayo
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = lifetime
	t.timeout.connect(beam.queue_free)
	beam.add_child(t)
	t.start()

func _play_sfx(owner_node: Node) -> void:
	# Busca primero en este nodo (weapon), luego en el owner
	var base: Node = get_node_or_null(sfx_player_path)
	if base == null and owner_node:
		base = owner_node.get_node_or_null(sfx_player_path)

	if base == null:
		return

	if base is AudioStreamPlayer:
		var dup := (base as AudioStreamPlayer).duplicate() as AudioStreamPlayer
		dup.bus = base.bus
		dup.volume_db = base.volume_db
		dup.pitch_scale = base.pitch_scale
		owner_node.get_parent().add_child(dup)
		dup.play()
		dup.finished.connect(dup.queue_free)
	elif base is AudioStreamPlayer2D:
		var dup2 := (base as AudioStreamPlayer2D).duplicate() as AudioStreamPlayer2D
		dup2.bus = base.bus
		dup2.volume_db = base.volume_db
		dup2.pitch_scale = base.pitch_scale
		dup2.global_position = (base as AudioStreamPlayer2D).global_position
		owner_node.get_parent().add_child(dup2)
		dup2.play()
		dup2.finished.connect(dup2.queue_free)
