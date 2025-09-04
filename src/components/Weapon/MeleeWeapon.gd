extends Weapon
class_name MeleeWeapon

@export var swing_scene: PackedScene
@export var damage: float = 20.0
@export var range_px: float = 36.0
@export var knockback: float = 180.0
@export var swing_lifetime: float = 0.15

func _fire(dir: Vector2, owner_node: Node) -> void:
	if not swing_scene: return
	var swing := swing_scene.instantiate()
	owner_node.get_parent().add_child(swing)
	swing.global_position = owner_node.global_position + dir.normalized() * range_px
	swing.rotation = dir.angle()

	# conectamos hit
	swing.connect("body_entered", Callable(self, "_on_swing_hit").bind(owner_node))
	# vida corta
	await get_tree().create_timer(swing_lifetime).timeout
	if is_instance_valid(swing):
		swing.queue_free()

func _on_swing_hit(body: Node, owner_node: Node) -> void:
	if body.is_in_group("damageable") and body.has_method("take_damage"):
		body.take_damage(damage, owner_node)
		# knockback si el body tiene física
		if "velocity" in body:
			var push = (body.global_position - owner_node.global_position).normalized() * knockback
			body.velocity += push
