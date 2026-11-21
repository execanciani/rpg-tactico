class_name CharacterProgress
extends Resource

@export var character_id := ""
@export var display_name := ""
@export var race_id := "human"
@export var profession_id := "warrior"
@export var profession_history: Array[String] = []
@export_range(1, ExperienceRules.MAX_LEVEL) var level := 1
@export var total_experience := 0
@export var sp_available := 0
@export var sp_spent := 0
@export var base_attributes: Dictionary = {}
@export var learned_ability_ids: Array[String] = []

func setup(id: String, name: String, selected_race: RaceData, initial_profession: String, initial_abilities: Array[String] = []) -> void:
	character_id = id
	display_name = name
	race_id = selected_race.race_id
	profession_id = initial_profession
	profession_history = [initial_profession]
	level = 1
	total_experience = 0
	sp_available = 0
	sp_spent = 0
	base_attributes = selected_race.base_attributes.duplicate(true)
	learned_ability_ids = initial_abilities.duplicate()

func gain_experience(amount: int) -> Dictionary:
	var safe_amount := clampi(amount, 0, ExperienceRules.MAX_EXPERIENCE_GAIN)
	var old_level := level
	var old_sp := sp_available
	var old_experience := total_experience
	if level < ExperienceRules.MAX_LEVEL:
		total_experience = mini(ExperienceRules.total_xp_for_level(ExperienceRules.MAX_LEVEL), total_experience + safe_amount)
		level = ExperienceRules.level_for_total_xp(total_experience)
		for gained_level in range(old_level + 1, level + 1):
			sp_available += ExperienceRules.sp_for_level(gained_level)
	return {
		"xp_gained": total_experience - old_experience,
		"levels_gained": level - old_level,
		"sp_gained": sp_available - old_sp,
		"new_level": level,
	}

func experience_into_level() -> int:
	return maxi(0, total_experience - ExperienceRules.total_xp_for_level(level))

func experience_to_next_level() -> int:
	return ExperienceRules.xp_for_next_level(level)

func has_profession(profession: String) -> bool:
	return profession_id == profession or profession_history.has(profession)

func can_learn(ability: AbilityData) -> bool:
	if ability == null or learned_ability_ids.has(String(ability.id)):
		return false
	if level < ability.required_level or sp_available < ability.sp_cost:
		return false
	if ability.required_profession_ids.is_empty():
		return true
	return ability.required_profession_ids.any(func(required_id: String): return has_profession(required_id))

func learn_ability(ability: AbilityData) -> bool:
	if not can_learn(ability):
		return false
	sp_available -= ability.sp_cost
	sp_spent += ability.sp_cost
	learned_ability_ids.append(String(ability.id))
	return true

func can_change_profession(next_profession: ProfessionData) -> bool:
	return next_profession != null \
		and next_profession.previous_profession_id == profession_id \
		and level >= next_profession.minimum_level \
		and next_profession.allows_race(race_id)

func change_profession(next_profession: ProfessionData) -> bool:
	if not can_change_profession(next_profession):
		return false
	profession_id = next_profession.profession_id
	if not profession_history.has(profession_id):
		profession_history.append(profession_id)
	return true

func make_snapshot() -> Dictionary:
	return {
		"character_id": character_id,
		"display_name": display_name,
		"race_id": race_id,
		"profession_id": profession_id,
		"profession_history": profession_history.duplicate(),
		"level": level,
		"total_experience": total_experience,
		"sp_available": sp_available,
		"sp_spent": sp_spent,
		"base_attributes": base_attributes.duplicate(true),
		"learned_ability_ids": learned_ability_ids.duplicate(),
	}

func restore(snapshot: Dictionary, fallback_race: RaceData) -> void:
	character_id = str(snapshot.get("character_id", character_id))
	display_name = str(snapshot.get("display_name", display_name))
	race_id = str(snapshot.get("race_id", fallback_race.race_id))
	profession_id = str(snapshot.get("profession_id", "warrior"))
	profession_history.assign(snapshot.get("profession_history", [profession_id]))
	if profession_history.is_empty():
		profession_history.append(profession_id)
	total_experience = clampi(int(snapshot.get("total_experience", 0)), 0, ExperienceRules.total_xp_for_level(ExperienceRules.MAX_LEVEL))
	level = ExperienceRules.level_for_total_xp(total_experience)
	sp_available = clampi(int(snapshot.get("sp_available", 0)), 0, 10000)
	sp_spent = clampi(int(snapshot.get("sp_spent", 0)), 0, 10000)
	base_attributes = snapshot.get("base_attributes", fallback_race.base_attributes).duplicate(true)
	learned_ability_ids.assign(snapshot.get("learned_ability_ids", []))
