extends Node
class_name HealthComponent

signal died
signal damaged(amount: float)

@export var max_health: float = 100.0
var health: float

func _ready() -> void:
	health = max_health

func apply_damage(amount: float, _source: Node = null) -> void:
	if amount <= 0.0: return
	health = max(0.0, health - amount)
	damaged.emit(amount)
	if health <= 0.0:
		died.emit()
