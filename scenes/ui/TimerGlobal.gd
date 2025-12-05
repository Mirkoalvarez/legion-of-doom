extends Label

@export var start_time: float = 0.0  # en segundos
var elapsed: float = 0.0

func _ready() -> void:
	elapsed = start_time
	_update_text(elapsed)

func _process(delta: float) -> void:
	elapsed += delta  # cuenta hacia arriba
	_update_text(elapsed)

func _update_text(time_val: float) -> void:
	var t: int = int(floor(time_val))
	var mm: int = int(t / 60.0)  # división en float para evitar el warning
	var ss: int = t % 60
	text = "%02d:%02d" % [mm, ss]
