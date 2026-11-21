class_name ProfessionData
extends Resource

@export var profession_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var previous_profession_id := ""
@export_range(1, 80) var minimum_level := 1
@export var allowed_race_ids: Array[String] = []
@export var attribute_modifiers: Dictionary = {}
@export var growth_attributes: Dictionary = {}
@export var derived_modifiers: Dictionary = {}
@export var ability_ids: Array[String] = []
@export var evolution_ids: Array[String] = []

func allows_race(race_id: String) -> bool:
	return allowed_race_ids.is_empty() or allowed_race_ids.has(race_id)
