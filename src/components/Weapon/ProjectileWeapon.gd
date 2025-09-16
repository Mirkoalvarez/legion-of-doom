# res://src/components/Weapon/ProjectileWeapon.gd
extends "res://src/components/Weapon/Weapon.gd"
class_name ProjectileWeapon

@export var projectile_scene: PackedScene
@export var damage: int = 10
@export var speed: float = 500.0
@export var lifetime: float = 1.8

# referencia al player de audio dentro del ProjectileWeapon (no 2D)
@export var fire_player_path: NodePath = NodePath("SFX_Fire")  # poné el nombre real del nodo
@export var fire_volume_db: float = 0.0                        # ajustá si queda bajo

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
	var base := get_node_or_null(fire_player_path) as AudioStreamPlayer
	if base == null or base.stream == null:
		return
	var one_shot := base.duplicate() as AudioStreamPlayer   # permite solapar sonidos
	one_shot.volume_db = fire_volume_db
	#one_shot.volume_db = -24.0
	get_tree().current_scene.add_child(one_shot)
	one_shot.play()
	one_shot.finished.connect(one_shot.queue_free)
