extends Node2D

## Spawner.gd
## Instancia enemigos en posiciones aleatorias dentro de un área.

@export var enemy_scene: PackedScene
@export var spawn_area: Rect2
@export var min_distance: float = 200.0

var _timer: Timer = Timer.new()

func _ready() -> void:
	_timer.wait_time = 1.0
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

func _on_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var spawn_pos := Vector2.ZERO
	var attempts := 0
	var valid := false
	while attempts < 10 and not valid:
		var x = randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
		var y = randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
		spawn_pos = Vector2(x, y)
		if player == null or spawn_pos.distance_to(player.global_position) >= min_distance:
			valid = true
		else:
			attempts += 1
	if not valid:
		return

	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	get_parent().add_child(enemy)
