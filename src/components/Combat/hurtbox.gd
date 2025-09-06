extends Area2D
signal hurt(amount: int)

@export var forward_to_parent: NodePath = NodePath("..")  # a quién reenvío el daño

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("hurtbox") # <- CLAVE para que hitboxes/proyectiles te detecten

func take_damage(amount: int, source: Node = null) -> void:
	var target := get_node_or_null(forward_to_parent) # Node | null
	if target and target.has_method("take_damage"):
		# Usamos call para tolerar tanto take_damage(amount) como take_damage(amount, source)
		target.call("take_damage", amount, source)
	emit_signal("hurt", amount) # opcional (HUD/SFX)


func _on_hurt(_amount: int) -> void:
	pass # Replace with function body.
