extends Area2D
class_name XPOrb

@export var xp_amount: int = 10
@export var magnet_shrink_scale: float = 0.8
@export var shrink_collision_on_magnet: bool = true

var _magnetized: bool = false
var _orig_shape_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Activación de físicas diferida para evitar "Function blocked during in/out signal"
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		_orig_shape_size = (cs.shape as RectangleShape2D).size
	elif cs and cs.shape is CircleShape2D:
		var r: float = (cs.shape as CircleShape2D).radius
		_orig_shape_size = Vector2(r, r)

func _try_give_to(node: Node) -> void:
	if node == null: 
		return
	var experience: Experience = node.get_node_or_null("Experience") as Experience
	if experience == null and node.get_parent() != null:
		experience = node.get_parent().get_node_or_null("Experience") as Experience
	if experience != null:
		experience.add_xp(xp_amount)
		queue_free()

func _on_area_entered(a: Area2D) -> void:
	var p: Node = a.get_parent()
	if p != null and p.is_in_group("player"):
		_try_give_to(p)
		return
	if (a.name == "Magnet") or a.is_in_group("magnet"):
		_on_enter_magnet()

func _on_body_entered(b: Node) -> void:
	if b != null and b.is_in_group("player"):
		_try_give_to(b)

func _on_enter_magnet() -> void:
	if _magnetized: return
	_magnetized = true

	if shrink_collision_on_magnet:
		var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs and cs.shape is RectangleShape2D:
			var rect := cs.shape as RectangleShape2D
			rect.size = rect.size * 0.8
		elif cs and cs.shape is CircleShape2D:
			var circ := cs.shape as CircleShape2D
			circ.radius = circ.radius * 0.8

	if magnet_shrink_scale < 1.0:
		var tw: Tween = create_tween()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE * magnet_shrink_scale, 0.1)
