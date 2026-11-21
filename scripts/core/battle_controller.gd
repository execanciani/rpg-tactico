class_name BattleController
extends Node2D

enum Phase { PLAYER, ENEMY, FINISHED }
enum SelectionMode { NONE, MOVE, ATTACK, SKILL }

@onready var grid: IsometricGrid = $IsometricGrid
@onready var units_layer: Node2D = $Units
@onready var effects_layer: Node2D = $Effects
@onready var tactical_camera: TacticalCamera = $Camera2D
@onready var ui: BattleUI = $Interface/BattleUI
@onready var character_selection: CharacterSelectionScreen = $Interface/CharacterSelectionScreen

var phase := Phase.PLAYER
var selection_mode := SelectionMode.NONE
var round_number := 1
var selected_unit: TacticalUnit
var unit_views: Array[TacticalUnit] = []
var hero_views: Array[TacticalUnit] = []
var enemy_views: Array[TacticalUnit] = []
var input_locked := false
var battle_won := false
var enemy_ai := EnemyAI.new()
var turn_manager := TurnManager.new()
var selected_ability: AbilityData
var campaign := CampaignManager.new()
var mission: MissionData
var pending_dialogue := ""
var reward_messages: Array[String] = []
var rewards_awarded := false
var progression_open := false

func _ready() -> void:
	grid.cell_pressed.connect(_on_cell_pressed)
	grid.cell_hovered.connect(_on_cell_hovered)
	ui.move_requested.connect(_on_move_requested)
	ui.attack_requested.connect(_on_attack_requested)
	ui.skill_requested.connect(_on_skill_requested)
	ui.wait_requested.connect(_on_wait_requested)
	ui.ability_selected.connect(_on_ability_selected)
	ui.progression_requested.connect(_on_progression_requested)
	ui.learn_skill_requested.connect(_on_learn_skill_requested)
	ui.profession_change_requested.connect(_on_profession_change_requested)
	ui.progression_closed.connect(_on_progression_closed)
	ui.save_requested.connect(_on_save_requested)
	ui.load_requested.connect(_on_load_requested)
	ui.continue_requested.connect(_on_continue_requested)
	ui.dialogue_finished.connect(_on_dialogue_finished)
	character_selection.create_requested.connect(_on_roster_create_requested)
	character_selection.delete_requested.connect(_on_roster_delete_requested)
	character_selection.formation_toggle_requested.connect(_on_roster_toggle_requested)
	character_selection.adventure_requested.connect(_on_adventure_requested)
	campaign.load_catalog()
	_load_profile_for_selection()
	ui.visible = false
	character_selection.configure(campaign.profile)

func _load_profile_for_selection() -> void:
	var payload := SaveSystem.load_game()
	if payload.is_empty():
		campaign.profile.initialize_new()
		return
	campaign.current_mission_index = clampi(int(payload.get("mission_index", 0)), 0, maxi(0, campaign.missions.size() - 1))
	if payload.has("profile"):
		campaign.profile.restore(payload.get("profile", {}))
	else:
		campaign.profile.initialize_default()

func _on_roster_create_requested(character_name: String, race_id: String, profession_id: String) -> void:
	var validation_error := campaign.profile.validate_character_name(character_name)
	if not validation_error.is_empty():
		character_selection.show_creation_error(validation_error)
		return
	var character := campaign.profile.create_character_auto(character_name, race_id, profession_id)
	if character == null:
		character_selection.show_creation_error("No se pudo crear el personaje con esa raza y profesión.")
		return
	_save_roster()
	character_selection.creation_succeeded()

func _on_roster_delete_requested(character_id: String) -> void:
	if campaign.profile.delete_character(character_id):
		_save_roster()
		character_selection.refresh()

func _on_roster_toggle_requested(character_id: String) -> void:
	if campaign.profile.toggle_formation_character(character_id):
		_save_roster()
	character_selection.refresh()

func _on_adventure_requested() -> void:
	if campaign.profile.formation_ids.is_empty():
		return
	_save_roster()
	character_selection.visible = false
	ui.visible = true
	_start_mission(campaign.current_mission_index)

func _save_roster() -> bool:
	return SaveSystem.save_game({
		"mission_index": campaign.current_mission_index,
		"profile": campaign.profile.make_snapshot(),
	})

