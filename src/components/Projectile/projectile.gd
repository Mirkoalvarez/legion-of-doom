extends Area2D
class_name Projectile

@export var speed: float = 400.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var target: Node2D = null
@onready var anim: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if anim:
		anim.play()

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		var enemy = area
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		elif area.get_parent() and area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(damage)
		queue_free()
