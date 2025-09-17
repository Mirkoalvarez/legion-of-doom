extends Node
class_name UpgradeManager

signal upgrade_picked(id: String)

# historial de upgrades elegidos (IDs únicas)
var chosen: Array[String] = []

# base de datos (IDs -> meta)
var db: Dictionary = {
	# --- MAGIA ---
	"magic_nova": {
		"branch": "MAGIA",
		"name": "Nova de energía",
		"desc": "Crea una onda de daño alrededor del jugador (habilidad activa).",
		"type": "active"
	},
	"magic_slow_curse": {
		"branch": "MAGIA",
		"name": "Maldición de ralentización",
		"desc": "Los enemigos cerca del jugador se mueven más lento.",
		"type": "passive",
		"effect": {"slow_radius": 160.0, "slow_pct": 0.25}
	},
	"magic_range_up": {
		"branch": "MAGIA",
		"name": "Aumento de alcance mágico",
		"desc": "+25% alcance de proyectiles.",
		"type": "stat",
		"effect": {"ranged.range_mul": 1.25}
	},
	"magic_summon_temp": {
		"branch": "MAGIA",
		"name": "Invocación temporal",
		"desc": "Invoca un aliado temporal.",
		"type": "active"
	},

	# --- COMBATE ---
	"melee_aoe": {
		"branch": "COMBATE",
		"name": "Golpe de zona",
		"desc": "El ataque melee pega en área.",
		"type": "flag",
		"effect": {"melee.aoe": true}
	},
	"melee_charge": {
		"branch": "COMBATE",
		"name": "Carga con espada",
		"desc": "Dash ofensivo que empuja a los enemigos.",
		"type": "active"
	},
	"defense_reduce_damage": {
		"branch": "COMBATE",
		"name": "Reducción de daño",
		"desc": "-20% daño recibido.",
		"type": "stat",
		"effect": {"player.damage_taken_mul": 0.8}
	},
	"melee_attack_speed_up": {
		"branch": "COMBATE",
		"name": "Aumento de velocidad de ataque",
		"desc": "+15% velocidad de ataque melee.",
		"type": "stat",
		"effect": {"melee.cooldown_mul": 0.85}
	}
}

func get_random_options(max_count: int = 3) -> Array[String]:
	var pool: Array[String] = []
	for k in db.keys():
		var id: String = String(k)
		if not chosen.has(id):
			pool.append(id)
	pool.shuffle()
	if pool.size() > max_count:
		pool.resize(max_count)
	return pool

func apply_upgrade(id: String, player: Node) -> void:
	if not db.has(id):
		return
	if chosen.has(id):
		return

	chosen.append(id)

	var meta: Dictionary = db[id] as Dictionary
	var effect: Dictionary = {}
	if meta.has("effect"):
		effect = meta["effect"] as Dictionary

	for k_var in effect.keys():
		var k: String = String(k_var)
		# Tomamos el valor y lo casteamos según el tipo esperado
		var any_val: Variant = effect[k]

		match k:
			"player.damage_taken_mul":
				var mul: float = 1.0
				if typeof(any_val) == TYPE_INT or typeof(any_val) == TYPE_FLOAT:
					mul = float(any_val)
				var cur_mul: float = 1.0
				if player.has_meta("damage_taken_mul"):
					cur_mul = float(player.get_meta("damage_taken_mul"))
				player.set_meta("damage_taken_mul", cur_mul * mul)

			"ranged.range_mul":
				var mul_ranged: float = 1.0
				if typeof(any_val) == TYPE_INT or typeof(any_val) == TYPE_FLOAT:
					mul_ranged = float(any_val)
				var rw: Node = player.get("ranged_weapon") as Node
				if rw != null:
					var prop_val: Variant = rw.get("range_px")
					if typeof(prop_val) == TYPE_INT or typeof(prop_val) == TYPE_FLOAT:
						var new_range: float = float(prop_val) * mul_ranged
						rw.set("range_px", new_range)

			"melee.cooldown_mul":
				var mul_cd: float = 1.0
				if typeof(any_val) == TYPE_INT or typeof(any_val) == TYPE_FLOAT:
					mul_cd = float(any_val)
				var mw: Node = player.get("melee_weapon") as Node
				if mw != null:
					var cd_val: Variant = mw.get("cooldown")
					if typeof(cd_val) == TYPE_INT or typeof(cd_val) == TYPE_FLOAT:
						var new_cd: float = float(cd_val) * mul_cd
						mw.set("cooldown", new_cd)

			"melee.aoe":
				var flag_aoe: bool = bool(any_val)
				player.set_meta("melee_aoe", flag_aoe)

	emit_signal("upgrade_picked", id)