func _unhandled_input(event: InputEvent) -> void:
	if input_locked or phase != Phase.PLAYER or selected_unit == null:
		return
	if event.is_action_pressed("action_move"):
		_on_move_requested()
	elif event.is_action_pressed("action_attack"):
		_on_attack_requested()
	elif event.is_action_pressed("action_skill"):
		_on_skill_requested()
	elif event.is_action_pressed("action_wait"):
		_on_wait_requested()
	elif event.is_action_pressed("ui_cancel"):
		_set_selection_mode(SelectionMode.NONE)

func _start_mission(index: int, announce := true, begin_turn := true) -> void:
	if campaign.missions.is_empty():
		push_error("La campaña no contiene misiones válidas.")
		return
	campaign.current_mission_index = clampi(index, 0, campaign.missions.size() - 1)
	mission = campaign.current_mission()
	_clear_battlefield()
	grid.configure(mission)
	tactical_camera.reset_view()
	for hero_index in mini(campaign.profile.formation_ids.size(), mission.hero_positions.size()):
		var character_id := campaign.profile.formation_ids[hero_index]
		var archetype := load(campaign.profile.battle_archetype_path(character_id)) as UnitArchetype
		if archetype == null or hero_index >= mission.hero_positions.size():
			continue
		var hero := archetype.instantiate(character_id, UnitData.Team.HEROES, mission.hero_positions[hero_index])
		campaign.profile.apply_to_hero(hero)
		_spawn_unit(hero)
	for enemy_index in mission.enemy_archetype_paths.size():
		if enemy_index >= mission.enemy_positions.size():
			break
		var archetype := load(mission.enemy_archetype_paths[enemy_index]) as UnitArchetype
		if archetype == null:
			continue
		var unit_id := "%s_%02d" % [archetype.archetype_id, enemy_index]
		_spawn_unit(archetype.instantiate(unit_id, UnitData.Team.ENEMIES, mission.enemy_positions[enemy_index]))
	round_number = 1
	battle_won = false
	rewards_awarded = false
	reward_messages.clear()
	input_locked = false
	ui.hide_result()
	ui.hide_progression()
	if progression_open:
		ui.hide_progression()
	ui.set_mission(mission.title, campaign.current_mission_index + 1, campaign.missions.size())
	ui.set_objective(mission.objective_text)
	turn_manager.start(_unit_data(), 1)
	ui.set_hint(mission.briefing)
	if announce and not mission.intro_dialogue.is_empty():
		pending_dialogue = "intro"
		input_locked = true
		ui.show_dialogue(mission.intro_dialogue)
	elif begin_turn:
		_begin_active_turn(false)
	if announce:
		ui.show_message("Misión: %s" % mission.title, Color("#9fe0bd"))

func _clear_battlefield() -> void:
	selected_unit = null
	selected_ability = null
	unit_views.clear()
	hero_views.clear()
	enemy_views.clear()
	for child in units_layer.get_children():
		child.free()
	for child in effects_layer.get_children():
		child.free()
	grid.clear_highlights()

func _spawn_unit(unit_data: UnitData) -> void:
	unit_data.elevation = grid.get_height(unit_data.grid_position)
	var view := TacticalUnit.new()
	view.name = unit_data.unit_id
	units_layer.add_child(view)
	view.setup(unit_data, grid.grid_to_world(unit_data.grid_position))
	unit_views.append(view)
	if unit_data.team == UnitData.Team.HEROES:
		hero_views.append(view)
	else:
		enemy_views.append(view)

func _on_cell_pressed(cell: Vector2i) -> void:
	if input_locked or phase != Phase.PLAYER:
		return
	if selection_mode == SelectionMode.MOVE:
		_try_move_to(cell)
		return
	if selection_mode == SelectionMode.ATTACK:
		_try_attack_at(cell, false)
		return
	if selection_mode == SelectionMode.SKILL:
		_try_attack_at(cell, true)
		return
	var clicked := _living_unit_at(cell)
	if clicked != null and clicked.data.team == UnitData.Team.HEROES:
		if clicked.data.unit_id != turn_manager.active_unit_id:
			ui.show_message("Ahora actúa %s." % _active_unit_name(), Color("#ffdc89"))
			ui.show_unit(clicked.data)
			return
		if clicked.data.has_acted:
			ui.show_message("%s ya actuó esta ronda." % clicked.data.display_name, Color("#ffdc89"))
			ui.show_unit(clicked.data)
			return
		_select_unit(clicked)
	elif clicked != null:
		ui.show_unit(clicked.data)
		ui.set_hint("Unidad enemiga · seleccioná un héroe para actuar")

