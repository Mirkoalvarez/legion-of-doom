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

func _on_body_entered(body: Node) -> void:
	# Aplica daño si el objetivo lo soporta
	if body.has_method("take_damage"):
		body.take_damage(damage)

		# Knockback (empuje) opcional
		if knockback > 0.0 and body is CharacterBody2D:
			var dir: Vector2 = (body.global_position - global_position).normalized()
			body.velocity += dir * knockback

	emit_signal("hit", body)

	if one_shot:
		queue_free()
