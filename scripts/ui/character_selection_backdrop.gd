class_name CharacterSelectionBackdrop
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var viewport_size := size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#071426"), true)
	_draw_stone_wall(viewport_size)
	_draw_side_arches(viewport_size)
	_draw_banners(viewport_size)
	var floor_height := viewport_size.y * 0.17
	draw_rect(Rect2(0, viewport_size.y - floor_height, viewport_size.x, floor_height), Color("#0b1d35"), true)
	for x in range(0, int(viewport_size.x), 48):
		draw_line(Vector2(x, viewport_size.y - floor_height), Vector2(x + 28, viewport_size.y), Color("#173454"), 2.0)

func _draw_stone_wall(viewport_size: Vector2) -> void:
	var brick_width := 72
	var brick_height := 36
	for row in range(int(ceil(viewport_size.y / brick_height))):
		var offset := -brick_width / 2 if row % 2 == 1 else 0
		for column in range(-1, int(ceil(viewport_size.x / brick_width)) + 1):
			var rect := Rect2(offset + column * brick_width, row * brick_height, brick_width, brick_height)
			draw_rect(rect, Color("#102845") if (row + column) % 3 else Color("#132f50"), true)
			draw_rect(rect, Color("#1b4168"), false, 1.0)

func _draw_side_arches(viewport_size: Vector2) -> void:
	var arch_width := viewport_size.x * 0.14
	for side in [0, 1]:
		var x := 0.0 if side == 0 else viewport_size.x - arch_width
		draw_rect(Rect2(x, viewport_size.y * 0.18, arch_width, viewport_size.y * 0.66), Color("#0a1a30"), true)
		var center_x := x + arch_width * 0.5
		draw_circle(Vector2(center_x, viewport_size.y * 0.27), arch_width * 0.42, Color("#8ac8e8"))
		draw_rect(Rect2(x + arch_width * 0.08, viewport_size.y * 0.27, arch_width * 0.84, viewport_size.y * 0.47), Color("#4a87ae"), true)
		draw_rect(Rect2(x, viewport_size.y * 0.17, arch_width, viewport_size.y * 0.68), Color("#294e75"), false, 8.0)

func _draw_banners(viewport_size: Vector2) -> void:
	var banner_width := maxf(54.0, viewport_size.x * 0.045)
	for side in [0, 1]:
		var center_x := viewport_size.x * (0.09 if side == 0 else 0.91)
		var top := viewport_size.y * 0.06
		var bottom := viewport_size.y * 0.31
		var points := PackedVector2Array([
			Vector2(center_x - banner_width, top), Vector2(center_x + banner_width, top),
			Vector2(center_x + banner_width, bottom), Vector2(center_x, bottom + banner_width * 0.55),
			Vector2(center_x - banner_width, bottom),
		])
		draw_colored_polygon(points, Color("#173f7a"))
		draw_polyline(points + PackedVector2Array([points[0]]), Color("#e0b54e"), 5.0)
		draw_circle(Vector2(center_x, top + (bottom - top) * 0.45), banner_width * 0.28, Color("#e0b54e"))