func _on_cell_hovered(cell: Vector2i) -> void:
	if selection_mode != SelectionMode.MOVE or selected_unit == null or not grid.highlighted_cells.has(cell):
		grid.show_path_preview([])
		return
	var path := GridPathfinder.find_path(
		selected_unit.data.grid_position, cell, IsometricGrid.MAP_SIZE,
		grid.blocked_cells, _occupied_cells(), selected_unit.data.effective_move_range(),
		grid.height_cells, selected_unit.data.max_climb
	)
	grid.show_path_preview(path)

func _select_unit(view: TacticalUnit) -> void:
	_clear_selection_visuals()
	selected_unit = view
	selected_unit.set_selected(true)
	grid.set_selected(view.data.grid_position)
	ui.show_unit(view.data)
	ui.configure_actions(view.data, true)
	ui.set_hint("Elegí una acción · la altura modifica movimiento, alcance y daño")
	selection_mode = SelectionMode.NONE

func _clear_selection_visuals() -> void:
	for view in unit_views:
		view.set_selected(false)
		view.set_targeted(false)
	grid.clear_highlights()
	grid.set_selected(Vector2i(-1, -1))

func _deselect_unit() -> void:
	_clear_selection_visuals()
	selected_unit = null
	selection_mode = SelectionMode.NONE
	ui.show_unit(null)
	ui.configure_actions(null, false)
	if phase == Phase.PLAYER:
		ui.set_hint("Esperando la acción de la unidad activa")

func _on_move_requested() -> void:
	if not _selection_can_act() or selected_unit.data.has_moved:
		return
	_set_selection_mode(SelectionMode.MOVE)
	var reachable := GridPathfinder.reachable_cells(
		selected_unit.data.grid_position, selected_unit.data.effective_move_range(),
		IsometricGrid.MAP_SIZE, grid.blocked_cells, _occupied_cells(),
		grid.height_cells, selected_unit.data.max_climb
	)
	reachable.erase(selected_unit.data.grid_position)
	var cells: Array[Vector2i] = []
	cells.assign(reachable.keys())
	grid.show_highlights(cells, IsometricGrid.Highlight.MOVE)
	ui.set_hint("Casillas azules · subir consume movimiento adicional")

func _on_attack_requested() -> void:
	if not _selection_can_act():
		return
	_set_selection_mode(SelectionMode.ATTACK)
	_show_range(selected_unit.data.basic_attack_range, IsometricGrid.Highlight.ATTACK)
	ui.set_hint("Área roja visible · rocas y crestas bloquean disparos")

func _on_skill_requested() -> void:
	if not _selection_can_act() or selected_unit.data.abilities.is_empty():
		return
	ui.show_abilities(selected_unit.data)

func _on_ability_selected(ability_id: StringName) -> void:
	if not _selection_can_act():
		return
	selected_ability = _ability_by_id(selected_unit.data, ability_id)
	if selected_ability == null:
		return
	if not selected_unit.data.can_spend_mp(selected_ability.mp_cost):
		ui.show_message("MP insuficiente.", Color("#8dd7ff"))
		return
	if not selected_unit.data.is_ability_ready(selected_ability.id):
		ui.show_message("La habilidad sigue en enfriamiento.", Color("#ffcf88"))
		return
	if selected_ability.target_type == AbilityData.TargetType.SELF:
		_execute_attack(BattleCommand.use_ability(selected_unit.data.unit_id, selected_unit.data.unit_id, selected_ability.id), true)
		return
	_set_selection_mode(SelectionMode.SKILL)
	_show_ability_range(selected_ability)
	ui.set_hint("%s · %d MP · alcance %d" % [selected_ability.display_name, selected_ability.mp_cost, selected_ability.range_cells])

func _on_wait_requested() -> void:
	if not _selection_can_act():
		return
	selected_unit.data.has_acted = true
	selected_unit.refresh()
	ui.show_message("%s espera." % selected_unit.data.display_name, Color("#d7dde0"))
	_finish_player_action()

func _on_progression_requested() -> void:
	if input_locked or phase != Phase.PLAYER:
		ui.show_message("La progresión se gestiona durante un turno disponible.", Color("#ffcf88"))
		return
	progression_open = true
	input_locked = true
	ui.show_progression(campaign.profile, selected_unit.data.archetype_id if selected_unit != null else "")

