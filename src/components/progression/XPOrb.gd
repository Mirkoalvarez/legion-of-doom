# res://src/progression/XPOrb.gd
extends Area2D
class_name XPOrb

@export var xp_amount: int = 10

func _ready() -> void:
	monitoring = true
	monitorable = true
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _try_give_to(node: Node) -> void:
	if node == null: 
		return
	var exp: Experience = node.get_node_or_null("Experience") as Experience
	if exp == null and node.get_parent() != null:
		exp = node.get_parent().get_node_or_null("Experience") as Experience
	if exp != null:
		exp.add_xp(xp_amount)
		queue_free()

func _on_area_entered(a: Area2D) -> void:
	var p: Node = a.get_parent()
	if p != null and p.is_in_group("player"):
		_try_give_to(p)

func _on_body_entered(b: Node) -> void:
	if b != null and b.is_in_group("player"):
		_try_give_to(b)
