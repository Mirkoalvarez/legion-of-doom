extends Area2D
##
## Hurtbox.gd — receptor de daño, escucha hitboxes rivales
##

signal hurt(amount: int)

func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var dmg: int = _extract_damage_from_attacker(area)
	if dmg > 0:
		print("Hurtbox recibió daño (área): ", dmg)
		emit_signal("hurt", dmg)

func _on_body_entered(body: Node) -> void:
	var dmg: int = _extract_damage_from_attacker(body)
	if dmg > 0:
		print("Hurtbox recibió daño (cuerpo): ", dmg)
		emit_signal("hurt", dmg)

func _extract_damage_from_attacker(attacker: Object) -> int:
	var dmg: int = 0

	# Caso propiedad exportada "damage"
	if "damage" in attacker and attacker.damage != null:
		if typeof(attacker.damage) == TYPE_INT:
			dmg = attacker.damage
		elif typeof(attacker.damage) == TYPE_FLOAT:
			dmg = int(attacker.damage)

	# Caso método get_damage()
	elif attacker.has_method("get_damage"):
		var val = attacker.get_damage()
		if val != null:
			if typeof(val) == TYPE_INT:
				dmg = val
			elif typeof(val) == TYPE_FLOAT:
				dmg = int(val)

	return max(dmg, 0)
