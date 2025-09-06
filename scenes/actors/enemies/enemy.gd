extends CharacterBody2D

@export var speed: float = 90.0
@export var max_hp: int = 20
@export var knockback_resistance: float = 0.0  # 0..1
@export var xp_orb_scene: PackedScene
@export var xp_drop: int = 10

var hp: int
var player: Node2D

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_dt: float) -> void:
	if player and is_instance_valid(player):
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()

func take_damage(amount: int, source: Node = null) -> void:
	hp -= amount

	# Knockback opcional (lee 'knockback' desde la FUENTE del daño)
	if source is Node2D and knockback_resistance < 1.0:
		var kb: float = 0.0
		# leer como Variant y castear explícito
		if "knockback" in source:
			var any: Variant = source.get("knockback")
			if typeof(any) == TYPE_INT or typeof(any) == TYPE_FLOAT:
				kb = float(any)

		if kb > 0.0:
			var from: Vector2 = (source as Node2D).global_position
			var dir: Vector2 = (global_position - from).normalized()
			velocity += dir * kb * (1.0 - clamp(knockback_resistance, 0.0, 1.0))

	if hp <= 0:
		_die()

func _die() -> void:
	if xp_orb_scene != null:
		var orb: Node2D = xp_orb_scene.instantiate() as Node2D
		get_parent().add_child(orb)
		orb.global_position = global_position
		if orb.has_method("set") and "xp_amount" in orb:
			orb.set("xp_amount", xp_drop)
	queue_free()
