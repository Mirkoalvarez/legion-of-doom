extends "res://src/components/Weapon/Weapon.gd"
class_name ProjectileWeapon

@export var projectile_scene: PackedScene
@export var damage: int = 10
@export var speed: float = 500.0
@export var lifetime: float = 1.8

func _fire(dir: Vector2, owner_node: Node) -> void:
	print("[ProjectileWeapon] _fire called dir=", dir)
	if projectile_scene == null or owner_node == null:
		push_warning("ProjectileWeapon: falta projectile_scene u owner_node")
		return
	if not (owner_node is Node2D):
		push_warning("ProjectileWeapon: owner_node no es Node2D")
		return

	var owner_2d := owner_node as Node2D
	var p := projectile_scene.instantiate()

	# Lo agregamos al MISMO padre que el player
	var container := owner_2d.get_parent()
	if container == null:
		container = owner_2d
	container.add_child(p)

	p.global_position = owner_2d.global_position
	# Tu contrato de projectile.gd: setup(dir, speed, damage, lifetime, instigator, target := null)
	p.call("setup", dir.normalized(), speed, damage, lifetime, owner_node, null)
	print("[ProjectileWeapon] spawned projectile at ", p.global_position)
