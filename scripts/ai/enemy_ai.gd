class_name EnemyAI
extends RefCounted

func choose_target(enemy: UnitData, heroes: Array[UnitData]) -> UnitData:
	var living := heroes.filter(func(hero: UnitData): return hero.is_alive())
	if living.is_empty():
		return null
	living.sort_custom(func(a: UnitData, b: UnitData):
		var distance_a := CombatRules.grid_distance(enemy.grid_position, a.grid_position)
		var distance_b := CombatRules.grid_distance(enemy.grid_position, b.grid_position)
		if distance_a == distance_b:
			return a.hp < b.hp
		return distance_a < distance_b
	)
	return living[0]

func choose_destination(enemy: UnitData, target: UnitData, reachable: Dictionary) -> Vector2i:
	var best_cell := enemy.grid_position
	var best_distance := CombatRules.grid_distance(best_cell, target.grid_position)
	for candidate: Vector2i in reachable:
		var distance := CombatRules.grid_distance(candidate, target.grid_position)
		if distance < best_distance:
			best_distance = distance
			best_cell = candidate
	return best_cell

func choose_attack(enemy: UnitData, target: UnitData, heights: Dictionary = {}, blocked: Dictionary = {}) -> BattleCommand:
	for ability in enemy.abilities:
		if CombatRules.can_use_ability(enemy, target, ability, heights, blocked):
			return BattleCommand.use_ability(enemy.unit_id, target.unit_id, ability.id)
	if CombatRules.can_basic_attack(enemy, target, heights, blocked):
		return BattleCommand.attack(enemy.unit_id, target.unit_id)
	return null
