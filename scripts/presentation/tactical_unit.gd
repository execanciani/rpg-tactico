class_name TacticalUnit
extends Node2D

signal movement_finished

var data: UnitData
var is_selected := false
var is_targeted := false

func setup(unit_data: UnitData, world_position: Vector2) -> void:
	data = unit_data
	position = world_position + Vector2(0, -9)
	z_index = unit_data.grid_position.x + unit_data.grid_position.y + 10
	queue_redraw()

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func set_targeted(value: bool) -> void:
	is_targeted = value
	queue_redraw()

func refresh() -> void:
	queue_redraw()

func animate_path(path: Array[Vector2i], grid: IsometricGrid) -> void:
	if path.is_empty():
		movement_finished.emit()
		return
	var tween := create_tween()
	for cell in path:
		var destination := grid.grid_to_world(cell) + Vector2(0, -9)
		tween.tween_property(self, "position", destination, 0.11).set_trans(Tween.TRANS_SINE)
		data.grid_position = cell
		data.elevation = grid.get_height(cell)
		tween.tween_callback(_update_depth)
	tween.finished.connect(func(): movement_finished.emit())

func play_hit() -> void:
	var original_modulate := modulate
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("#ff7070"), 0.07)
	tween.tween_property(self, "modulate", original_modulate, 0.13)

func play_defeat() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(self, "position:y", position.y + 10.0, 0.35)
	await tween.finished
	visible = false

func _update_depth() -> void:
	z_index = data.grid_position.x + data.grid_position.y + 10

func _draw() -> void:
	if data == null:
		return
	var team_color := Color("#4da6ff") if data.team == UnitData.Team.HEROES else Color("#ed5d5d")
	var accent := _class_color()
	_draw_flat_ellipse(Vector2(0, 13), Vector2(20, 8), Color(0.05, 0.08, 0.10, 0.45))
	if is_selected:
		draw_arc(Vector2(0, 11), 22.0, 0, TAU, 32, Color("#ffe784"), 3.0)
	if is_targeted:
		draw_arc(Vector2(0, -12), 23.0, 0, TAU, 32, Color("#ff5b55"), 3.0)
	# Provisional original pixel-style character assembled from primitives.
	draw_rect(Rect2(-11, -9, 22, 24), team_color)
	draw_rect(Rect2(-8, -5, 16, 17), accent)
	draw_circle(Vector2(0, -17), 10.0, Color("#e8bd91"))
	draw_rect(Rect2(-10, -25, 20, 7), accent.darkened(0.18))
	draw_rect(Rect2(-12, 13, 9, 8), Color("#263248"))
	draw_rect(Rect2(3, 13, 9, 8), Color("#263248"))
	_draw_class_details(accent)
	var hp_ratio := float(data.hp) / float(data.max_hp)
	draw_rect(Rect2(-21, -36, 42, 6), Color("#182027"))
	draw_rect(Rect2(-20, -35, 40.0 * hp_ratio, 4), Color("#58d26d") if hp_ratio > 0.35 else Color("#f0655b"))
	if data.has_acted:
		draw_circle(Vector2(16, -23), 6.0, Color("#2c333d"))
		draw_line(Vector2(13, -23), Vector2(15, -20), Color("#d5dae0"), 2.0)
		draw_line(Vector2(15, -20), Vector2(20, -26), Color("#d5dae0"), 2.0)

func _draw_class_details(accent: Color) -> void:
	match data.class_name_text:
		"Guerrero", "Guardia":
			draw_rect(Rect2(13, -9, 5, 25), Color("#d9e0e5"))
			draw_colored_polygon(PackedVector2Array([Vector2(11, -9), Vector2(20, -9), Vector2(15, -18)]), Color("#eef3f6"))
		"Mago", "Chamán":
			draw_line(Vector2(15, 15), Vector2(20, -21), Color("#6b432b"), 4.0)
			draw_circle(Vector2(21, -23), 6.0, Color("#80d8ff"))
		"Arquero", "Explorador":
			draw_arc(Vector2(15, -1), 13.0, -PI * 0.5, PI * 0.5, 12, Color("#d7a65d"), 3.0)
			draw_line(Vector2(15, -14), Vector2(15, 12), Color("#e8dfbd"), 1.0)

func _class_color() -> Color:
	match data.class_name_text:
		"Guerrero", "Guardia": return Color("#607d9b")
		"Mago", "Chamán": return Color("#7759a8")
		"Arquero", "Explorador": return Color("#507c55")
		_: return Color("#777777")

func _draw_flat_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
