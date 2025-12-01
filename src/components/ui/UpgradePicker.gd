extends CanvasLayer
class_name UpgradePicker

signal picked(id: String)

var _ids: Array = []

@onready var _btn0: Button = $Panel/VBoxContainer/Btn0
@onready var _btn1: Button = $Panel/VBoxContainer/Btn1
@onready var _btn2: Button = $Panel/VBoxContainer/Btn2

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_btn0.pressed.connect(func(): _on_pick_index(0))
	_btn1.pressed.connect(func(): _on_pick_index(1))
	_btn2.pressed.connect(func(): _on_pick_index(2))

func show_options(ids: Array, um: UpgradeManager) -> void:
	_ids.clear()

	# Reset visual
	for b in [_btn0, _btn1, _btn2]:
		b.visible = false
		b.disabled = true
		b.text = ""

	# Construir solo las opciones validas
	var buttons: Array[Button] = [_btn0, _btn1, _btn2]
	var idx := 0
	for upgrade_id in ids:
		if idx >= buttons.size():
			break
		if upgrade_id == "" or not um.db.has(upgrade_id):
			continue

		var data = um.db[upgrade_id]
		if data == null:
			continue

		var label: String = str(upgrade_id)
		var desc: String = ""
		if data and data.has_method("get"):
			var nm_val = data.get("name")
			var nm: String = str(nm_val) if nm_val != null else ""
			if nm != "":
				label = nm
			var desc_val = data.get("desc")
			desc = str(desc_val) if desc_val != null else ""
		if desc != "":
			label += " - " + desc

		var btn: Button = buttons[idx]
		btn.text = label
		btn.set_meta("upgrade_id", upgrade_id)
		btn.visible = true
		btn.disabled = false

		_ids.append(upgrade_id)
		idx += 1

	# Si no quedo ninguna opcion, cerrar y despausar
	if _ids.is_empty():
		visible = false
		if get_tree().paused:
			get_tree().paused = false
		return

	# Mostrar y dar foco al primer boton visible
	visible = true
	await get_tree().process_frame
	for b in buttons:
		if b.visible and not b.disabled:
			b.grab_focus()
			break

func _on_pick_index(i: int) -> void:
	if i < _ids.size():
		emit_signal("picked", _ids[i])
	visible = false
	if get_tree().paused:
		get_tree().paused = false