func _on_learn_skill_requested(character_id: String, ability_id: String) -> void:
	if not progression_open or phase != Phase.PLAYER:
		return
	if not campaign.profile.learn_ability(character_id, ability_id):
		ui.show_message("No se cumplen los requisitos de aprendizaje.", Color("#ffcf88"))
		return
	_sync_character_view(character_id)
	ui.show_message("Habilidad aprendida.", Color("#9fe0bd"))
	ui.show_progression(campaign.profile, character_id, "skills")

func _on_profession_change_requested(character_id: String, profession_id: String) -> void:
	if not progression_open or phase != Phase.PLAYER:
		return
	if not campaign.profile.change_profession(character_id, profession_id):
		ui.show_message("No se cumplen los requisitos de profesión.", Color("#ffcf88"))
		return
	_sync_character_view(character_id)
	var progress := campaign.profile.character(character_id)
	var profession := campaign.profile.catalog.profession(progress.profession_id)
	ui.show_message("%s ahora es %s." % [progress.display_name, profession.display_name], Color("#ffe195"))
	ui.show_progression(campaign.profile, character_id, "profession")

func _on_progression_closed() -> void:
	progression_open = false
	if phase == Phase.PLAYER:
		input_locked = false

func _sync_character_view(character_id: String) -> void:
	var view := _unit_by_id(character_id)
	if view == null:
		return
	campaign.profile.apply_to_hero(view.data, true)
	view.refresh()
	if selected_unit == view:
		ui.show_unit(view.data)
		ui.configure_actions(view.data, true)

func _set_selection_mode(mode: SelectionMode) -> void:
	selection_mode = mode
	grid.clear_highlights()
	for view in unit_views:
		view.set_targeted(false)
	if mode != SelectionMode.SKILL:
		selected_ability = null
	if mode == SelectionMode.NONE and selected_unit != null:
		ui.set_hint("Elegí una acción")

func _show_range(attack_range: int, highlight: IsometricGrid.Highlight) -> void:
	var cells: Array[Vector2i] = []
	for x in range(IsometricGrid.MAP_SIZE.x):
		for y in range(IsometricGrid.MAP_SIZE.y):
			var cell := Vector2i(x, y)
			if cell == selected_unit.data.grid_position:
				continue
			if CombatRules.effective_distance(selected_unit.data.grid_position, cell, grid.height_cells) <= attack_range \
			and CombatRules.has_line_of_sight(selected_unit.data.grid_position, cell, grid.height_cells, grid.blocked_cells):
				cells.append(cell)
	grid.show_highlights(cells, highlight)
	for enemy in enemy_views:
		if enemy.data.is_alive() and cells.has(enemy.data.grid_position):
			enemy.set_targeted(true)

func _show_ability_range(ability: AbilityData) -> void:
	var cells: Array[Vector2i] = []
	for x in range(IsometricGrid.MAP_SIZE.x):
		for y in range(IsometricGrid.MAP_SIZE.y):
			var cell := Vector2i(x, y)
			if CombatRules.effective_distance(selected_unit.data.grid_position, cell, grid.height_cells) <= ability.range_cells \
			and CombatRules.has_line_of_sight(selected_unit.data.grid_position, cell, grid.height_cells, grid.blocked_cells):
				cells.append(cell)
	grid.show_highlights(cells, IsometricGrid.Highlight.SKILL)
	for view in unit_views:
		if not view.data.is_alive() or not cells.has(view.data.grid_position):
			continue
		var valid_team := ability.target_type == AbilityData.TargetType.ENEMY and view.data.team != selected_unit.data.team
		valid_team = valid_team or (ability.target_type == AbilityData.TargetType.ALLY and view.data.team == selected_unit.data.team)
		view.set_targeted(valid_team)

func _try_move_to(cell: Vector2i) -> void:
	if not grid.highlighted_cells.has(cell):
		ui.show_message("Esa casilla no es alcanzable.", Color("#ffb28e"))
		return
	var path := GridPathfinder.find_path(
		selected_unit.data.grid_position, cell, IsometricGrid.MAP_SIZE,
		grid.blocked_cells, _occupied_cells(), selected_unit.data.effective_move_range(),
		grid.height_cells, selected_unit.data.max_climb
	)
	if path.is_empty():
		ui.show_message("No hay un camino válido.", Color("#ffb28e"))
		return
	_execute_move(BattleCommand.move(selected_unit.data.unit_id, cell), path, true)

