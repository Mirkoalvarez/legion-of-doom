# res://autoload/GameEvents.gd
extends Node
signal game_over
signal level_completed

func trigger_game_over() -> void: emit_signal("game_over")
func trigger_level_completed() -> void: emit_signal("level_completed")
