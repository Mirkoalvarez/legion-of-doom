extends Node
class_name Experience

signal xp_changed(current_xp: int, needed: int, level: int)
signal level_up(new_level: int)

@export var level: int = 1
@export var current_xp: int = 0
@export var xp_table: Array[int] = [0, 50, 120, 200, 290, 390]
@export var rewards_by_level: Dictionary = {
	2: {"heal": 10},
	3: {"stat": "speed", "delta": 10},
	4: {"stat": "projectile_damage", "delta": 5}
}

func _ready() -> void:
	emit_signal("xp_changed", current_xp, _xp_needed_for(level), level)

func add_xp(amount: int) -> void:
	if amount <= 0: return
	current_xp += amount
	while current_xp >= _xp_needed_for(level):
		_level_up()
	emit_signal("xp_changed", current_xp, _xp_needed_for(level), level)

func _level_up() -> void:
	level += 1
	emit_signal("level_up", level)
	_apply_rewards_for(level)

func _apply_rewards_for(lv: int) -> void:
	if not rewards_by_level.has(lv): return
	var r: Dictionary = rewards_by_level[lv]
	var player: Node = get_parent()
	if player == null: return

	if r.has("heal") and player.has_method("heal"):
		var heal_val: int = int(r["heal"])
		player.heal(heal_val)

	if r.has("stat") and r.has("delta"):
		var stat_name: String = str(r["stat"])
		var delta: int = int(r["delta"])
		if player.has_variable(stat_name):
			var v: Variant = player.get(stat_name)
			if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
				player.set(stat_name, float(v) + delta)

func _xp_needed_for(lv: int) -> int:
	if lv < xp_table.size():
		return int(xp_table[lv])
	if xp_table.size() >= 2:
		var last: int = int(xp_table[xp_table.size() - 1])
		var prev: int = int(xp_table[xp_table.size() - 2])
		var step: int = max(1, last - prev)
		return last + step * int(lv - (xp_table.size() - 1))
	return 50

func to_dict() -> Dictionary:
	return {"level": level, "current_xp": current_xp}

func from_dict(d: Dictionary) -> void:
	level = int(d.get("level", level))
	current_xp = int(d.get("current_xp", current_xp))
	emit_signal("xp_changed", current_xp, _xp_needed_for(level), level)
