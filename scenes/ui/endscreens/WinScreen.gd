extends Control

@onready var play_again_button: Button = %PlayAgainButton
@onready var menu_button: Button = %MenuButton

const MAIN_SCENE := "res://scenes/main/main.tscn"
const MENU_SCENE := "res://scenes/menu/Menu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	play_again_button.grab_focus()

func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
