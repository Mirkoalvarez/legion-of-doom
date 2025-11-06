extends Control

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton

const MAIN_SCENE_PATH := "res://scenes/main/main.tscn"

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	# Opcional: mostrar el mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	play_button.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
