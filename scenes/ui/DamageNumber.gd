extends Label
@export var rise_distance: float = 24.0
@export var lifetime: float = 0.6

func show_value(val: int, start_pos: Vector2) -> void:
	text = str(val)
	global_position = start_pos
	var tw := create_tween()
	tw.tween_property(self, "global_position", start_pos + Vector2(0, -rise_distance), lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, lifetime)
	tw.tween_callback(queue_free)
