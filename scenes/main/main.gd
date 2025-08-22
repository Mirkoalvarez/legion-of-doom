extends Node2D

func _process(_dt):
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	)
	if dir.length() > 0:
		print("Input dir: ", dir.normalized())
