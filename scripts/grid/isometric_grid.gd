class_name IsometricGrid
extends Node2D

signal cell_pressed(cell: Vector2i)
signal cell_hovered(cell: Vector2i)

enum Terrain { GRASS, DIRT, STONE }
enum Highlight { NONE, MOVE, ATTACK, SKILL }

const MAP_SIZE := Vector2i(12, 12)
const TILE_SIZE := Vector2(64.0, 32.0)
const HEIGHT_STEP := 14.0

var blocked_cells: Dictionary = {}
var height_cells: Dictionary = {}
var highlighted_cells: Dictionary = {}
var selected_cell := Vector2i(-1, -1)
var objective_cell := Vector2i(-1, -1)
var preview_path: Array[Vector2i] = []
var last_hovered_cell := Vector2i(-1, -1)

func _ready() -> void:
	queue_redraw()

func configure(mission: MissionData) -> void:
	blocked_cells = mission.blocked_map()
	height_cells = mission.height_map()
	objective_cell = mission.objective_cell if mission.objective_type == MissionData.ObjectiveType.REACH_CELL else Vector2i(-1, -1)
	highlighted_cells.clear()
	preview_path.clear()
	selected_cell = Vector2i(-1, -1)
	queue_redraw()

func grid_to_world(cell: Vector2i) -> Vector2:
	return grid_to_world_flat(cell) - Vector2(0, get_height(cell) * HEIGHT_STEP)

func grid_to_world_flat(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * TILE_SIZE.x * 0.5,
		(cell.x + cell.y) * TILE_SIZE.y * 0.5
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	var local := to_local(world_position)
	var best := Vector2i(-1, -1)
	var best_distance: float = INF
	for diagonal in range(MAP_SIZE.x + MAP_SIZE.y - 2, -1, -1):
		for y in range(MAP_SIZE.y - 1, -1, -1):
			var x := diagonal - y
			if x < 0 or x >= MAP_SIZE.x:
				continue
			var cell := Vector2i(x, y)
			var center := grid_to_world(cell)
			var normalized: float = absf(local.x - center.x) / (TILE_SIZE.x * 0.5) + absf(local.y - center.y) / (TILE_SIZE.y * 0.5)
			if normalized <= 1.0 and normalized < best_distance:
				best = cell
				best_distance = normalized
	return best

func get_height(cell: Vector2i) -> int:
	return int(height_cells.get(cell, 0))

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < MAP_SIZE.x and cell.y < MAP_SIZE.y

func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)

func show_highlights(cells: Array[Vector2i], type: Highlight) -> void:
	highlighted_cells.clear()
	for cell in cells:
		highlighted_cells[cell] = type
	queue_redraw()

func clear_highlights() -> void:
	highlighted_cells.clear()
	preview_path.clear()
	queue_redraw()

func show_path_preview(path: Array[Vector2i]) -> void:
	preview_path = path.duplicate()
	queue_redraw()

func set_selected(cell: Vector2i) -> void:
	selected_cell = cell
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := world_to_grid(get_global_mouse_position())
		if hovered != last_hovered_cell:
			last_hovered_cell = hovered
			cell_hovered.emit(hovered)
	var was_pressed := false
	var pointer_world := get_global_mouse_position()
	if event is InputEventMouseButton:
		was_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		was_pressed = event.pressed
		pointer_world = get_canvas_transform().affine_inverse() * event.position
	if not was_pressed:
		return
	var cell := world_to_grid(pointer_world)
	if is_inside(cell):
		cell_pressed.emit(cell)
		get_viewport().set_input_as_handled()

func _draw() -> void:
	for diagonal in range(MAP_SIZE.x + MAP_SIZE.y - 1):
		for y in range(MAP_SIZE.y):
			var x := diagonal - y
			if x < 0 or x >= MAP_SIZE.x:
				continue
			_draw_cell(Vector2i(x, y))
	for cell: Vector2i in blocked_cells:
		_draw_obstacle(cell)
	_draw_path_preview()

func _draw_path_preview() -> void:
	if preview_path.is_empty():
		return
	var points := PackedVector2Array()
	for cell in preview_path:
		points.append(grid_to_world(cell))
	if points.size() > 1:
		draw_polyline(points, Color("#e9fbff"), 5.0, true)
	for point in points:
		draw_circle(point, 5.0, Color("#62d9ff"))
		draw_arc(point, 7.0, 0, TAU, 16, Color("#173244"), 2.0)

func _draw_cell(cell: Vector2i) -> void:
	var center := grid_to_world(cell)
	var elevation := get_height(cell)
	var diamond := PackedVector2Array([
		center + Vector2(0, -TILE_SIZE.y * 0.5),
		center + Vector2(TILE_SIZE.x * 0.5, 0),
		center + Vector2(0, TILE_SIZE.y * 0.5),
		center + Vector2(-TILE_SIZE.x * 0.5, 0),
	])
	if elevation > 0:
		var drop := Vector2(0, elevation * HEIGHT_STEP)
		draw_colored_polygon(PackedVector2Array([diamond[3], diamond[2], diamond[2] + drop, diamond[3] + drop]), Color("#40564c"))
		draw_colored_polygon(PackedVector2Array([diamond[2], diamond[1], diamond[1] + drop, diamond[2] + drop]), Color("#354841"))
	var terrain := _terrain_at(cell)
	var color := Color("#5f9f58")
	if terrain == Terrain.DIRT:
		color = Color("#a87948")
	elif terrain == Terrain.STONE:
		color = Color("#747c83")
	if (cell.x + cell.y) % 2 == 0:
		color = color.lightened(0.045)
	draw_colored_polygon(diamond, color)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#263b35"), 1.5, true)
	if cell == objective_cell:
		draw_colored_polygon(diamond, Color(1.0, 0.78, 0.2, 0.55))
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#fff0a0"), 3.0, true)
	if highlighted_cells.has(cell):
		var highlight_type: Highlight = highlighted_cells[cell]
		var highlight_color := Color(0.18, 0.72, 1.0, 0.52)
		if highlight_type == Highlight.ATTACK:
			highlight_color = Color(1.0, 0.24, 0.20, 0.52)
		elif highlight_type == Highlight.SKILL:
			highlight_color = Color(0.48, 0.76, 1.0, 0.58)
		draw_colored_polygon(diamond, highlight_color)
	if cell == selected_cell:
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#fff2a6"), 4.0, true)
	if elevation > 0:
		draw_string(ThemeDB.fallback_font, center + Vector2(-4, 5), str(elevation), HORIZONTAL_ALIGNMENT_CENTER, 8, 11, Color("#eef6e8"))

func _draw_obstacle(cell: Vector2i) -> void:
	var center := grid_to_world(cell)
	var base := center + Vector2(0, 4)
	var rock_color := Color("#48515b")
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-18, 6), base + Vector2(-13, -12), base + Vector2(-3, -22),
		base + Vector2(12, -16), base + Vector2(19, 3), base + Vector2(8, 11),
		base + Vector2(-8, 12),
	]), rock_color)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-12, -10), base + Vector2(-3, -21), base + Vector2(11, -15),
		base + Vector2(3, -7),
	]), Color("#77838c"))

func _terrain_at(cell: Vector2i) -> Terrain:
	if cell.x in [5, 6] and cell.y in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		return Terrain.DIRT
	if (cell.x + cell.y * 3) % 11 in [0, 1]:
		return Terrain.STONE
	return Terrain.GRASS
