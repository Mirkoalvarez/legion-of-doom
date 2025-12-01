extends Weapon
class_name MeleeWeapon

@export var swing_scene: PackedScene        # arrastrá sword_player.tscn (con Hitbox.gd)
@export var damage: int = 20
@export var range_px: float = 64
@export var knockback: float = 180
@export var swing_lifetime: float = 0.15

# Parámetros del movimiento visual
@export var arc_degrees: float = 90.0       # amplitud del arco
@export var lead_fraction: float = 0.15     # “empujón” hacia adelante (0..0.3 aprox)

func _fire(dir: Vector2, owner_node: Node) -> void:
	if swing_scene == null or owner_node == null or not (owner_node is Node2D):
		return

	var owner2d := owner_node as Node2D
	var swing := swing_scene.instantiate()
	owner2d.add_child(swing)

	# posición base delante del player
	var out: Vector2 = dir.normalized() * range_px
	(swing as Node2D).global_position = owner2d.global_position + out
	(swing as Node2D).rotation = dir.angle()
	if swing is CanvasItem:
		(swing as CanvasItem).z_index = 20

	# pasar daño/knockback al hitbox (Enemy lo lee de 'source')
	if "damage" in swing: swing.set("damage", damage)
	if "knockback" in swing: swing.set("knockback", knockback)

	#Sonido de SWORD
	var sfx := get_node_or_null("SFX_Sword") as AudioStreamPlayer2D
	if sfx:
		# clonar para permitir solapamiento de sonidos
		var one_shot := sfx.duplicate() as AudioStreamPlayer2D
		one_shot.global_position = (owner_node as Node2D).global_position
		get_parent().add_child(one_shot)
		one_shot.play()
		one_shot.finished.connect(one_shot.queue_free)


	# ---------- ANIMACIÓN DEL SWING ----------
	var half_arc: float = deg_to_rad(arc_degrees) * 0.9
	var start_rot: float = dir.angle() - half_arc
	var end_rot: float = dir.angle() + half_arc

	var start_pos: Vector2 = (swing as Node2D).global_position - dir.normalized() * (range_px * lead_fraction)
	var end_pos: Vector2 = (swing as Node2D).global_position + dir.normalized() * (range_px * lead_fraction)

	(swing as Node2D).global_position = start_pos
	(swing as Node2D).rotation = start_rot

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(swing, "rotation", end_rot, swing_lifetime)
	tw.parallel().tween_property(swing, "global_position", end_pos, swing_lifetime)

	# ---------- VENTANA ACTIVA / LIFE ----------
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = swing_lifetime
	t.timeout.connect(swing.queue_free)
	swing.add_child(t)
	t.start()
