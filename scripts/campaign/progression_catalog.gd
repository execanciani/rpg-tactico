class_name ProgressionCatalog
extends RefCounted

const RACE_PATHS: Array[String] = [
	"res://data/races/human.tres", "res://data/races/elf.tres", "res://data/races/dark_elf.tres",
	"res://data/races/orc.tres", "res://data/races/dwarf.tres",
]
const PROFESSION_PATHS: Array[String] = [
	"res://data/professions/warrior.tres", "res://data/professions/mage.tres", "res://data/professions/archer.tres",
	"res://data/professions/acolyte.tres", "res://data/professions/explorer.tres",
	"res://data/professions/swordsman.tres", "res://data/professions/guardian.tres",
	"res://data/professions/elementalist.tres", "res://data/professions/summoner.tres",
	"res://data/professions/marksman.tres", "res://data/professions/hunter.tres",
	"res://data/professions/healer.tres", "res://data/professions/oracle.tres",
	"res://data/professions/assassin.tres", "res://data/professions/stalker.tres",
	"res://data/professions/blade_master.tres", "res://data/professions/iron_protector.tres",
	"res://data/professions/frost_sorcerer.tres", "res://data/professions/flame_sorcerer.tres",
	"res://data/professions/spirit_master.tres", "res://data/professions/imperial_archer.tres",
	"res://data/professions/light_priest.tres", "res://data/professions/lethal_shadow.tres",
]
const ABILITY_PATHS: Array[String] = [
	"res://data/abilities/powerful_strike.tres", "res://data/abilities/steel_guard.tres",
	"res://data/abilities/ice_lance.tres", "res://data/abilities/paralyzing_frost.tres",
	"res://data/abilities/precise_arrow.tres", "res://data/abilities/double_shot.tres",
	"res://data/abilities/blade_arc.tres", "res://data/abilities/armor_breaker.tres",
	"res://data/abilities/arcane_burst.tres", "res://data/abilities/astral_lance.tres",
	"res://data/abilities/piercing_arrow.tres", "res://data/abilities/hamstring_shot.tres",
]
const APPEARANCE_PATHS: Array[String] = [
	"res://data/appearances/warrior.tres", "res://data/appearances/mage.tres",
	"res://data/appearances/archer.tres", "res://data/appearances/acolyte.tres",
	"res://data/appearances/explorer.tres",
]
const EQUIPMENT_PATHS: Array[String] = [
	"res://data/equipment/iron_sword.tres", "res://data/equipment/wooden_shield.tres",
	"res://data/equipment/leather_helmet.tres", "res://data/equipment/leather_armor.tres",
	"res://data/equipment/leather_boots.tres", "res://data/equipment/apprentice_staff.tres",
	"res://data/equipment/arcane_robe.tres", "res://data/equipment/cloth_hood.tres",
	"res://data/equipment/cloth_gloves.tres", "res://data/equipment/apprentice_sandals.tres",
	"res://data/equipment/wooden_bow.tres", "res://data/equipment/leather_vest.tres",
	"res://data/equipment/archer_gloves.tres", "res://data/equipment/light_boots.tres",
	"res://data/equipment/ceremonial_staff.tres", "res://data/equipment/healer_robe.tres",
	"res://data/equipment/white_hood.tres", "res://data/equipment/cloth_boots.tres",
	"res://data/equipment/iron_daggers.tres", "res://data/equipment/light_armor.tres",
	"res://data/equipment/dark_hood.tres", "res://data/equipment/explorer_boots.tres",
	"res://data/equipment/iron_helmet.tres", "res://data/equipment/iron_armor.tres",
	"res://data/equipment/iron_boots.tres", "res://data/equipment/iron_shield.tres",
	"res://data/equipment/leather_gloves.tres",
	"res://data/items/small_health_potion.tres", "res://data/items/small_mana_potion.tres",
	"res://data/items/iron_ore.tres", "res://data/items/wood.tres",
	"res://data/items/leather.tres", "res://data/items/magic_crystal.tres",
]

var races: Dictionary = {}
var professions: Dictionary = {}
var abilities: Dictionary = {}
var appearances: Dictionary = {}
var equipment: Dictionary = {}

func load_all() -> void:
	races.clear()
	professions.clear()
	abilities.clear()
	appearances.clear()
	equipment.clear()
	for path in RACE_PATHS:
		var race := load(path) as RaceData
		if race != null:
			races[race.race_id] = race
	for path in PROFESSION_PATHS:
		var profession := load(path) as ProfessionData
		if profession != null:
			professions[profession.profession_id] = profession
	for path in ABILITY_PATHS:
		var ability := load(path) as AbilityData
		if ability != null:
			abilities[String(ability.id)] = ability
	for path in APPEARANCE_PATHS:
		var appearance := load(path) as AppearanceData
		if appearance != null:
			appearances[appearance.appearance_id] = appearance
	for path in EQUIPMENT_PATHS:
		var item := load(path) as EquipmentItemData
		if item != null:
			equipment[item.item_id] = item

func race(race_id: String) -> RaceData:
	return races.get(race_id) as RaceData

func profession(profession_id: String) -> ProfessionData:
	return professions.get(profession_id) as ProfessionData

func ability(ability_id: String) -> AbilityData:
	return abilities.get(ability_id) as AbilityData

func appearance(appearance_id: String) -> AppearanceData:
	return appearances.get(appearance_id) as AppearanceData

func equipment_item(item_id: String) -> EquipmentItemData:
	return equipment.get(item_id) as EquipmentItemData

func item(item_id: String) -> EquipmentItemData:
	return equipment_item(item_id)

func category_map() -> Dictionary:
	var result := {}
	for item_id in equipment:
		var definition := equipment[item_id] as EquipmentItemData
		result[item_id] = definition.category
	return result

func abilities_for_character(character: CharacterProgress) -> Array[AbilityData]:
	var result: Array[AbilityData] = []
	for ability_value in abilities.values():
		var ability_data := ability_value as AbilityData
		if ability_data.required_profession_ids.is_empty() or ability_data.required_profession_ids.any(func(id: String): return character.has_profession(id)):
			result.append(ability_data)
	result.sort_custom(func(a: AbilityData, b: AbilityData):
		if a.required_level == b.required_level:
			return a.display_name < b.display_name
		return a.required_level < b.required_level
	)
	return result
