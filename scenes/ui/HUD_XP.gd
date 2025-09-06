extends Control
class_name HUD_XP

@export var experience_path: NodePath
var experience_node: Experience

@onready var _level_label: Label = $LevelLabel
@onready var _xp_bar: ProgressBar = $XPBar
@onready var _xp_text: Label = $XPText

func _ready() -> void:
	# obtener Experience de forma segura
	if experience_path != NodePath(""):
		var node: Node = get_node_or_null(experience_path)
		experience_node = node as Experience
	else:
		# fallback: buscar hijo llamado "Experience" en la escena (si el HUD está como hijo del Player o similar)
		var maybe: Node = get_node_or_null("../Experience")
		experience_node = maybe as Experience

	if experience_node != null:
		if not experience_node.xp_changed.is_connected(_on_xp_changed):
			experience_node.xp_changed.connect(_on_xp_changed)
		if not experience_node.level_up.is_connected(_on_level_up):
			experience_node.level_up.connect(_on_level_up)
		# sync inicial
		var need: int = experience_node._xp_needed_for(experience_node.level)
		_on_xp_changed(experience_node.current_xp, need, experience_node.level)
	else:
		# HUD sin fuente de datos: proteger UI
		_level_label.text = "Lv ?"
		_xp_bar.max_value = 1
		_xp_bar.value = 0
		_xp_text.text = "0 / 1"

func _on_xp_changed(cur: int, need: int, lvl: int) -> void:
	_level_label.text = "Lv " + str(lvl)
	_xp_bar.max_value = max(1, need)
	_xp_bar.value = clamp(cur, 0, _xp_bar.max_value)
	_xp_text.text = str(cur) + " / " + str(need)

func _on_level_up(_lvl: int) -> void:
	# anim/SFX opcional
	pass
