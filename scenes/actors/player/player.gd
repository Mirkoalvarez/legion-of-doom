extends CharacterBody2D

@export var speed := 260.0
@export var max_hp := 100
var hp := 100

func _ready() -> void:
	hp = max_hp
	add_to_group("player")

func _physics_process(_dt: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

	velocity = dir * speed
	move_and_slide()
