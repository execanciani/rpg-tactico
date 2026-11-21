class_name CampaignProfile
extends RefCounted

const MAX_CHARACTERS := 3
const MIN_NAME_LENGTH := 3
const MAX_NAME_LENGTH := 16
const STARTER_ITEMS := {
	"warrior": ["iron_sword", "iron_shield", "iron_helmet", "iron_armor", "iron_boots"],
	"mage": ["apprentice_staff", "arcane_robe", "cloth_hood", "cloth_gloves", "apprentice_sandals"],
	"archer": ["wooden_bow", "leather_vest", "archer_gloves", "light_boots"],
	"acolyte": ["ceremonial_staff", "healer_robe", "white_hood", "cloth_boots"],
	"explorer": ["iron_daggers", "light_armor", "dark_hood", "explorer_boots"],
}

var characters: Dictionary = {}
var slot_ids: Array[String] = []
var formation_ids: Array[String] = []
var completed_missions: Array[String] = []
var catalog := ProgressionCatalog.new()

func _init() -> void:
	catalog.load_all()

func initialize_default() -> void:
	characters.clear()
	slot_ids.clear()
	formation_ids.clear()
	create_character("hero_warrior", "Kael", "human", "warrior", ["powerful_strike", "steel_guard"])
	create_character("hero_mage", "Lyra", "elf", "mage", ["ice_lance", "paralyzing_frost"])
	create_character("hero_archer", "Orin", "dark_elf", "archer", ["precise_arrow", "double_shot"])
	formation_ids = slot_ids.duplicate()
	completed_missions.clear()

func initialize_new() -> void:
	characters.clear()
	slot_ids.clear()
	formation_ids.clear()
	completed_missions.clear()

func create_character(
	character_id: String,
	character_name: String,
	race_id: String,
	profession_id: String,
	initial_abilities: Array[String] = []
) -> CharacterProgress:
	var clean_name := normalize_character_name(character_name)
	if character_id.is_empty() or characters.has(character_id) or characters.size() >= MAX_CHARACTERS:
		return null
	if not validate_character_name(clean_name).is_empty():
		return null
	var race := catalog.race(race_id)
	var profession := catalog.profession(profession_id)
	if race == null or profession == null or not race.allows_profession(profession_id) or not profession.allows_race(race_id):
		return null
	var character := CharacterProgress.new()
	character.setup(character_id, clean_name, race, profession_id, initial_abilities)
	_grant_starter_items(character)
	characters[character_id] = character
	slot_ids.append(character_id)
	formation_ids.append(character_id)
	return character

func create_character_auto(character_name: String, race_id: String, profession_id: String) -> CharacterProgress:
	var clean_name := normalize_character_name(character_name)
	var number := 1
	var character_id := "character_%03d" % number
	while characters.has(character_id):
		number += 1
		character_id = "character_%03d" % number
	var profession := catalog.profession(profession_id)
	var initial_abilities: Array[String] = []
	if profession != null:
		for ability_id in profession.ability_ids:
			var ability := catalog.ability(ability_id)
			if ability != null and ability.required_level <= 1 and ability.sp_cost == 0:
				initial_abilities.append(ability_id)
	return create_character(character_id, clean_name, race_id, profession_id, initial_abilities)

func normalize_character_name(value: String) -> String:
	return " ".join(value.strip_edges().split(" ", false))

func validate_character_name(value: String, excluding_character_id := "") -> String:
	var clean_name := normalize_character_name(value)
	if clean_name.length() < MIN_NAME_LENGTH or clean_name.length() > MAX_NAME_LENGTH:
		return "El nombre debe tener entre %d y %d caracteres." % [MIN_NAME_LENGTH, MAX_NAME_LENGTH]
	for character in clean_name:
		var code := character.unicode_at(0)
		if code < 32 or code == 127:
			return "El nombre contiene caracteres no permitidos."
	for character_id in characters:
		if str(character_id) == excluding_character_id:
			continue
		var existing := characters[character_id] as CharacterProgress
		if existing.display_name.nocasecmp_to(clean_name) == 0:
			return "Ya existe un personaje con ese nombre."
	return ""

