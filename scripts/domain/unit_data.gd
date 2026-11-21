class_name UnitData
extends Resource

enum Team { HEROES, ENEMIES }

@export var unit_id := ""
@export var archetype_id := ""
@export var display_name := ""
@export var team: Team = Team.HEROES
@export var class_name_text := ""
@export var level := 1
@export var max_hp := 30
@export var hp := 30
@export var max_mp := 10
@export var mp := 10
@export var physical_attack := 8
@export var magical_attack := 4
@export var physical_defense := 4
@export var magical_defense := 3
@export var speed := 5
@export var move_range := 4
@export var max_climb := 1
@export var basic_attack_range := 1
@export var basic_attack_damage_type: AbilityData.DamageType = AbilityData.DamageType.PHYSICAL
@export var grid_position := Vector2i.ZERO
@export var elevation := 0
@export var abilities: Array[AbilityData] = []

var has_moved := false
var has_acted := false

func is_alive() -> bool:
	return hp > 0

func can_spend_mp(amount: int) -> bool:
	return mp >= amount

func begin_turn() -> void:
	has_moved = false
	has_acted = false

func make_snapshot() -> Dictionary:
	return {
		"unit_id": unit_id,
		"archetype_id": archetype_id,
		"display_name": display_name,
		"team": team,
		"class": class_name_text,
		"level": level,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"grid_position": {"x": grid_position.x, "y": grid_position.y},
		"elevation": elevation,
		"has_moved": has_moved,
		"has_acted": has_acted,
	}
