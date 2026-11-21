class_name BattleSimulator
extends RefCounted

const HERO_PATHS: Array[String] = [
	"res://data/archetypes/hero_warrior.tres",
	"res://data/archetypes/hero_mage.tres",
	"res://data/archetypes/hero_archer.tres",
]

static func simulate_mission(mission: MissionData, maximum_rounds := 80) -> Dictionary:
	var heroes: Array[UnitData] = []
	var enemies: Array[UnitData] = []
	var profile := CampaignProfile.new()
	profile.initialize_default()
	for index in mini(HERO_PATHS.size(), mission.hero_positions.size()):
		var archetype := load(HERO_PATHS[index]) as UnitArchetype
		var hero := archetype.instantiate(archetype.archetype_id, UnitData.Team.HEROES, mission.hero_positions[index])
		profile.apply_to_hero(hero)
		heroes.append(hero)
	for index in mini(mission.enemy_archetype_paths.size(), mission.enemy_positions.size()):
		var archetype := load(mission.enemy_archetype_paths[index]) as UnitArchetype
		enemies.append(archetype.instantiate("enemy_%02d" % index, UnitData.Team.ENEMIES, mission.enemy_positions[index]))
	var heights := mission.height_map()
	var blocked := mission.blocked_map()
	var actions := 0
	var completed_rounds := 0
	var all_units: Array[UnitData] = []
	all_units.append_array(heroes)
	all_units.append_array(enemies)
	var turn_manager := TurnManager.new()
	turn_manager.start(all_units)
	while turn_manager.round_number <= maximum_rounds and not turn_manager.active_unit_id.is_empty():
		completed_rounds = turn_manager.round_number
		var actor := _unit_by_id(turn_manager.active_unit_id, all_units)
		if actor != null and actor.is_alive():
			actor.begin_turn()
			actor.process_status_turn()
		if actor != null and actor.is_alive():
			var opponents := enemies if actor.team == UnitData.Team.HEROES else heroes
			var target := _nearest_target(actor, opponents)
			if target != null and not _can_attack(actor, target, heights, blocked):
				var reachable := GridPathfinder.reachable_cells(
					actor.grid_position, actor.effective_move_range(), IsometricGrid.MAP_SIZE,
					blocked, _occupied(heroes, enemies), heights, actor.max_climb
				)
				var destination := _best_destination(actor, target, reachable, heights, blocked)
				if destination != actor.grid_position:
					actor.grid_position = destination
					actor.elevation = int(heights.get(destination, 0))
					actions += 1
			target = _nearest_target(actor, opponents)
			if target != null and _apply_best_attack(actor, target, heights, blocked):
				actions += 1
		if not heroes.any(func(unit: UnitData): return unit.is_alive()):
			return {"finished": true, "winner": UnitData.Team.ENEMIES, "rounds": completed_rounds, "actions": actions}
		if _heroes_completed_objective(mission, heroes, enemies, completed_rounds, false):
			return {"finished": true, "winner": UnitData.Team.HEROES, "rounds": completed_rounds, "actions": actions}
		var began_new_round := turn_manager.complete_active_turn(all_units)
		if began_new_round and _heroes_completed_objective(mission, heroes, enemies, completed_rounds, true):
			return {"finished": true, "winner": UnitData.Team.HEROES, "rounds": completed_rounds, "actions": actions}
	return {"finished": false, "winner": -1, "rounds": completed_rounds, "actions": actions}

static func _unit_by_id(unit_id: String, units: Array[UnitData]) -> UnitData:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

static func _apply_best_attack(actor: UnitData, target: UnitData, heights: Dictionary, blocked: Dictionary) -> bool:
	for ability in actor.abilities:
		if CombatRules.can_use_ability(actor, target, ability, heights, blocked):
			actor.mp -= ability.mp_cost
			actor.start_ability_cooldown(ability)
			if ability.deals_damage():
				for hit_index in ability.hit_count:
					if target.is_alive():
						CombatRules.apply_damage(target, CombatRules.ability_damage(actor, target, ability, heights))
			if ability.applies_status() and not ability.status_effect_path.is_empty() and target.is_alive():
				target.add_status(load(ability.status_effect_path) as StatusEffectData)
			return true
	if CombatRules.can_basic_attack(actor, target, heights, blocked):
		CombatRules.apply_damage(target, CombatRules.basic_attack_damage(actor, target, heights))
		return true
	return false

static func _can_attack(actor: UnitData, target: UnitData, heights: Dictionary, blocked: Dictionary) -> bool:
	if CombatRules.can_basic_attack(actor, target, heights, blocked):
		return true
	for ability in actor.abilities:
		if CombatRules.can_use_ability(actor, target, ability, heights, blocked):
			return true
	return false

static func _nearest_target(actor: UnitData, opponents: Array[UnitData]) -> UnitData:
	var best: UnitData
	var best_distance := 9999
	for candidate in opponents:
		if not candidate.is_alive():
			continue
		var distance := CombatRules.grid_distance(actor.grid_position, candidate.grid_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best

static func _best_destination(actor: UnitData, target: UnitData, reachable: Dictionary, heights: Dictionary, blocked: Dictionary) -> Vector2i:
	var best := actor.grid_position
	var best_score := 9999
	for candidate_value in reachable.keys():
		var candidate: Vector2i = candidate_value
		var score := CombatRules.effective_distance(candidate, target.grid_position, heights) * 10
		if not CombatRules.has_line_of_sight(candidate, target.grid_position, heights, blocked):
			score += 7
		if score < best_score:
			best = candidate
			best_score = score
	return best

static func _occupied(heroes: Array[UnitData], enemies: Array[UnitData]) -> Dictionary:
	var result := {}
	for unit in heroes + enemies:
		if unit.is_alive():
			result[unit.grid_position] = true
	return result

static func _heroes_completed_objective(
	mission: MissionData,
	heroes: Array[UnitData],
	enemies: Array[UnitData],
	round_number: int,
	after_enemy_turn: bool
) -> bool:
	if not enemies.any(func(unit: UnitData): return unit.is_alive()):
		return true
	if mission.objective_type == MissionData.ObjectiveType.REACH_CELL:
		return heroes.any(func(unit: UnitData): return unit.is_alive() and unit.grid_position == mission.objective_cell)
	if mission.objective_type == MissionData.ObjectiveType.SURVIVE_ROUNDS:
		return after_enemy_turn and round_number >= mission.survive_rounds
	return false
