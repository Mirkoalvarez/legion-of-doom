extends CanvasLayer
class_name HUD_Wave

@export var spawner_path: NodePath
@onready var _label: Label = $WaveLabel

func _ready() -> void:
	_label.visible = false
	if spawner_path != NodePath(""):
		var spawner := get_node_or_null(spawner_path)
		if spawner:
			if spawner.has_signal("wave_started"):
				spawner.connect("wave_started", Callable(self, "_on_wave_started"))
			if spawner.has_signal("wave_cleared"):
				spawner.connect("wave_cleared", Callable(self, "_on_wave_cleared"))

func _on_wave_started(idx: int) -> void:
	_show_text("Wave " + str(idx + 1))

func _on_wave_cleared(idx: int) -> void:
	_show_text("Wave " + str(idx + 1) + " cleared!")

func _show_text(t: String) -> void:
	_label.text = t
	_label.visible = true
	_label.modulate.a = 1.0
	# fade out suave
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "modulate:a", 0.0, 1.0).set_delay(1.0)
	tw.tween_callback(Callable(self, "_hide"))

func _hide() -> void:
	_label.visible = false
