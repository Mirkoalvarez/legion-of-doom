extends Area2D
class_name Projectile

@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 1.8
@export_range(0.0, 1.0, 0.01) var homing_strength: float = 0.0
@export var knockback: float = 220.0

var direction: Vector2 = Vector2.RIGHT
var target: Node2D = null
var instigator: Node = null
var _time_left: float
var _hit: bool = false

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func setup(dir: Vector2, new_speed: float, new_damage: int, new_lifetime: float, new_instigator: Node, new_target: Node2D = null) -> void:
	direction = dir.normalized()
	speed = new_speed
	damage = new_damage
	lifetime = new_lifetime
	_time_left = lifetime
	instigator = new_instigator
	target = new_target
	visible = true
	set_physics_process(true)

	if anim:
		anim.rotation = direction.angle()

func _ready() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if anim:
		anim.play()

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var desired: Vector2 = (target.global_position - global_position).normalized()
		if homing_strength > 0.0:
			direction = direction.lerp(desired, homing_strength * delta).normalized()
	global_position += direction * speed * delta

	_time_left -= delta
	if _time_left <= 0.0:
		_despawn()

func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	if area == self or area == instigator:
		return
	if not area.is_in_group("hurtbox"):
		return

	var dmg_target: Node = area
	var parent_node: Node = area.get_parent()
	if not dmg_target.has_method("take_damage") and parent_node and parent_node.has_method("take_damage"):
		dmg_target = parent_node

	# Avoid friendly fire: skip if instigator is self or ancestor (hurtbox), or same player group
	if instigator:
		if dmg_target == instigator:
			return
		if instigator.has_method("is_ancestor_of") and instigator.is_ancestor_of(dmg_target):
			return
		if instigator.is_in_group("player") and dmg_target.is_in_group("player"):
			return

	_hit = true
	# Pass self as source for knockback reading
	dmg_target.call("take_damage", damage, self)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	call_deferred("_despawn")

func _despawn() -> void:
	queue_free()
