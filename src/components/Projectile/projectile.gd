extends Area2D
class_name Projectile

@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 1.8
@export_range(0.0, 1.0, 0.01) var homing_strength: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var target: Node2D = null
var instigator: Node = null  # <- renombrada (antes 'owner')
var _time_left: float

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func setup(
	dir: Vector2,
	new_speed: float,
	new_damage: int,
	new_lifetime: float,
	new_instigator: Node,
	new_target: Node2D = null
) -> void:
	direction = dir.normalized()
	speed = new_speed
	damage = new_damage
	lifetime = new_lifetime
	_time_left = lifetime
	instigator = new_instigator
	target = new_target
	visible = true
	set_physics_process(true)
	print("[Projectile] setup at ", global_position)

func _ready() -> void:
	monitoring = true
	monitorable = true
	_time_left = lifetime
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if anim:
		anim.play()

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var desired := (target.global_position - global_position).normalized()
		if homing_strength > 0.0:
			direction = direction.lerp(desired, homing_strength * delta).normalized()
	global_position += direction * speed * delta

	_time_left -= delta
	if _time_left <= 0.0:
		_despawn()

func _on_body_entered(body: Node) -> void:
	if body == instigator:
		return
	if body.is_in_group("damageable") and body.has_method("take_damage"):
		body.take_damage(damage, instigator)
		_despawn()

func _on_area_entered(area: Area2D) -> void:
	if area == self or area == instigator:
		return
	if area.is_in_group("damageable") and area.has_method("take_damage"):
		area.take_damage(damage, instigator)
		_despawn()
		return
	var p := area.get_parent()
	if p and p.is_in_group("damageable") and p.has_method("take_damage"):
		p.take_damage(damage, instigator)
		_despawn()

func _despawn() -> void:
	queue_free()  # si después haces pooling, acá cambiás por visible=false y physics off
