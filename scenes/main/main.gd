extends Node2D

const MENU_SCENE := "res://scenes/menu/Menu.tscn"
const MAIN_SCENE := "res://scenes/main/main.tscn"

@onready var lose_screen: Control = %LoseScreen
@onready var win_screen: Control = %WinScreen

var _paused_by_endscreen := false

func _ready() -> void:
	# Asegura que arrancan ocultas
	lose_screen.visible = false
	win_screen.visible = false

# === Mostrar pantallas ===
func show_lose() -> void:
	_pause_for_endscreen()
	lose_screen.visible = true
	await get_tree().process_frame
	# Si el botón se llama RetryButton:
	if lose_screen.has_node("%RetryButton"):
		(lose_screen.get_node("%RetryButton") as Button).grab_focus()

func show_win() -> void:
	_pause_for_endscreen()
	win_screen.visible = true
	await get_tree().process_frame
	if win_screen.has_node("%PlayAgainButton"):
		(win_screen.get_node("%PlayAgainButton") as Button).grab_focus()

func _pause_for_endscreen() -> void:
	if not get_tree().paused:
		_paused_by_endscreen = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _resume_if_paused() -> void:
	if _paused_by_endscreen and get_tree().paused:
		get_tree().paused = false
		_paused_by_endscreen = false

# === Botones: hookeá estos desde LoseScreen.gd / WinScreen.gd o llamalos desde ahí ===
func on_retry_requested() -> void:
	_resume_if_paused()
	get_tree().change_scene_to_file(MAIN_SCENE)

func on_menu_requested() -> void:
	_resume_if_paused()
	get_tree().change_scene_to_file(MENU_SCENE)