func _execute_move(command: BattleCommand, path: Array[Vector2i], player_action: bool) -> void:
	if not command.is_valid_for(turn_manager.active_unit_id):
		return
	var actor := _unit_by_id(command.actor_id)
	if actor == null or not actor.data.is_alive() or not grid.is_inside(command.target_cell) or grid.is_blocked(command.target_cell):
		return
	var validated_path := GridPathfinder.find_path(
		actor.data.grid_position, command.target_cell, IsometricGrid.MAP_SIZE,
		grid.blocked_cells, _occupied_cells(), actor.data.effective_move_range(),
		grid.height_cells, actor.data.max_climb
	)
	if command.target_cell != actor.data.grid_position and validated_path.is_empty():
		return
	var occupant := _living_unit_at(command.target_cell)
	if occupant != null and occupant != actor:
		return
	path = validated_path
	input_locked = true
	grid.clear_highlights()
	actor.animate_path(path, grid)
	await actor.movement_finished
	actor.data.grid_position = command.target_cell
	actor.data.elevation = grid.get_height(command.target_cell)
	actor.data.has_moved = true
	actor.refresh()
	input_locked = false
	if player_action and _check_battle_result():
		return
	if player_action and selected_unit == actor:
		selection_mode = SelectionMode.NONE
		grid.set_selected(actor.data.grid_position)
		ui.show_unit(actor.data)
		ui.configure_actions(actor.data, true)
		ui.set_hint("Movimiento completado · ahora atacá, usá una habilidad o esperá")

func _try_attack_at(cell: Vector2i, use_skill: bool) -> void:
	if use_skill:
		var ability := selected_ability
		var ability_target := _living_unit_at(cell)
		if ability == null or ability_target == null:
			ui.show_message("Elegí un objetivo válido.", Color("#ffb28e"))
			return
		if not CombatRules.can_use_ability(selected_unit.data, ability_target.data, ability, grid.height_cells, grid.blocked_cells):
			ui.show_message("Sin alcance, visión, MP o habilidad disponible.", Color("#ffb28e"))
			return
		_execute_attack(BattleCommand.use_ability(selected_unit.data.unit_id, ability_target.data.unit_id, ability.id), true)
		return
	var target := _living_unit_at(cell)
	if target == null or target.data.team == selected_unit.data.team:
		ui.show_message("Elegí una unidad enemiga válida.", Color("#ffb28e"))
		return
	if CombatRules.can_basic_attack(selected_unit.data, target.data, grid.height_cells, grid.blocked_cells):
		_execute_attack(BattleCommand.attack(selected_unit.data.unit_id, target.data.unit_id), true)
	else:
		ui.show_message("Objetivo fuera de alcance o sin línea de visión.", Color("#ffb28e"))

func _execute_attack(command: BattleCommand, player_action: bool) -> void:
	if not command.is_valid_for(turn_manager.active_unit_id):
		return
	var actor := _unit_by_id(command.actor_id)
	var target := _unit_by_id(command.target_unit_id)
	if actor == null or target == null or not actor.data.is_alive() or not target.data.is_alive():
		return
	if command.type == BattleCommand.Type.USE_ABILITY:
		await _execute_ability(command, actor, target, player_action)
		return
	var action_name := "Ataque"
	if not CombatRules.can_basic_attack(actor.data, target.data, grid.height_cells, grid.blocked_cells):
		return
	var damage := CombatRules.basic_attack_damage(actor.data, target.data, grid.height_cells)
	input_locked = true
	await actor.play_attack(target.position, actor.data.basic_attack_damage_type == AbilityData.DamageType.MAGICAL)
	var applied := CombatRules.apply_damage(target.data, damage)
	actor.data.has_acted = true
	actor.refresh()
	target.refresh()
	target.play_hit()
	_show_floating_damage(target, applied)
	ui.show_message("%s usa %s: %d de daño" % [actor.data.display_name, action_name, applied], Color("#ffd38a"))
	await get_tree().create_timer(0.34).timeout
	if not target.data.is_alive():
		target.play_defeat()
		ui.show_message("%s fue derrotado." % target.data.display_name, Color("#ff8d86"))
	input_locked = false
	if _check_battle_result():
		return
	if player_action:
		_finish_player_action()

