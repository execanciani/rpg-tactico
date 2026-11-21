class_name StatCalculator
extends RefCounted

const ATTRIBUTE_IDS: Array[String] = ["STR", "DEX", "CON", "INT", "WIS", "MEN"]

static func calculate(
	character: CharacterProgress,
	race: RaceData,
	profession: ProfessionData,
	equipment_bonuses: Dictionary = {}
) -> Dictionary:
	# Cada atributo se reconstruye desde sus fuentes independientes. El crecimiento
	# suma growth/5 por nivel y nunca reutiliza el resultado de un cálculo anterior.
	var attributes := {}
	for attribute_id in ATTRIBUTE_IDS:
		var base_value := int(character.base_attributes.get(attribute_id, race.base_attributes.get(attribute_id, 10)))
		var racial_bonus := int(race.racial_modifiers.get(attribute_id, 0))
		var profession_bonus := int(profession.attribute_modifiers.get(attribute_id, 0))
		var growth_rate := int(profession.growth_attributes.get(attribute_id, 0))
		var level_bonus := int(floor(float(maxi(0, character.level - 1) * growth_rate) / 5.0))
		var equipment_attributes: Dictionary = equipment_bonuses.get("attributes", {})
		var equipment_bonus := int(equipment_attributes.get(attribute_id, 0))
		attributes[attribute_id] = maxi(1, base_value + racial_bonus + profession_bonus + level_bonus + equipment_bonus)
	var strength := int(attributes.STR)
	var dexterity := int(attributes.DEX)
	var constitution := int(attributes.CON)
	var intelligence := int(attributes.INT)
	var wisdom := int(attributes.WIS)
	var mentality := int(attributes.MEN)
	var level := character.level
	# Fórmulas deliberadamente lineales: facilitan el balance y mantienen visibles
	# las contribuciones de atributos y nivel. Equipo y estados se aplican después.
	var derived := {
		"max_hp": 38 + constitution * 6 + strength + level * 3,
		"max_mp": 8 + intelligence * 2 + wisdom * 3 + level,
		"physical_attack": 3 + strength * 2 + int(dexterity / 3.0) + level,
		"magical_attack": 2 + intelligence * 2 + int(wisdom / 2.0) + level,
		"physical_defense": 2 + constitution + int(strength / 3.0) + int(level / 2.0),
		"magical_defense": 2 + mentality + wisdom + int(level / 2.0),
		"accuracy": 65 + dexterity * 2 + level,
		"evasion": 3 + dexterity + int(wisdom / 3.0) + int(level / 4.0),
		"critical_chance": clampi(3 + int(dexterity * 0.65), 3, 35),
		"critical_damage": 145 + int(strength * 1.5),
		"speed": clampi(3 + int(dexterity / 2.0), 4, 14),
		"move_range": clampi(3 + int(dexterity / 8.0), 3, 6),
		"effect_resistance": clampi(mentality * 2 + int(constitution / 2.0), 0, 90),
	}
	for stat_id in profession.derived_modifiers:
		derived[stat_id] = int(derived.get(stat_id, 0)) + int(profession.derived_modifiers[stat_id])
	var equipment_derived: Dictionary = equipment_bonuses.get("derived", {})
	for stat_id in equipment_derived:
		derived[stat_id] = int(derived.get(stat_id, 0)) + int(equipment_derived[stat_id])
	return {"attributes": attributes, "derived": derived}
