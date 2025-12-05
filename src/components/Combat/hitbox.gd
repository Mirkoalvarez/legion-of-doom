extends Area2D

@export var damage: int = 10
@export var one_shot: bool = false
@export var knockback: float = 0.0
@export var instigator: Node = null
signal hit(body: Node)

func _ready() -> void:
	monitoring = true
	monitorable = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _apply_damage(target: Node) -> void:
	# Evitar fuego amigo
	if instigator:
		if target == instigator:
			return
		if instigator.has_method("is_ancestor_of") and instigator.is_ancestor_of(target):
			return

	if target and target.has_method("take_damage"):
		target.take_damage(damage, self)

		# Knockback (solo si el objetivo es un CharacterBody2D)
		if knockback > 0.0 and target is CharacterBody2D:
			var dir: Vector2 = (target.global_position - global_position).normalized()
			(target as CharacterBody2D).velocity += dir * knockback

	emit_signal("hit", target)

	if one_shot:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == instigator:
		return
	if instigator and instigator.has_method("is_ancestor_of") and instigator.is_ancestor_of(body):
		return
	_apply_damage(body)

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hurtbox"):
		return

	var target: Node = area
	var parent: Node = area.get_parent()
	if not target.has_method("take_damage") and parent and parent.has_method("take_damage"):
		target = parent

	_apply_damage(target)

func _on_hit(_body: Node) -> void:
	pass # Replace with function body.
