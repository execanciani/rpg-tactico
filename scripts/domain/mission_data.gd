class_name MissionData
extends Resource

enum ObjectiveType { ELIMINATE_ALL, REACH_CELL, SURVIVE_ROUNDS }

@export var mission_id := ""
@export var title := ""
@export_multiline var briefing := ""
@export var hero_positions: Array[Vector2i] = []
@export var enemy_archetype_paths: Array[String] = []
@export var enemy_positions: Array[Vector2i] = []
@export var blocked_cells: Array[Vector2i] = []
@export var height_cells: Array[Vector3i] = []
@export var objective_type: ObjectiveType = ObjectiveType.ELIMINATE_ALL
@export_multiline var objective_text := "Derrotá a todos los enemigos."
@export var objective_cell := Vector2i(-1, -1)
@export var survive_rounds := 0
@export var reward_xp := 40
@export var reward_gold := 25
@export var reward_item_ids: Array[String] = []
@export var reward_item_quantities: Array[int] = []
@export var intro_dialogue: Array[String] = []
@export var victory_dialogue: Array[String] = []

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
