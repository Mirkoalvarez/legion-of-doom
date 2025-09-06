# res://src/ui/HealthBar2D.gd
extends Node2D
class_name HealthBar2D

@export var target_path: NodePath          # arrastrá Player o Enemy
@export var offset: Vector2 = Vector2(0, -24)
@export var hide_when_full: bool = true

@onready var _bar: ProgressBar = $ProgressBar
var _target: Node = null

func _ready() -> void:
	position = offset
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)
	else:
		# si la barra es hija del personaje, usa el padre
		_target = get_parent()

	if _target != null:
		# conectar si expone la señal
		if _target.has_signal("hp_changed"):
			_target.connect("hp_changed", Callable(self, "_on_hp_changed"))
		# tomar estado inicial si existen hp/max_hp como propiedades
		var cur_ok := "hp" in _target
		var max_ok := "max_hp" in _target
		if cur_ok and max_ok:
			var cur: int = int(_target.get("hp"))
			var mx: int = int(_target.get("max_hp"))
			_on_hp_changed(cur, mx)

func _process(_dt: float) -> void:
	# mantener el offset fijo sobre la cabeza
	position = offset

func _on_hp_changed(cur: int, mx: int) -> void:
	_bar.max_value = max(1, mx)
	_bar.value = clamp(cur, 0, _bar.max_value)
	visible = not (hide_when_full and cur >= mx)
