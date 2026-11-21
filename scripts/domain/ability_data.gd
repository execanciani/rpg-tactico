class_name AbilityData
extends Resource

enum DamageType { PHYSICAL, MAGICAL }
enum AbilityType { DAMAGE, STATUS, DAMAGE_AND_STATUS }
enum TargetType { ENEMY, ALLY, SELF }

@export var id: StringName = &""
@export var display_name := ""
@export var description := ""
@export var mp_cost := 0
@export var range_cells := 1
@export var power := 0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var ability_type: AbilityType = AbilityType.DAMAGE
@export var target_type: TargetType = TargetType.ENEMY
@export_range(0, 4) var area_radius := 0
@export_range(0, 10) var cooldown_turns := 0
@export_range(1, 4) var hit_count := 1
@export_range(0.1, 2.0, 0.05) var damage_scale := 1.0
@export_file("*.tres") var status_effect_path := ""
@export_range(0.0, 1.0) var status_chance := 1.0

func deals_damage() -> bool:
	return ability_type == AbilityType.DAMAGE or ability_type == AbilityType.DAMAGE_AND_STATUS

func applies_status() -> bool:
	return ability_type == AbilityType.STATUS or ability_type == AbilityType.DAMAGE_AND_STATUS

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