func _execute_ability(command: BattleCommand, actor: TacticalUnit, primary_target: TacticalUnit, player_action: bool) -> void:
	var ability := _ability_by_id(actor.data, command.ability_id)
	if ability == null or not CombatRules.can_use_ability(actor.data, primary_target.data, ability, grid.height_cells, grid.blocked_cells):
		return
	input_locked = true
	actor.data.mp -= ability.mp_cost
	actor.data.start_ability_cooldown(ability)
	await actor.play_attack(primary_target.position, ability.damage_type == AbilityData.DamageType.MAGICAL)
	var affected: Array[TacticalUnit] = []
	for candidate in unit_views:
		if not candidate.data.is_alive():
			continue
		if CombatRules.grid_distance(primary_target.data.grid_position, candidate.data.grid_position) > ability.area_radius:
			continue
		if ability.target_type == AbilityData.TargetType.ENEMY and candidate.data.team == actor.data.team:
			continue
		if ability.target_type == AbilityData.TargetType.ALLY and candidate.data.team != actor.data.team:
			continue
		if ability.target_type == AbilityData.TargetType.SELF and candidate != actor:
			continue
		affected.append(candidate)
	if affected.is_empty():
		affected.append(primary_target)
	var total_damage := 0
	var applied_status_names: Array[String] = []
	for target in affected:
		if ability.deals_damage():
			for hit_index in ability.hit_count:
				if not target.data.is_alive():
					break
				var damage := CombatRules.ability_damage(actor.data, target.data, ability, grid.height_cells)
				var applied := CombatRules.apply_damage(target.data, damage)
				total_damage += applied
				target.play_hit()
				_show_floating_damage(target, applied)
				if ability.hit_count > 1:
					await get_tree().create_timer(0.12).timeout
		if ability.applies_status() and not ability.status_effect_path.is_empty() and target.data.is_alive() and _status_roll_succeeds(actor.data, target.data, ability):
			var status := load(ability.status_effect_path) as StatusEffectData
			if status != null:
				target.data.add_status(status)
				if not applied_status_names.has(status.display_name):
					applied_status_names.append(status.display_name)
		target.refresh()
		if not target.data.is_alive():
			target.play_defeat()
	actor.data.has_acted = true
	actor.refresh()
	var result_text := "%s usa %s" % [actor.data.display_name, ability.display_name]
	if total_damage > 0:
		result_text += ": %d de daño" % total_damage
	if not applied_status_names.is_empty():
		result_text += " · " + ", ".join(applied_status_names)
	ui.show_message(result_text, Color("#9edcff") if ability.damage_type == AbilityData.DamageType.MAGICAL else Color("#ffd38a"))
	await get_tree().create_timer(0.28).timeout
	input_locked = false
	if _check_battle_result():
		return
	if player_action:
		_finish_player_action()

func _finish_player_action() -> void:
	_advance_turn()

func _begin_active_turn(show_message := true) -> void:
	if phase == Phase.FINISHED:
		return
	var active := _unit_by_id(turn_manager.active_unit_id)
	if active == null or not active.data.is_alive():
		_advance_turn()
		return
	round_number = turn_manager.round_number
	for view in unit_views:
		view.set_active(view == active)
	active.data.begin_turn()
	_process_status_for_view(active)
	if not active.data.is_alive():
		if not _check_battle_result():
			_advance_turn()
		return
	if active.data.team == UnitData.Team.HEROES:
		phase = Phase.PLAYER
		input_locked = false
		ui.set_turn(round_number, true)
		_select_unit(active)
		ui.set_hint("Turno de %s · elegí movimiento, ataque, habilidad, objeto o espera" % active.data.display_name)
		if show_message:
			ui.show_message("Actúa %s (VEL %d)" % [active.data.display_name, active.data.speed], Color("#ffe29a"))
	else:
		phase = Phase.ENEMY
		input_locked = true
		_deselect_unit()
		active.set_active(true)
		ui.show_unit(active.data)
		ui.set_turn(round_number, false)
		ui.set_hint("%s está decidiendo su acción…" % active.data.display_name)
		await get_tree().create_timer(0.28).timeout
		await _run_active_enemy_turn(active)

