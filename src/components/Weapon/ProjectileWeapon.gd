# res://src/components/Weapon/ProjectileWeapon.gd
extends "res://src/components/Weapon/Weapon.gd"
class_name ProjectileWeapon

@export var projectile_scene: PackedScene
@export var damage: int = 10
@export var speed: float = 500.0
@export var lifetime: float = 1.8
@export var knockback: float = 220.0 

# referencia al player de audio dentro del ProjectileWeapon (no 2D)
@export var fire_player_path: NodePath = NodePath("SFX_Fire")
@export var fire_volume_db: float = 0.0

func _fire(dir: Vector2, owner_node: Node) -> void:
	if projectile_scene == null or owner_node == null:
		return

	# 1) instanciar proyectil
	var p := projectile_scene.instantiate()
	owner_node.get_parent().add_child(p)
	(p as Node2D).global_position = (owner_node as Node2D).global_position
	p.call("setup", dir.normalized(), speed, damage, lifetime, owner_node, null)

	# 2) reproducir SFX (global, no posicional)
	_play_fire_sfx_global()

func _play_fire_sfx_global() -> void:
	var n := get_node_or_null(fire_player_path)
	if n == null:
		return
	if n is AudioStreamPlayer:
		var base := n as AudioStreamPlayer
		if base.stream == null:
			return
		var one_shot := base.duplicate() as AudioStreamPlayer   # permite solapar sonidos
		one_shot.bus = base.bus
		one_shot.volume_db = base.volume_db + fire_volume_db
		one_shot.pitch_scale = base.pitch_scale
		get_tree().current_scene.add_child(one_shot)
		one_shot.play()
		one_shot.finished.connect(one_shot.queue_free)
	elif n is AudioStreamPlayer2D:
		var base2 := n as AudioStreamPlayer2D
		if base2.stream == null:
			return
		var one_shot2 := base2.duplicate() as AudioStreamPlayer2D
		one_shot2.bus = base2.bus
		one_shot2.volume_db = base2.volume_db + fire_volume_db
		one_shot2.pitch_scale = base2.pitch_scale
		one_shot2.global_position = base2.global_position
		get_tree().current_scene.add_child(one_shot2)
		one_shot2.play()
		one_shot2.finished.connect(one_shot2.queue_free)
