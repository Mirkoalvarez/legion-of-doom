extends Area2D
class_name StatPickup

@export_enum("player.speed", "player.max_hp", "ranged.damage") var target_stat: String = "player.speed"
@export var delta: float = 10.0
@export var duration: float = 0.0   # 0 = permanente; >0 = temporal (segundos)

func _ready() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_area_entered(a: Area2D) -> void:
	var p: Node = a.get_parent()
	if p != null and p.is_in_group("player"):
		_apply_to(p)

func _on_body_entered(b: Node) -> void:
	if b != null and b.is_in_group("player"):
		_apply_to(b)

func _apply_to(player: Node) -> void:
	match target_stat:
		"player.speed":
			_apply_player_numeric(player, "speed", delta, duration)
		"player.max_hp":
			var before: float = float(player.get("max_hp"))
			_apply_player_numeric(player, "max_hp", delta, duration)
			if player.has_method("heal"):
				var inc: int = int(max(0.0, float(player.get("max_hp")) - before))
				if inc > 0: player.call("heal", inc)
		"ranged.damage":
			_apply_ranged_damage(player, delta, duration)
		_:
			pass

	queue_free()

func _apply_player_numeric(player: Node, prop: String, amount: float, dur: float) -> void:
	var cur: Variant = player.get(prop)
	var t: int = typeof(cur)
	if t == TYPE_INT or t == TYPE_FLOAT:
		player.set(prop, float(cur) + amount)
		if dur > 0.0:
			var timer := get_tree().create_timer(dur) # <- SceneTreeTimer, no se borra con el pickup
			timer.timeout.connect(func():
				if is_instance_valid(player):
					var back: Variant = player.get(prop)
					var t2: int = typeof(back)
					if t2 == TYPE_INT or t2 == TYPE_FLOAT:
						player.set(prop, float(back) - amount))

func _apply_ranged_damage(player: Node, amount: float, dur: float) -> void:
	var rw: Node = null
	if "ranged_weapon" in player:
		rw = player.get("ranged_weapon") as Node
	if rw == null:
		return

	var cur: Variant = rw.get("damage")
	var t: int = typeof(cur)
	if t != TYPE_INT and t != TYPE_FLOAT:
		return

	rw.set("damage", float(cur) + amount)

	if dur > 0.0:
		var timer := get_tree().create_timer(dur) # <- SceneTreeTimer
		timer.timeout.connect(func():
			if is_instance_valid(rw):
				var back: Variant = rw.get("damage")
				var t2: int = typeof(back)
				if t2 == TYPE_INT or t2 == TYPE_FLOAT:
					rw.set("damage", float(back) - amount))
