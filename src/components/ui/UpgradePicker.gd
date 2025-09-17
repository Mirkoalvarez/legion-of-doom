extends CanvasLayer
class_name UpgradePicker

signal picked(id: String)

var _ids: Array[String] = []

@onready var _btn0: Button = $Panel/VBoxContainer/Btn0
@onready var _btn1: Button = $Panel/VBoxContainer/Btn1
@onready var _btn2: Button = $Panel/VBoxContainer/Btn2

func _ready() -> void:
	visible = false
	_btn0.pressed.connect(func(): _on_pick_index(0))
	_btn1.pressed.connect(func(): _on_pick_index(1))
	_btn2.pressed.connect(func(): _on_pick_index(2))

func show_options(ids: Array[String], um: UpgradeManager) -> void:
	_ids = ids
	# protege por si hay menos de 3
	var texts: Array[String] = []
	for i in range(3):
		var label := ""
		if i < ids.size() and um.db.has(ids[i]):
			var meta: Dictionary = um.db[ids[i]]
			label = str(meta.get("name", ids[i])) + " — " + str(meta.get("desc", ""))
		else:
			label = "-"
		texts.append(label)

	_btn0.text = texts[0]
	_btn1.text = texts[1]
	_btn2.text = texts[2]

	visible = true

func _on_pick_index(i: int) -> void:
	if i < _ids.size():
		emit_signal("picked", _ids[i])
	visible = false
