class_name CombatRules
extends RefCounted

static func grid_distance(origin: Vector2i, target: Vector2i) -> int:
	return abs(origin.x - target.x) + abs(origin.y - target.y)

static func can_basic_attack(attacker: UnitData, defender: UnitData, heights: Dictionary = {}, blocked: Dictionary = {}) -> bool:
	if attacker == null or defender == null:
		return false
	return (
		attacker.is_alive()
		and defender.is_alive()
		and attacker.team != defender.team
		and effective_distance(attacker.grid_position, defender.grid_position, heights) <= attacker.basic_attack_range
		and has_line_of_sight(attacker.grid_position, defender.grid_position, heights, blocked)
	)

static func can_use_ability(attacker: UnitData, defender: UnitData, ability: AbilityData, heights: Dictionary = {}, blocked: Dictionary = {}) -> bool:
	if attacker == null or defender == null or ability == null:
		return false
	var valid_target := false
	match ability.target_type:
		AbilityData.TargetType.ENEMY:
			valid_target = attacker.team != defender.team
		AbilityData.TargetType.ALLY:
			valid_target = attacker.team == defender.team
		AbilityData.TargetType.SELF:
			valid_target = attacker == defender
	return (
		attacker.is_alive()
		and defender.is_alive()
		and valid_target
		and attacker.can_spend_mp(ability.mp_cost)
		and attacker.is_ability_ready(ability.id)
		and effective_distance(attacker.grid_position, defender.grid_position, heights) <= ability.range_cells
		and has_line_of_sight(attacker.grid_position, defender.grid_position, heights, blocked)
	)

static func basic_attack_damage(attacker: UnitData, defender: UnitData, heights: Dictionary = {}) -> int:
	var height_bonus: int = _height_bonus(attacker, defender, heights)
	if attacker.basic_attack_damage_type == AbilityData.DamageType.MAGICAL:
		return maxi(1, attacker.magical_attack - int(defender.effective_magical_defense() * 0.55) + height_bonus)
	return maxi(1, attacker.physical_attack - int(defender.effective_physical_defense() * 0.55) + height_bonus)

static func ability_damage(attacker: UnitData, defender: UnitData, ability: AbilityData, heights: Dictionary = {}) -> int:
	var height_bonus: int = _height_bonus(attacker, defender, heights)
	if ability.damage_type == AbilityData.DamageType.MAGICAL:
		return maxi(1, roundi((attacker.magical_attack + ability.power - int(defender.effective_magical_defense() * 0.5) + height_bonus) * ability.damage_scale))
	return maxi(1, roundi((attacker.physical_attack + ability.power - int(defender.effective_physical_defense() * 0.5) + height_bonus) * ability.damage_scale))

static func battle_winner(units: Array[UnitData]) -> int:
	var heroes_alive := units.any(func(unit: UnitData): return unit.team == UnitData.Team.HEROES and unit.is_alive())
	var enemies_alive := units.any(func(unit: UnitData): return unit.team == UnitData.Team.ENEMIES and unit.is_alive())
	if heroes_alive and not enemies_alive:
		return UnitData.Team.HEROES
	if enemies_alive and not heroes_alive:
		return UnitData.Team.ENEMIES
	return -1

static func apply_damage(target: UnitData, amount: int) -> int:
	var applied: int = mini(target.hp, maxi(0, amount))
	target.hp -= applied
	return applied

static func effective_distance(origin: Vector2i, target: Vector2i, heights: Dictionary = {}) -> int:
	var vertical: int = absi(int(heights.get(origin, 0)) - int(heights.get(target, 0)))
	return grid_distance(origin, target) + maxi(0, vertical - 1)

static func has_line_of_sight(origin: Vector2i, target: Vector2i, heights: Dictionary = {}, blocked: Dictionary = {}) -> bool:
	if origin == target:
		return true
	var cells: Array[Vector2i] = _line_cells(origin, target)
	var origin_eye: float = float(heights.get(origin, 0)) + 1.2
	var target_eye: float = float(heights.get(target, 0)) + 1.2
	for index in range(1, cells.size() - 1):
		var cell: Vector2i = cells[index]
		if blocked.has(cell):
			return false
		var progress: float = float(index) / float(cells.size() - 1)
		var ray_height: float = lerpf(origin_eye, target_eye, progress)
		if float(heights.get(cell, 0)) + 0.65 > ray_height:
			return false
	return true

static func _line_cells(origin: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var x := origin.x
	var y := origin.y
	var dx: int = absi(target.x - origin.x)
	var step_x := 1 if origin.x < target.x else -1
	var dy: int = -absi(target.y - origin.y)
	var step_y := 1 if origin.y < target.y else -1
	var error: int = dx + dy
	while true:
		result.append(Vector2i(x, y))
		if x == target.x and y == target.y:
			break
		var doubled: int = 2 * error
		if doubled >= dy:
			error += dy
			x += step_x
		if doubled <= dx:
			error += dx
			y += step_y
	return result

static func _height_bonus(attacker: UnitData, defender: UnitData, heights: Dictionary) -> int:
	var difference: int = int(heights.get(attacker.grid_position, 0)) - int(heights.get(defender.grid_position, 0))
	return clampi(difference * 2, -2, 4)
