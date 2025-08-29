# scenes/actors/player/enemy_detector.gd
extends Area2D

var target: Node2D = null

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		target = body

func _on_body_exited(body):
	if body == target:
		target = null

func get_target() -> Node2D:
	return target