func delete_character(character_id: String) -> bool:
	if not characters.has(character_id):
		return false
	characters.erase(character_id)
	slot_ids.erase(character_id)
	formation_ids.erase(character_id)
	return true

func set_formation(character_ids: Array[String]) -> bool:
	if character_ids.is_empty() or character_ids.size() > MAX_CHARACTERS:
		return false
	var validated: Array[String] = []
	for character_id in character_ids:
		if not characters.has(character_id) or validated.has(character_id):
			return false
		validated.append(character_id)
	formation_ids = validated
	return true

func toggle_formation_character(character_id: String) -> bool:
	if not characters.has(character_id):
		return false
	if formation_ids.has(character_id):
		if formation_ids.size() == 1:
			return false
		formation_ids.erase(character_id)
	else:
		if formation_ids.size() >= MAX_CHARACTERS:
			return false
		formation_ids.append(character_id)
	return true

func character(character_id: String) -> CharacterProgress:
	return characters.get(character_id) as CharacterProgress

func battle_archetype_path(character_id: String) -> String:
	var progress := character(character_id)
	if progress == null:
		return ""
	var profession := catalog.profession(progress.profession_id)
	while profession != null and not profession.previous_profession_id.is_empty():
		profession = catalog.profession(profession.previous_profession_id)
	if profession == null:
		return ""
	match profession.profession_id:
		"mage", "acolyte":
			return "res://data/archetypes/hero_mage.tres"
		"archer", "explorer":
			return "res://data/archetypes/hero_archer.tres"
		_:
			return "res://data/archetypes/hero_warrior.tres"

func apply_to_hero(unit: UnitData, preserve_vitals := false) -> void:
	var progress := character(unit.unit_id)
	if progress == null:
		return
	var race := catalog.race(progress.race_id)
	var profession := catalog.profession(progress.profession_id)
	if race == null or profession == null:
		return
	var hp_ratio := float(unit.hp) / float(maxi(1, unit.max_hp))
	var mp_ratio := float(unit.mp) / float(maxi(1, unit.max_mp))
	var calculated := StatCalculator.calculate(progress, race, profession, equipment_bonuses(progress))
	var attributes: Dictionary = calculated.attributes
	var derived: Dictionary = calculated.derived
	unit.display_name = progress.display_name
	unit.race_id = race.race_id
	unit.race_name_text = race.display_name
	unit.profession_id = profession.profession_id
	unit.class_name_text = profession.display_name
	unit.level = progress.level
	unit.xp = progress.experience_into_level()
	unit.xp_to_next = progress.experience_to_next_level()
	unit.skill_points = progress.sp_available
	unit.body_model_id = progress.appearance_id
	unit.equipment_ids.assign(progress.equipped_items.values())
	unit.equipment_items = equipped_resources(progress)
	unit.main_attributes = attributes.duplicate(true)
	unit.max_hp = int(derived.max_hp)
	unit.max_mp = int(derived.max_mp)
	unit.physical_attack = int(derived.physical_attack)
	unit.magical_attack = int(derived.magical_attack)
	unit.physical_defense = int(derived.physical_defense)
	unit.magical_defense = int(derived.magical_defense)
	unit.accuracy = int(derived.accuracy)
	unit.evasion = int(derived.evasion)
	unit.critical_chance = int(derived.critical_chance)
	unit.critical_damage = int(derived.critical_damage)
	unit.speed = int(derived.speed)
	unit.move_range = int(derived.move_range)
	unit.effect_resistance = int(derived.effect_resistance)
	unit.hp = unit.max_hp
	unit.mp = unit.max_mp
	unit.abilities.clear()
	for ability_id in progress.learned_ability_ids:
		var learned := catalog.ability(ability_id)
		if learned != null:
			unit.abilities.append(learned)
	if preserve_vitals:
		unit.hp = clampi(roundi(unit.max_hp * hp_ratio), 1 if hp_ratio > 0.0 else 0, unit.max_hp)
		unit.mp = clampi(roundi(unit.max_mp * mp_ratio), 0, unit.max_mp)

func learn_ability(character_id: String, ability_id: String) -> bool:
	var progress := character(character_id)
	var ability := catalog.ability(ability_id)
	return progress != null and progress.learn_ability(ability)

