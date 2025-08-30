# scenes/actors/player/enemy_detector.gd
extends Area2D

var target: Node2D = null

func _ready() -> void:
	monitoring = true
	monitorable = true

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		target = body

func _on_body_exited(body):
	if body == target:
		target = null
		for other in get_overlapping_bodies():
			if other.is_in_group("enemy"):
				target = other
				break

func get_target() -> Node2D:
	if target and not is_instance_valid(target):
		target = null
	if target == null:
		for other in get_overlapping_bodies():
			if other.is_in_group("enemy"):
				target = other
				break
	return target
