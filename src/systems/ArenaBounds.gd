@tool
extends Node2D
class_name ArenaBounds

# 0 = centrado (posición del nodo es el centro + size)
# 1 = top-left + size (coordenadas absolutas)
# 2 = dos marcadores (TopLeft y BottomRight)
@export_enum("Centered", "TopLeft+Size", "TwoMarkers") var mode: int = 2

@export var size: Vector2 = Vector2(4800, 2700)            # usado en Centered/TopLeft+Size
@export var top_left: Vector2 = Vector2(-35.046, -41.371)  # usado en TopLeft+Size

@export var top_left_marker: NodePath                      # usado en TwoMarkers
@export var bottom_right_marker: NodePath                  # usado en TwoMarkers

func get_rect() -> Rect2:
	match mode:
		0: # Centered
			return Rect2(global_position - size * 0.5, size)
		1: # TopLeft+Size
			return Rect2(top_left, size)
		2: # TwoMarkers
			var tl := get_node_or_null(top_left_marker) as Node2D
			var br := get_node_or_null(bottom_right_marker) as Node2D
			if tl != null and br != null:
				var p1: Vector2 = tl.global_position
				var p2: Vector2 = br.global_position
				var pos := Vector2(min(p1.x, p2.x), min(p1.y, p2.y))
				var sz := Vector2(abs(p2.x - p1.x), abs(p2.y - p1.y))
				return Rect2(pos, sz)
	# fallback
	return Rect2(global_position - size * 0.5, size)

func _draw() -> void:
	var r := get_rect()
	# draw_rect dibuja en espacio local, convertimos el rect global a local
	var local_r := Rect2(to_local(r.position), r.size)
	draw_rect(local_r, Color(0, 1, 0, 0.08), true)
	draw_rect(local_r, Color(0.1, 1, 0.1, 0.9), false)