func _run_active_enemy_turn(enemy: TacticalUnit) -> void:
	if phase == Phase.FINISHED or enemy == null or not enemy.data.is_alive():
		return
	var target := enemy_ai.choose_target(enemy.data, _hero_data())
	if target == null:
		_advance_turn()
		return
	var attack_command := enemy_ai.choose_attack(enemy.data, target, grid.height_cells, grid.blocked_cells)
	if attack_command == null:
		var reachable := GridPathfinder.reachable_cells(
			enemy.data.grid_position, enemy.data.effective_move_range(), IsometricGrid.MAP_SIZE,
			grid.blocked_cells, _occupied_cells(), grid.height_cells, enemy.data.max_climb
		)
		var destination := enemy_ai.choose_destination(enemy.data, target, reachable)
		if destination != enemy.data.grid_position:
			var path := GridPathfinder.find_path(
				enemy.data.grid_position, destination, IsometricGrid.MAP_SIZE,
				grid.blocked_cells, _occupied_cells(), enemy.data.effective_move_range(),
				grid.height_cells, enemy.data.max_climb
			)
			await _execute_move(BattleCommand.move(enemy.data.unit_id, destination), path, false)
		target = enemy_ai.choose_target(enemy.data, _hero_data())
		if target != null:
			attack_command = enemy_ai.choose_attack(enemy.data, target, grid.height_cells, grid.blocked_cells)
	if attack_command != null:
		await _execute_attack(attack_command, false)
	if phase != Phase.FINISHED:
		enemy.data.has_acted = true
		enemy.refresh()
		await get_tree().create_timer(0.16).timeout
		_advance_turn()

func _advance_turn() -> void:
	if phase == Phase.FINISHED:
		return
	var active := _unit_by_id(turn_manager.active_unit_id)
	if active != null:
		active.data.has_acted = true
		active.refresh()
	_deselect_unit()
	var began_new_round := turn_manager.complete_active_turn(_unit_data())
	if began_new_round:
		var next_round := turn_manager.round_number
		round_number = next_round - 1
		if _check_battle_result(true):
			return
		round_number = next_round
		ui.show_message("Comienza la ronda %d" % round_number, Color("#ffe29a"))
	call_deferred("_begin_active_turn", false)

func _check_battle_result(allow_survival := false) -> bool:
	var heroes_alive := hero_views.any(func(view: TacticalUnit): return view.data.is_alive())
	var enemies_alive := enemy_views.any(func(view: TacticalUnit): return view.data.is_alive())
	if not heroes_alive:
		battle_won = false
	elif not enemies_alive:
		battle_won = true
	elif mission.objective_type == MissionData.ObjectiveType.REACH_CELL:
		battle_won = hero_views.any(func(view: TacticalUnit): return view.data.is_alive() and view.data.grid_position == mission.objective_cell)
	elif mission.objective_type == MissionData.ObjectiveType.SURVIVE_ROUNDS and allow_survival:
		battle_won = round_number >= mission.survive_rounds
	else:
		battle_won = false
	if heroes_alive and enemies_alive and not battle_won:
		return false
	phase = Phase.FINISHED
	input_locked = true
	_clear_selection_visuals()
	ui.configure_actions(null, false)
	if battle_won and not rewards_awarded:
		reward_messages = campaign.profile.award_mission(mission, _hero_data())
		rewards_awarded = true
	if battle_won and not mission.victory_dialogue.is_empty():
		pending_dialogue = "victory"
		ui.show_dialogue(mission.victory_dialogue)
	else:
		_present_result()
	return true

func _present_result() -> void:
	ui.show_result(battle_won, round_number, campaign.has_next_mission(), reward_messages)

func _on_dialogue_finished() -> void:
	if pending_dialogue == "intro":
		pending_dialogue = ""
		_begin_active_turn(false)
	elif pending_dialogue == "victory":
		pending_dialogue = ""
		_present_result()

func _on_continue_requested() -> void:
	if not battle_won:
		_start_mission(campaign.current_mission_index)
	elif campaign.advance():
		_start_mission(campaign.current_mission_index)
	else:
		campaign.current_mission_index = 0
		_start_mission(0)

func _on_save_requested() -> void:
	if phase != Phase.PLAYER or input_locked:
		ui.show_message("Sólo se puede guardar durante tu turno.", Color("#ffcf88"))
		return
	var success := SaveSystem.save_game({
		"mission_index": campaign.current_mission_index,
		"round": round_number,
		"turn_manager": turn_manager.snapshot(),
		"profile": campaign.profile.make_snapshot(),
		"units": unit_views.map(func(view: TacticalUnit): return view.data.make_snapshot()),
	})
	ui.show_message("Partida guardada." if success else "No se pudo guardar la partida.", Color("#9fe0bd") if success else Color("#ff8d86"))

