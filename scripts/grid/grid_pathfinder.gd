class_name GridPathfinder
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

static func reachable_cells(
	start: Vector2i,
	maximum_cost: int,
	map_size: Vector2i,
	blocked: Dictionary,
	occupied: Dictionary,
	heights: Dictionary = {},
	max_climb: int = 1
) -> Dictionary:
	var costs: Dictionary = {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Vector2i, b: Vector2i): return costs[a] < costs[b])
		var current: Vector2i = frontier.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = current + direction
			if not _inside(next, map_size) or blocked.has(next):
				continue
			if occupied.has(next) and next != start:
				continue
			var height_delta: int = absi(_height(heights, next) - _height(heights, current))
			if height_delta > max_climb:
				continue
			var next_cost: int = costs[current] + 1 + height_delta
			if next_cost > maximum_cost:
				continue
			if not costs.has(next) or next_cost < costs[next]:
				costs[next] = next_cost
				if not frontier.has(next):
					frontier.append(next)
	return costs

static func find_path(
	start: Vector2i,
	goal: Vector2i,
	map_size: Vector2i,
	blocked: Dictionary,
	occupied: Dictionary,
	maximum_cost: int = 999,
	heights: Dictionary = {},
	max_climb: int = 1
) -> Array[Vector2i]:
	if start == goal:
		return []
	# Una casilla ocupada no puede ser destino final de movimiento.
	# La posición de origen sí puede figurar entre las ocupadas.
	if occupied.has(goal) or blocked.has(goal) or not _inside(goal, map_size):
		return []
	var came_from: Dictionary = {start: start}
	var costs: Dictionary = {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Vector2i, b: Vector2i): return costs[a] < costs[b])
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			return _reconstruct(came_from, start, goal)
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = current + direction
			if not _inside(next, map_size) or blocked.has(next):
				continue
			if occupied.has(next) and next != goal:
				continue
			var height_delta: int = absi(_height(heights, next) - _height(heights, current))
			if height_delta > max_climb:
				continue
			var next_cost: int = costs[current] + 1 + height_delta
			if next_cost > maximum_cost:
				continue
			if not costs.has(next) or next_cost < costs[next]:
				costs[next] = next_cost
				came_from[next] = current
				if not frontier.has(next):
					frontier.append(next)
	return []

static func path_cost(path: Array[Vector2i], start: Vector2i, heights: Dictionary = {}) -> int:
	var result := 0
	var previous := start
	for cell in path:
		result += 1 + abs(_height(heights, cell) - _height(heights, previous))
		previous = cell
	return result

static func _reconstruct(came_from: Dictionary, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := goal
	while current != start:
		path.push_front(current)
		current = came_from[current]
	return path

static func _height(heights: Dictionary, cell: Vector2i) -> int:
	return int(heights.get(cell, 0))

static func _inside(cell: Vector2i, map_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y
