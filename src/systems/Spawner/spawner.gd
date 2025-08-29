extends Node2D

## Spawner.gd
## Instancia enemigos en posiciones aleatorias dentro de un área.

@export var enemy_scene: PackedScene
@export var spawn_area: Rect2

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
	var enemy = enemy_scene.instantiate()
	var x = randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
	var y = randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	enemy.position = Vector2(x, y)
	get_parent().add_child(enemy)
