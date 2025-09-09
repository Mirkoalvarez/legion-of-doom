extends Area2D
class_name HealthPickup

@export var heal_amount: int = 15

func _ready() -> void:
	# Evita “Function blocked during in/out signal”
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_area_entered(a: Area2D) -> void:
	var p: Node = a.get_parent()
	if p != null and p.is_in_group("player"):
		_give_to(p)

func _on_body_entered(b: Node) -> void:
	if b != null and b.is_in_group("player"):
		_give_to(b)

func _give_to(node: Node) -> void:
	if node.has_method("heal"):
		node.call("heal", heal_amount)
	queue_free()