func change_profession(character_id: String, profession_id: String) -> bool:
	var progress := character(character_id)
	var next_profession := catalog.profession(profession_id)
	return progress != null and progress.change_profession(next_profession)

func equip_item(character_id: String, item_id: String) -> bool:
	var progress := character(character_id)
	return progress != null and progress.equip(catalog.equipment_item(item_id))

func unequip_item(character_id: String, slot_id: String) -> bool:
	var progress := character(character_id)
	return progress != null and progress.unequip(slot_id)

func equipped_resources(progress: CharacterProgress) -> Array[EquipmentItemData]:
	var result: Array[EquipmentItemData] = []
	if progress == null:
		return result
	for item_id in progress.equipped_items.values():
		var item := catalog.equipment_item(str(item_id))
		if item != null:
			result.append(item)
	return result

func equipment_bonuses(progress: CharacterProgress) -> Dictionary:
	var attributes := {}
	var derived := {}
	for item in equipped_resources(progress):
		for stat_id in item.attribute_bonuses:
			attributes[stat_id] = int(attributes.get(stat_id, 0)) + int(item.attribute_bonuses[stat_id])
		for stat_id in item.derived_bonuses:
			derived[stat_id] = int(derived.get(stat_id, 0)) + int(item.derived_bonuses[stat_id])
	return {"attributes": attributes, "derived": derived}

func award_mission(mission: MissionData, heroes: Array[UnitData]) -> Array[String]:
	var messages: Array[String] = []
	if completed_missions.has(mission.mission_id):
		return messages
	completed_missions.append(mission.mission_id)
	for hero in heroes:
		var progress := character(hero.unit_id)
		if progress == null:
			continue
		var result := progress.gain_experience(maxi(0, mission.reward_xp))
		messages.append("%s: +%d XP" % [progress.display_name, int(result.xp_gained)])
		if int(result.levels_gained) > 0:
			messages.append("¡%s subió %d nivel(es)! Nv. %d · +%d SP" % [
				progress.display_name, int(result.levels_gained), int(result.new_level), int(result.sp_gained),
			])
		apply_to_hero(hero, true)
	return messages

func xp_required(level: int) -> int:
	return ExperienceRules.xp_for_next_level(level)

func make_snapshot() -> Dictionary:
	var character_data := {}
	for character_id in characters:
		character_data[character_id] = (characters[character_id] as CharacterProgress).make_snapshot()
	return {
		"characters": character_data,
		"slot_ids": slot_ids.duplicate(),
		"formation_ids": formation_ids.duplicate(),
		"completed_missions": completed_missions.duplicate(),
	}

func restore(snapshot: Dictionary) -> void:
	initialize_new()
	var saved_characters: Dictionary = snapshot.get("characters", {})
	if not saved_characters.is_empty():
		for character_id in saved_characters:
			var data: Dictionary = saved_characters[character_id]
			var race_id := str(data.get("race_id", "human"))
			var race := catalog.race(race_id)
			if race == null:
				race = catalog.race("human")
			if characters.size() >= MAX_CHARACTERS:
				break
			var fallback_profession_id := str(race.allowed_initial_professions[0])
			var progress := CharacterProgress.new()
			characters[str(character_id)] = progress
			progress.restore(data, race)
			_sanitize_restored_character(progress, str(character_id), race, fallback_profession_id)
			if not data.has("inventory") and not data.has("equipped_items"):
				_grant_starter_items(progress)
	elif not snapshot.get("hero_progress", {}).is_empty():
		initialize_default()
		_restore_legacy_progress(snapshot.get("hero_progress", {}))
	var saved_slots: Array[String] = []
	saved_slots.assign(snapshot.get("slot_ids", []))
	for character_id in saved_slots:
		if characters.has(character_id) and not slot_ids.has(character_id):
			slot_ids.append(character_id)
	for character_id in characters:
		if slot_ids.size() >= MAX_CHARACTERS:
			break
		if not slot_ids.has(character_id):
			slot_ids.append(character_id)
	var saved_formation: Array[String] = []
	saved_formation.assign(snapshot.get("formation_ids", slot_ids))
	for character_id in saved_formation:
		if characters.has(character_id) and not formation_ids.has(character_id) and formation_ids.size() < MAX_CHARACTERS:
			formation_ids.append(character_id)
	if formation_ids.is_empty() and not slot_ids.is_empty():
		formation_ids = slot_ids.duplicate()
	completed_missions.assign(snapshot.get("completed_missions", []))

