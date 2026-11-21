class_name UnitData
extends Resource

enum Team { HEROES, ENEMIES }

@export var unit_id := ""
@export var archetype_id := ""
@export var display_name := ""
@export var team: Team = Team.HEROES
@export var class_name_text := ""
@export var level := 1
@export var xp := 0
@export var xp_to_next := 100
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
var active_statuses: Array[Dictionary] = []
var equipped_summary := "Sin equipo"

func is_alive() -> bool:
	return hp > 0

func can_spend_mp(amount: int) -> bool:
	return mp >= amount

func begin_turn() -> void:
	has_moved = false
	has_acted = false

func effective_move_range() -> int:
	var modifier := 0
	for entry in active_statuses:
		var effect := load(str(entry.get("path", ""))) as StatusEffectData
		if effect != null:
			modifier += effect.move_modifier
	return maxi(1, move_range + modifier)

func add_status(effect: StatusEffectData) -> void:
	if effect == null or effect.resource_path.is_empty():
		return
	for index in active_statuses.size():
		if str(active_statuses[index].get("path", "")) == effect.resource_path:
			active_statuses[index]["remaining"] = effect.duration_turns
			return
	active_statuses.append({"path": effect.resource_path, "remaining": effect.duration_turns})

func process_status_turn() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for index in range(active_statuses.size() - 1, -1, -1):
		var entry: Dictionary = active_statuses[index]
		var effect := load(str(entry.get("path", ""))) as StatusEffectData
		if effect == null:
			active_statuses.remove_at(index)
			continue
		if effect.damage_per_turn > 0 and is_alive():
			var damage := mini(hp, effect.damage_per_turn)
			hp -= damage
			events.append({"name": effect.display_name, "damage": damage, "color": effect.color})
		entry["remaining"] = int(entry.get("remaining", 1)) - 1
		if int(entry.remaining) <= 0:
			active_statuses.remove_at(index)
		else:
			active_statuses[index] = entry
	return events

func status_summary() -> String:
	var names: Array[String] = []
	for entry in active_statuses:
		var effect := load(str(entry.get("path", ""))) as StatusEffectData
		if effect != null:
			names.append("%s (%d)" % [effect.display_name, int(entry.get("remaining", 0))])
	return ", ".join(names) if not names.is_empty() else "Sin estados"

func make_snapshot() -> Dictionary:
	return {
		"unit_id": unit_id,
		"archetype_id": archetype_id,
		"display_name": display_name,
		"team": team,
		"class": class_name_text,
		"level": level,
		"xp": xp,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"grid_position": {"x": grid_position.x, "y": grid_position.y},
		"elevation": elevation,
		"has_moved": has_moved,
		"has_acted": has_acted,
		"active_statuses": active_statuses.duplicate(true),
	}
