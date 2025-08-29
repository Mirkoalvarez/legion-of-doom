extends Area2D
##
## Hitbox.gd — área que hace daño al cuerpo que entra
##

@export var damage: int = 10
@export var one_shot: bool = false   # se destruye tras golpear
@export var knockback: float = 0.0   # empuje simple si el objetivo es CharacterBody2D

signal hit(body: Node)

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _apply_damage(target: Node) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
		
		# Knockback (empuje) opcional
		if knockback > 0.0 and target is CharacterBody2D:
			var dir: Vector2 = (target.global_position - global_position).normalized()
			target.velocity += dir * knockback

	emit_signal("hit", target)

	if one_shot:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_apply_damage(body)

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hurtbox"):
		return
	var target: Node = area
	var parent: Node = area.get_parent()
	if not target.has_method("take_damage") and parent and parent.has_method("take_damage"):
		target = parent
	_apply_damage(target)
