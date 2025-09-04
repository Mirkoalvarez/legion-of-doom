extends Node
class_name Weapon

signal fired

@export var cooldown: float = 0.4
var _can_fire: bool = true

func try_fire(dir: Vector2, owner_node: Node) -> void:
	if not _can_fire: return
	_can_fire = false
	print("[Weapon] try_fire dir=", dir, " owner=", owner_node.name)
	_fire(dir, owner_node)
	fired.emit()
	await get_tree().create_timer(cooldown).timeout
	_can_fire = true

func _fire(_dir: Vector2, _owner_node: Node) -> void:
	# Implementan las subclases
	pass
