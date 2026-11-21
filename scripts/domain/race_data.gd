class_name RaceData
extends Resource

@export var race_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var base_attributes: Dictionary = {
	"STR": 10, "DEX": 10, "CON": 10, "INT": 10, "WIS": 10, "MEN": 10,
}
@export var racial_modifiers: Dictionary = {}
@export var allowed_initial_professions: Array[String] = []

func attribute_value(attribute_id: String) -> int:
	return int(base_attributes.get(attribute_id, 0)) + int(racial_modifiers.get(attribute_id, 0))

func allows_profession(profession_id: String) -> bool:
	return allowed_initial_professions.has(profession_id)
