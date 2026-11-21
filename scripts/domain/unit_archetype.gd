class_name UnitArchetype
extends Resource

@export var archetype_id := ""
@export var default_name := ""
@export var class_name_text := ""
@export var level := 1
@export var max_hp := 30
@export var max_mp := 10
@export var physical_attack := 8
@export var magical_attack := 4
@export var physical_defense := 4
@export var magical_defense := 3
@export var speed := 5
@export var move_range := 4
@export var max_climb := 1
@export var basic_attack_range := 1
@export var basic_attack_damage_type: AbilityData.DamageType = AbilityData.DamageType.PHYSICAL
@export var ability_paths: Array[String] = []

func instantiate(unit_id: String, team: UnitData.Team, cell: Vector2i, custom_name := "") -> UnitData:
	var unit := UnitData.new()
	unit.archetype_id = archetype_id
	unit.unit_id = unit_id
	unit.display_name = custom_name if not custom_name.is_empty() else default_name
	unit.team = team
	unit.class_name_text = class_name_text
	unit.level = level
	unit.max_hp = max_hp
	unit.hp = max_hp
	unit.max_mp = max_mp
	unit.mp = max_mp
	unit.physical_attack = physical_attack
	unit.magical_attack = magical_attack
	unit.physical_defense = physical_defense
	unit.magical_defense = magical_defense
	unit.speed = speed
	unit.move_range = move_range
	unit.max_climb = max_climb
	unit.basic_attack_range = basic_attack_range
	unit.basic_attack_damage_type = basic_attack_damage_type
	unit.grid_position = cell
	for path in ability_paths:
		var ability := load(path) as AbilityData
		if ability != null:
			unit.abilities.append(ability)
	return unit
