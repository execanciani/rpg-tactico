class_name ItemData
extends Resource

enum Type { CONSUMABLE, WEAPON, ARMOR, ACCESSORY }

@export var item_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var type: Type = Type.CONSUMABLE
@export var allowed_classes: Array[String] = []
@export var heal_hp := 0
@export var restore_mp := 0
@export var max_hp_bonus := 0
@export var max_mp_bonus := 0
@export var physical_attack_bonus := 0
@export var magical_attack_bonus := 0
@export var physical_defense_bonus := 0
@export var magical_defense_bonus := 0

func slot_name() -> String:
	match type:
		Type.WEAPON: return "weapon"
		Type.ARMOR: return "armor"
		Type.ACCESSORY: return "accessory"
		_: return ""

func can_equip(unit: UnitData) -> bool:
	return type != Type.CONSUMABLE and (allowed_classes.is_empty() or allowed_classes.has(unit.class_name_text))
