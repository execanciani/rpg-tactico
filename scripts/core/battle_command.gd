class_name BattleCommand
extends RefCounted

enum Type { MOVE, BASIC_ATTACK, USE_ABILITY, WAIT }

var type: Type
var actor_id: String
var target_cell: Vector2i
var target_unit_id: String
var ability_id: StringName

static func move(actor: String, cell: Vector2i) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = Type.MOVE
	command.actor_id = actor
	command.target_cell = cell
	return command

static func attack(actor: String, target: String) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = Type.BASIC_ATTACK
	command.actor_id = actor
	command.target_unit_id = target
	return command

static func use_ability(actor: String, target: String, selected_ability: StringName) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = Type.USE_ABILITY
	command.actor_id = actor
	command.target_unit_id = target
	command.ability_id = selected_ability
	return command

static func wait(actor: String) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = Type.WAIT
	command.actor_id = actor
	return command

func serialize() -> Dictionary:
	return {
		"type": type,
		"actor_id": actor_id,
		"target_cell": {"x": target_cell.x, "y": target_cell.y},
		"target_unit_id": target_unit_id,
		"ability_id": String(ability_id),
	}

func is_valid_for(active_actor_id: String) -> bool:
	if actor_id.is_empty() or actor_id != active_actor_id:
		return false
	match type:
		Type.MOVE:
			return true
		Type.BASIC_ATTACK:
			return not target_unit_id.is_empty()
		Type.USE_ABILITY:
			return not target_unit_id.is_empty() and not ability_id.is_empty()
		Type.WAIT:
			return true
	return false
