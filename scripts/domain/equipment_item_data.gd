class_name EquipmentItemData
extends Resource

enum Slot { HEAD, TORSO, LEGS, HANDS, FEET, CAPE, MAIN_HAND, OFF_HAND, ACCESSORY, NONE }
enum ItemType { EQUIPMENT, CONSUMABLE, MATERIAL }

const SLOT_KEYS: Array[String] = [
	"head", "torso", "legs", "hands", "feet", "cape", "main_hand", "off_hand",
	"accessory",
]

@export var item_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var slot: Slot = Slot.HEAD
@export var category := ""
@export var item_type: ItemType = ItemType.EQUIPMENT
@export_range(0, 999999) var base_price := 0
@export_range(0.0, 999.0, 0.1) var weight := 0.0
@export var stackable := false
@export_range(1, 999) var max_stack := 1
@export_range(1, 80) var minimum_level := 1
@export var allowed_profession_ids: Array[String] = []
@export var attribute_bonuses: Dictionary = {}
@export var derived_bonuses: Dictionary = {}
@export var consumable_effects: Dictionary = {}
@export var icon: Texture2D
@export var body_model_id := ""
@export var preview_visual: Texture2D
@export var combat_visual: Texture2D
# Future race/body variants can be added without changing item IDs or saves.
@export var preview_variants: Dictionary = {}
@export var combat_variants: Dictionary = {}
@export var combat_offsets: Dictionary = {}
## Uses the cells of the matching body's animation atlas.
@export var combat_pose_atlas: Texture2D
@export var combat_draw_order: Dictionary = {}

func combat_z_index(state: String, direction: String, frame: int, fallback: int) -> int:
	for key in ["%s:%s:%d" % [state, direction, frame], "%s:%s" % [state, direction], direction, "default"]:
		if combat_draw_order.has(key):
			return int(combat_draw_order[key])
	return fallback

func slot_key() -> String:
	if slot == Slot.NONE:
		return ""
	return SLOT_KEYS[slot]

func is_equipment() -> bool:
	return item_type == ItemType.EQUIPMENT and slot != Slot.NONE

func is_consumable() -> bool:
	return item_type == ItemType.CONSUMABLE

func is_material() -> bool:
	return item_type == ItemType.MATERIAL

func stack_limit() -> int:
	return maxi(1, max_stack if stackable else 1)

func can_be_used_by(character: CharacterProgress) -> bool:
	if not is_equipment() or character == null or character.level < minimum_level:
		return false
	if not allowed_profession_ids.is_empty() and not allowed_profession_ids.any(
		func(profession_id: String): return character.has_profession(profession_id)
	):
		return false
	# Un visual es opcional para ranuras que todavia no poseen una capa propia.
	# La compatibilidad jugable depende de nivel y profesion, no del arte.
	return true

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

