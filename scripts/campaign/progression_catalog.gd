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

var races: Dictionary = {}
var professions: Dictionary = {}
var abilities: Dictionary = {}

func load_all() -> void:
	races.clear()
	professions.clear()
	abilities.clear()
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

func race(race_id: String) -> RaceData:
	return races.get(race_id) as RaceData

func profession(profession_id: String) -> ProfessionData:
	return professions.get(profession_id) as ProfessionData

func ability(ability_id: String) -> AbilityData:
	return abilities.get(ability_id) as AbilityData

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
