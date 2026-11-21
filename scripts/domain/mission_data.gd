class_name MissionData
extends Resource

@export var mission_id := ""
@export var title := ""
@export_multiline var briefing := ""
@export var hero_positions: Array[Vector2i] = []
@export var enemy_archetype_paths: Array[String] = []
@export var enemy_positions: Array[Vector2i] = []
@export var blocked_cells: Array[Vector2i] = []
@export var height_cells: Array[Vector3i] = []

func height_map() -> Dictionary:
	var result := {}
	for entry in height_cells:
		result[Vector2i(entry.x, entry.y)] = entry.z
	return result

func blocked_map() -> Dictionary:
	var result := {}
	for cell in blocked_cells:
		result[cell] = true
	return result