func _sanitize_restored_character(
	progress: CharacterProgress,
	character_id: String,
	race: RaceData,
	fallback_profession_id: String
) -> void:
	progress.character_id = character_id
	if progress.display_name.strip_edges().is_empty():
		progress.display_name = character_id
	progress.race_id = race.race_id
	var profession := catalog.profession(progress.profession_id)
	if profession == null or not _profession_is_valid_for_race(profession, race):
		progress.profession_id = fallback_profession_id
	var valid_history: Array[String] = []
	for profession_id in progress.profession_history:
		var historical_profession := catalog.profession(profession_id)
		if historical_profession != null and _profession_is_valid_for_race(historical_profession, race):
			valid_history.append(profession_id)
	if not valid_history.has(progress.profession_id):
		valid_history.append(progress.profession_id)
	progress.profession_history = valid_history
	var valid_abilities: Array[String] = []
	for ability_id in progress.learned_ability_ids:
		var ability := catalog.ability(ability_id)
		if ability != null and (ability.required_profession_ids.is_empty() or ability.required_profession_ids.any(
			func(required_id: String): return progress.has_profession(required_id)
		)):
			valid_abilities.append(ability_id)
	progress.learned_ability_ids = valid_abilities
	for attribute_id in StatCalculator.ATTRIBUTE_IDS:
		var fallback_value := int(race.base_attributes.get(attribute_id, 10))
		progress.base_attributes[attribute_id] = clampi(int(progress.base_attributes.get(attribute_id, fallback_value)), 1, 200)
	if catalog.appearance(progress.appearance_id) == null:
		progress.appearance_id = _initial_profession_id(progress)
	var valid_inventory := {}
	for item_id in progress.inventory:
		if catalog.equipment_item(str(item_id)) != null and int(progress.inventory[item_id]) > 0:
			valid_inventory[str(item_id)] = clampi(int(progress.inventory[item_id]), 1, 99)
	progress.inventory = valid_inventory
	var valid_equipped := {}
	for slot_id in progress.equipped_items:
		var item := catalog.equipment_item(str(progress.equipped_items[slot_id]))
		if item != null and item.slot_key() == str(slot_id) and item.can_be_used_by(progress):
			valid_equipped[str(slot_id)] = item.item_id
		elif item != null:
			progress.add_item(item.item_id)
	progress.equipped_items = valid_equipped

func _initial_profession_id(progress: CharacterProgress) -> String:
	return progress.profession_history[0] if not progress.profession_history.is_empty() else progress.profession_id

func _grant_starter_items(progress: CharacterProgress) -> void:
	var family := _initial_profession_id(progress)
	progress.appearance_id = family
	for item_id in STARTER_ITEMS.get(family, []):
		if catalog.equipment_item(str(item_id)) != null:
			progress.add_item(str(item_id))

func _profession_is_valid_for_race(profession: ProfessionData, race: RaceData) -> bool:
	var branch := profession
	while branch.previous_profession_id != "":
		if not branch.allows_race(race.race_id):
			return false
		branch = catalog.profession(branch.previous_profession_id)
		if branch == null:
			return false
	return branch.allows_race(race.race_id) and race.allows_profession(branch.profession_id)

func _restore_legacy_progress(legacy: Dictionary) -> void:
	for character_id in legacy:
		var progress := character(str(character_id))
		if progress == null:
			continue
		var old_data: Dictionary = legacy[character_id]
		var old_level := clampi(int(old_data.get("level", 1)), 1, ExperienceRules.MAX_LEVEL)
		progress.total_experience = ExperienceRules.total_xp_for_level(old_level) + maxi(0, int(old_data.get("xp", 0)))
		progress.total_experience = mini(progress.total_experience, ExperienceRules.total_xp_for_level(ExperienceRules.MAX_LEVEL))
		progress.level = ExperienceRules.level_for_total_xp(progress.total_experience)
		progress.sp_available = 0
		for gained_level in range(2, progress.level + 1):
			progress.sp_available += ExperienceRules.sp_for_level(gained_level)
