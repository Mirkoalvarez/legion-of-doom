# res://src/ui/HUD_Health.gd
extends Control
class_name HUD_Health

@export var player_path: NodePath
var _player: Node = null

@onready var _bar: ProgressBar = $HPBar
@onready var _txt: Label = $HPText

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path)
	else:
		# intenta buscar en la escena principal
		_player = get_tree().get_first_node_in_group("player")

	if _player != null and _player.has_signal("hp_changed"):
		_player.connect("hp_changed", Callable(self, "_on_hp_changed"))
		# estado inicial si existen propiedades
		if "hp" in _player and "max_hp" in _player:
			_on_hp_changed(int(_player.get("hp")), int(_player.get("max_hp")))
	else:
		_bar.max_value = 1
		_bar.value = 0
		_txt.text = "0 / 1"

func _on_hp_changed(cur: int, mx: int) -> void:
	_bar.max_value = max(1, mx)
	_bar.value = clamp(cur, 0, _bar.max_value)
	_txt.text = str(cur) + " / " + str(mx)
