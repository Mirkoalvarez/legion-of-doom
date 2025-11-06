extends Node2D

const MENU_SCENE := "res://scenes/menu/Menu.tscn"
const MAIN_SCENE := "res://scenes/main/main.tscn"

@onready var lose_screen: Control = %LoseScreen
@onready var win_screen: Control  = %WinScreen
@onready var spawner:    Node     = %Spawner
# (Opcional) Si tenés Player con signal died:
# @onready var player: CharacterBody2D = %Player

var _paused_by_endscreen := false

func _ready() -> void:
	# Asegura que arrancan ocultas
	lose_screen.visible = false
	win_screen.visible  = false
	
	# Conectar señal del spawner → victoria
	if spawner and not spawner.is_connected("all_waves_cleared", Callable(self, "_on_all_waves_cleared")):
		spawner.connect("all_waves_cleared", Callable(self, "_on_all_waves_cleared"))

	# (Opcional) LoseScreen al morir el jugador:
	# if player and not player.is_connected("died", Callable(self, "_on_player_died")):
	# 	player.connect("died", Callable(self, "_on_player_died"))

func _on_all_waves_cleared() -> void:
	show_win()

# (Opcional) Muerte del jugador: derrota
# func _on_player_died() -> void:
# 	show_lose()

# === Mostrar pantallas ===
func show_lose() -> void:
	_pause_for_endscreen()
	lose_screen.visible = true
	await get_tree().process_frame
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

# === Botones: conectá estos métodos desde los botones de Lose/Win ===
func on_retry_requested() -> void:
	_resume_if_paused()
	get_tree().change_scene_to_file(MAIN_SCENE)

func on_menu_requested() -> void:
	_resume_if_paused()
	get_tree().change_scene_to_file(MENU_SCENE)
