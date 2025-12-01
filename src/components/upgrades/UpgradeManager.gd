extends Node
class_name UpgradeManager

signal upgrade_picked(id: String)

@export var upgrades: Array[Resource] = [] # UpgradeData resources

var chosen: Array = []
var db: Dictionary = {} # id -> UpgradeData

func _ready() -> void:
	_build_db()

func _build_db() -> void:
	db.clear()
	for u in upgrades:
		if u == null:
			continue
		var id_val: String = ""
		if u.has_method("get"):
			id_val = str(u.get("id"))
		if id_val == "":
			continue
		db[id_val] = u

func get_random_options(max_count: int = 3) -> Array:
	var pool: Array = []
	for u in upgrades:
		if u == null:
			continue
		var id_val: String = ""
		if u.has_method("get"):
			id_val = str(u.get("id"))
		if id_val == "":
			continue
		if chosen.has(id_val):
			continue
		pool.append(id_val)
	pool.shuffle()
	if pool.size() > max_count:
		pool.resize(max_count)
	return pool

func apply_upgrade(id: String, player: Node) -> void:
	if not db.has(id):
		return
	if chosen.has(id):
		return

	var data = db[id]

	chosen.append(id)

	if data != null:
		var effects_dict: Dictionary = {}
		if data.has_method("get"):
			var maybe = data.get("effects")
			if maybe is Dictionary:
				effects_dict = maybe
		for k_var in effects_dict.keys():
			var k: String = String(k_var)
			var any_val: Variant = effects_dict[k_var]
			_apply_effect(k, any_val, player)

	emit_signal("upgrade_picked", id)

func _apply_effect(key: String, val: Variant, player: Node) -> void:
	match key:
		"player.max_hp_add":
			var add_val: float = float(val)
			var prev_max: float = float(player.get("max_hp"))
			player.set("max_hp", prev_max + add_val)
			if player.has_method("heal"):
				player.call("heal", int(max(0.0, add_val)))

		"player.speed_mul":
			var mul: float = float(val)
			var cur: Variant = player.get("speed")
			if typeof(cur) == TYPE_INT or typeof(cur) == TYPE_FLOAT:
				player.set("speed", float(cur) * mul)

		"ranged.damage_mul":
			_for_each_ranged(player, func(w):
				var dmg: Variant = w.get("damage")
				if typeof(dmg) == TYPE_INT or typeof(dmg) == TYPE_FLOAT:
					w.set("damage", float(dmg) * float(val)))

		"ranged.cooldown_mul":
			_for_each_ranged(player, func(w):
				var cd: Variant = w.get("cooldown")
				if typeof(cd) == TYPE_INT or typeof(cd) == TYPE_FLOAT:
					w.set("cooldown", float(cd) * float(val)))

		"melee.damage_mul":
			var mw: Node = player.get("melee_weapon") as Node
			if mw:
				var dmg: Variant = mw.get("damage")
				if typeof(dmg) == TYPE_INT or typeof(dmg) == TYPE_FLOAT:
					mw.set("damage", float(dmg) * float(val))

		"detector.radius_add":
			var det: Area2D = player.get("enemy_detector") as Area2D
			if det:
				var cs: CollisionShape2D = det.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if cs and cs.shape is CircleShape2D:
					var c := cs.shape as CircleShape2D
					c.radius = c.radius + float(val)

		"magnet.radius_mul":
			var mag: Area2D = player.get_node_or_null("Magnet") as Area2D
			if mag:
				var cs: CollisionShape2D = mag.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if cs and cs.shape is CircleShape2D:
					var c := cs.shape as CircleShape2D
					c.radius = c.radius * float(val)

		_:
			pass

func _for_each_ranged(player: Node, cb: Callable) -> void:
	var list: Array[Node] = []
	if "ranged_weapon" in player and player.get("ranged_weapon"):
		list.append(player.get("ranged_weapon"))
	# paths opcionales (nuevo)
	if "extra_ranged_weapon_paths" in player:
		for p in player.get("extra_ranged_weapon_paths"):
			if p is NodePath and p != NodePath(""):
				var n := player.get_node_or_null(p) as Node
				if n:
					list.append(n)
	# compat: arrays de nodos (viejo)
	if "extra_ranged_weapons" in player:
		for rw in player.get("extra_ranged_weapons"):
			if rw:
				list.append(rw)
	for w in list:
		if w:
			cb.call(w)