func _on_load_requested() -> void:
	if input_locked and phase != Phase.FINISHED:
		return
	var payload := SaveSystem.load_game()
	if payload.is_empty():
		ui.show_message("No hay una partida guardada válida.", Color("#ffcf88"))
		return
	var mission_index := int(payload.get("mission_index", 0))
	campaign.profile.restore(payload.get("profile", {}))
	_start_mission(mission_index, false, false)
	round_number = maxi(1, int(payload.get("round", 1)))
	for snapshot_value in payload.get("units", []):
		var snapshot: Dictionary = snapshot_value
		var view := _unit_by_id(str(snapshot.get("unit_id", "")))
		if view == null:
			continue
		view.data.hp = clampi(int(snapshot.get("hp", view.data.max_hp)), 0, view.data.max_hp)
		view.data.mp = clampi(int(snapshot.get("mp", view.data.max_mp)), 0, view.data.max_mp)
		var cell_data: Dictionary = snapshot.get("grid_position", {})
		view.data.grid_position = Vector2i(int(cell_data.get("x", 0)), int(cell_data.get("y", 0)))
		view.data.elevation = grid.get_height(view.data.grid_position)
		view.data.has_moved = bool(snapshot.get("has_moved", false))
		view.data.has_acted = bool(snapshot.get("has_acted", false))
		view.data.active_statuses.assign(snapshot.get("active_statuses", []))
		view.data.ability_cooldowns = snapshot.get("ability_cooldowns", {}).duplicate(true)
		view.position = grid.grid_to_world(view.data.grid_position) + Vector2(0, -9)
		view.visible = view.data.is_alive()
		view.refresh()
	turn_manager.restore(payload.get("turn_manager", {"round": round_number}), _unit_data())
	round_number = turn_manager.round_number
	for view in unit_views:
		view.set_active(view.data.unit_id == turn_manager.active_unit_id)
	var active := _unit_by_id(turn_manager.active_unit_id)
	phase = Phase.PLAYER if active != null and active.data.team == UnitData.Team.HEROES else Phase.ENEMY
	input_locked = phase != Phase.PLAYER
	ui.set_turn(round_number, phase == Phase.PLAYER)
	if active != null:
		ui.show_unit(active.data)
		if phase == Phase.PLAYER:
			_select_unit(active)
	ui.show_message("Partida cargada.", Color("#9fe0bd"))

func _occupied_cells() -> Dictionary:
	var occupied := {}
	for view in unit_views:
		if view.data.is_alive():
			occupied[view.data.grid_position] = view.data.unit_id
	return occupied

func _living_unit_at(cell: Vector2i) -> TacticalUnit:
	for view in unit_views:
		if view.data.is_alive() and view.data.grid_position == cell:
			return view
	return null

func _unit_by_id(unit_id: String) -> TacticalUnit:
	for view in unit_views:
		if view.data.unit_id == unit_id:
			return view
	return null

func _ability_by_id(unit: UnitData, ability_id: StringName) -> AbilityData:
	for ability in unit.abilities:
		if ability.id == ability_id:
			return ability
	return null

func _hero_data() -> Array[UnitData]:
	var result: Array[UnitData] = []
	for view in hero_views:
		result.append(view.data)
	return result

func _unit_data() -> Array[UnitData]:
	var result: Array[UnitData] = []
	for view in unit_views:
		result.append(view.data)
	return result

func _active_unit_name() -> String:
	var active := _unit_by_id(turn_manager.active_unit_id)
	return active.data.display_name if active != null else "la unidad activa"

func _selection_can_act() -> bool:
	return phase == Phase.PLAYER and not input_locked and selected_unit != null and selected_unit.data.is_alive() \
		and selected_unit.data.unit_id == turn_manager.active_unit_id and not selected_unit.data.has_acted

func _show_floating_damage(target: TacticalUnit, amount: int) -> void:
	var floating := FloatingText.new()
	effects_layer.add_child(floating)
	floating.show_text("-%d" % amount, target.position, Color("#ffebaa"))

func _process_status_for_view(view: TacticalUnit) -> void:
	var events := view.data.process_status_turn()
	for event in events:
		_show_floating_damage(view, int(event.damage))
		ui.show_message("%s sufre %d por %s" % [view.data.display_name, int(event.damage), str(event.name)], event.color)
	view.refresh()
	if not view.data.is_alive():
		view.play_defeat()

func _status_roll_succeeds(actor: UnitData, target: UnitData, ability: AbilityData) -> bool:
	var effective_chance := clampf(ability.status_chance - float(target.effect_resistance) / 200.0, 0.05, 1.0)
	if effective_chance >= 1.0:
		return true
	var seed_text := "%s:%s:%s:%d" % [actor.unit_id, target.unit_id, ability.id, round_number]
	var normalized := float(absi(hash(seed_text)) % 10000) / 10000.0
	return normalized < effective_chance
