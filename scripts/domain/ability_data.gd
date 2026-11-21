class_name AbilityData
extends Resource

enum DamageType { PHYSICAL, MAGICAL }

@export var id: StringName = &""
@export var display_name := ""
@export var description := ""
@export var mp_cost := 0
@export var range_cells := 1
@export var power := 0
@export var damage_type: DamageType = DamageType.PHYSICAL

static func create(
	ability_id: StringName,
	ability_name: String,
	cost: int,
	attack_range: int,
	ability_power: int,
	type: DamageType,
	ability_description: String = ""
) -> AbilityData:
	var ability := AbilityData.new()
	ability.id = ability_id
	ability.display_name = ability_name
	ability.mp_cost = cost
	ability.range_cells = attack_range
	ability.power = ability_power
	ability.damage_type = type
	ability.description = ability_description
	return ability
