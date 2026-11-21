class_name EquipmentItemData
extends Resource

enum Slot { HEAD, TORSO, LEGS, HANDS, FEET, CAPE, MAIN_HAND, OFF_HAND }

const SLOT_KEYS: Array[String] = [
	"head", "torso", "legs", "hands", "feet", "cape", "main_hand", "off_hand",
]

@export var item_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var slot: Slot = Slot.HEAD
@export var category := ""
@export_range(1, 80) var minimum_level := 1
@export var allowed_profession_ids: Array[String] = []
@export var attribute_bonuses: Dictionary = {}
@export var derived_bonuses: Dictionary = {}
@export var icon: Texture2D
@export var body_model_id := ""
@export var preview_visual: Texture2D
@export var combat_visual: Texture2D
# Future race/body variants can be added without changing item IDs or saves.
@export var preview_variants: Dictionary = {}
@export var combat_variants: Dictionary = {}
@export var combat_offsets: Dictionary = {}

func slot_key() -> String:
	return SLOT_KEYS[slot]

func can_be_used_by(character: CharacterProgress) -> bool:
	if character == null or character.level < minimum_level:
		return false
	if not allowed_profession_ids.is_empty() and not allowed_profession_ids.any(
		func(profession_id: String): return character.has_profession(profession_id)
	):
		return false
	return visual_for(character.appearance_id, false) != null

func visual_for(requested_body_model: String, combat := false) -> Texture2D:
	var variants: Dictionary = combat_variants if combat else preview_variants
	if variants.has(requested_body_model):
		return variants[requested_body_model] as Texture2D
	if requested_body_model != body_model_id:
		return null
	return combat_visual if combat else preview_visual

func combat_visual_for(requested_body_model: String, direction: String) -> Texture2D:
	var directional_key := "%s:%s" % [requested_body_model, direction]
	if combat_variants.has(directional_key):
		return combat_variants[directional_key] as Texture2D
	return visual_for(requested_body_model, true)

func combat_offset(state: String, direction: String, frame: int) -> Vector2:
	for key in ["%s:%s:%d" % [state, direction, frame], "%s:%s" % [state, direction], direction, "default"]:
		if combat_offsets.has(key):
			return combat_offsets[key] as Vector2
	return Vector2.ZERO

