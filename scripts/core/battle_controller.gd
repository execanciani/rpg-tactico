class_name BattleController
extends Node2D

enum Phase { PLAYER, ENEMY, FINISHED }
enum SelectionMode { NONE, MOVE, ATTACK, SKILL }

const HERO_ARCHETYPE_PATHS: Array[String] = [
	"res://data/archetypes/hero_warrior.tres",
	"res://data/archetypes/hero_mage.tres",
	"res://data/archetypes/hero_archer.tres",
]

@onready var grid: IsometricGrid = $IsometricGrid
@onready var units_layer: Node2D = $Units
@onready var effects_layer: Node2D = $Effects
@onready var tactical_camera: TacticalCamera = $Camera2D
@onready var ui: BattleUI = $Interface/BattleUI

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
var campaign := CampaignManager.new()
var mission: MissionData
var pending_dialogue := ""
var reward_messages: Array[String] = []
var rewards_awarded := false

func _ready() -> void:
	grid.cell_pressed.connect(_on_cell_pressed)
	ui.move_requested.connect(_on_move_requested)
	ui.attack_requested.connect(_on_attack_requested)
	ui.skill_requested.connect(_on_skill_requested)
	ui.wait_requested.connect(_on_wait_requested)
	ui.item_requested.connect(_on_item_requested)
	ui.item_selected.connect(_on_item_selected)
	ui.save_requested.connect(_on_save_requested)
	ui.load_requested.connect(_on_load_requested)
	ui.continue_requested.connect(_on_continue_requested)
	ui.dialogue_finished.connect(_on_dialogue_finished)
	campaign.load_catalog()
	_start_mission(campaign.current_mission_index)

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
	elif event.is_action_pressed("action_item"):
		_on_item_requested()
	elif event.is_action_pressed("ui_cancel"):
		_set_selection_mode(SelectionMode.NONE)

func _start_mission(index: int, announce := true) -> void:
	if campaign.missions.is_empty():
		push_error("La campaña no contiene misiones válidas.")
		return
	campaign.current_mission_index = clampi(index, 0, campaign.missions.size() - 1)
	mission = campaign.current_mission()
	_clear_battlefield()
	grid.configure(mission)
	tactical_camera.reset_view()
	for hero_index in HERO_ARCHETYPE_PATHS.size():
		var archetype := load(HERO_ARCHETYPE_PATHS[hero_index]) as UnitArchetype
		if archetype == null or hero_index >= mission.hero_positions.size():
			continue
		var hero := archetype.instantiate(archetype.archetype_id, UnitData.Team.HEROES, mission.hero_positions[hero_index])
		campaign.profile.apply_to_hero(hero)
		hero.xp_to_next = campaign.profile.xp_required(hero.level)
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
	ui.set_mission(mission.title, campaign.current_mission_index + 1, campaign.missions.size(), campaign.profile.gold)
	ui.set_objective(mission.objective_text)
	_start_player_round(false)
	ui.set_hint(mission.briefing)
	if announce and not mission.intro_dialogue.is_empty():
		pending_dialogue = "intro"
		input_locked = true
		ui.show_dialogue(mission.intro_dialogue)
	if announce:
		ui.show_message("Misión: %s" % mission.title, Color("#9fe0bd"))

func _clear_battlefield() -> void:
	selected_unit = null
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
		if clicked.data.has_acted:
			ui.show_message("%s ya actuó esta ronda." % clicked.data.display_name, Color("#ffdc89"))
			ui.show_unit(clicked.data)
			return
		_select_unit(clicked)
	elif clicked != null:
		ui.show_unit(clicked.data)
		ui.set_hint("Unidad enemiga · seleccioná un héroe para actuar")

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
		ui.set_hint("Seleccioná una unidad azul que no haya actuado")

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
	var ability: AbilityData = selected_unit.data.abilities[0]
	if not selected_unit.data.can_spend_mp(ability.mp_cost):
		ui.show_message("MP insuficiente", Color("#8dd7ff"))
		return
	_set_selection_mode(SelectionMode.SKILL)
	_show_range(ability.range_cells, IsometricGrid.Highlight.SKILL)
	ui.set_hint("%s · %d MP · requiere línea de visión" % [ability.display_name, ability.mp_cost])

func _on_wait_requested() -> void:
	if not _selection_can_act():
		return
	selected_unit.data.has_acted = true
	selected_unit.refresh()
	ui.show_message("%s espera." % selected_unit.data.display_name, Color("#d7dde0"))
	_finish_player_action()

func _on_item_requested() -> void:
	if not _selection_can_act():
		return
	var entries := campaign.profile.inventory.list_available_for(selected_unit.data)
	if entries.is_empty():
		ui.show_message("No hay objetos utilizables para esta unidad.", Color("#ffcf88"))
		return
	ui.show_inventory(entries, selected_unit.data)

func _on_item_selected(item_id: String) -> void:
	if not _selection_can_act():
		ui.hide_inventory()
		return
	var item := campaign.profile.inventory.get_item(item_id)
	if item == null:
		return
	var success := false
	if item.type == ItemData.Type.CONSUMABLE:
		success = campaign.profile.inventory.consume(selected_unit.data, item_id)
	else:
		success = campaign.profile.inventory.equip_item(selected_unit.data, item_id)
	if not success:
		ui.show_message("El objeto no puede usarse ahora.", Color("#ffcf88"))
		return
	ui.hide_inventory()
	selected_unit.data.has_acted = true
	selected_unit.refresh()
	ui.show_message("%s usa %s." % [selected_unit.data.display_name, item.display_name], Color("#9fe0bd"))
	_finish_player_action()

func _set_selection_mode(mode: SelectionMode) -> void:
	selection_mode = mode
	grid.clear_highlights()
	for view in unit_views:
		view.set_targeted(false)
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
	var actor := _unit_by_id(command.actor_id)
	if actor == null or not actor.data.is_alive() or grid.is_blocked(command.target_cell):
		return
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
	var target := _living_unit_at(cell)
	if target == null or target.data.team == selected_unit.data.team:
		ui.show_message("Elegí una unidad enemiga válida.", Color("#ffb28e"))
		return
	if use_skill:
		var ability: AbilityData = selected_unit.data.abilities[0]
		if not CombatRules.can_use_ability(selected_unit.data, target.data, ability, grid.height_cells, grid.blocked_cells):
			ui.show_message("Sin alcance, visión o MP suficiente.", Color("#ffb28e"))
			return
		_execute_attack(BattleCommand.use_ability(selected_unit.data.unit_id, target.data.unit_id, ability.id), true)
	elif CombatRules.can_basic_attack(selected_unit.data, target.data, grid.height_cells, grid.blocked_cells):
		_execute_attack(BattleCommand.attack(selected_unit.data.unit_id, target.data.unit_id), true)
	else:
		ui.show_message("Objetivo fuera de alcance o sin línea de visión.", Color("#ffb28e"))

func _execute_attack(command: BattleCommand, player_action: bool) -> void:
	var actor := _unit_by_id(command.actor_id)
	var target := _unit_by_id(command.target_unit_id)
	if actor == null or target == null or not actor.data.is_alive() or not target.data.is_alive():
		return
	var damage := 0
	var action_name := "Ataque"
	if command.type == BattleCommand.Type.USE_ABILITY:
		var ability := _ability_by_id(actor.data, command.ability_id)
		if ability == null or not CombatRules.can_use_ability(actor.data, target.data, ability, grid.height_cells, grid.blocked_cells):
			return
		actor.data.mp -= ability.mp_cost
		damage = CombatRules.ability_damage(actor.data, target.data, ability, grid.height_cells)
		action_name = ability.display_name
		if not ability.status_effect_path.is_empty() and _status_roll_succeeds(actor.data, target.data, ability):
			var status := load(ability.status_effect_path) as StatusEffectData
			if status != null:
				target.data.add_status(status)
				action_name += " + %s" % status.display_name
	else:
		if not CombatRules.can_basic_attack(actor.data, target.data, grid.height_cells, grid.blocked_cells):
			return
		damage = CombatRules.basic_attack_damage(actor.data, target.data, grid.height_cells)
	input_locked = true
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

func _finish_player_action() -> void:
	_deselect_unit()
	if _living_heroes_have_acted():
		_run_enemy_turn()

func _run_enemy_turn() -> void:
	phase = Phase.ENEMY
	_deselect_unit()
	ui.set_turn(round_number, false)
	ui.set_hint("Los enemigos están decidiendo sus acciones…")
	await get_tree().create_timer(0.45).timeout
	for enemy in enemy_views:
		if enemy.data.is_alive():
			enemy.data.begin_turn()
			_process_status_for_view(enemy)
	if _check_battle_result():
		return
	for enemy in enemy_views:
		if phase == Phase.FINISHED:
			return
		if not enemy.data.is_alive():
			continue
		var target := enemy_ai.choose_target(enemy.data, _hero_data())
		if target == null:
			break
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
		enemy.data.has_acted = true
		enemy.refresh()
		await get_tree().create_timer(0.18).timeout
	if phase != Phase.FINISHED:
		if _check_battle_result(true):
			return
		round_number += 1
		_start_player_round(true)

func _start_player_round(show_message: bool) -> void:
	phase = Phase.PLAYER
	for hero in hero_views:
		if hero.data.is_alive():
			hero.data.begin_turn()
			_process_status_for_view(hero)
	if not hero_views.any(func(view: TacticalUnit): return view.data.is_alive()):
		_check_battle_result()
		return
	ui.set_turn(round_number, true)
	ui.configure_actions(null, false)
	if show_message:
		ui.show_message("Comienza la ronda %d" % round_number, Color("#ffe29a"))
	ui.set_hint("Seleccioná una unidad azul")

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
		input_locked = false
		ui.set_hint(mission.objective_text)
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
		campaign.profile.initialize_default()
		_start_mission(0)

func _on_save_requested() -> void:
	if phase != Phase.PLAYER or input_locked:
		ui.show_message("Sólo se puede guardar durante tu turno.", Color("#ffcf88"))
		return
	var success := SaveSystem.save_game({
		"mission_index": campaign.current_mission_index,
		"round": round_number,
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
	_start_mission(mission_index, false)
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
		view.position = grid.grid_to_world(view.data.grid_position) + Vector2(0, -9)
		view.visible = view.data.is_alive()
		view.refresh()
	phase = Phase.PLAYER
	input_locked = false
	ui.set_turn(round_number, true)
	ui.show_message("Partida cargada.", Color("#9fe0bd"))

func _living_heroes_have_acted() -> bool:
	for hero in hero_views:
		if hero.data.is_alive() and not hero.data.has_acted:
			return false
	return true

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

func _selection_can_act() -> bool:
	return phase == Phase.PLAYER and not input_locked and selected_unit != null and selected_unit.data.is_alive() and not selected_unit.data.has_acted

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
	if ability.status_chance >= 1.0:
		return true
	var seed_text := "%s:%s:%s:%d" % [actor.unit_id, target.unit_id, ability.id, round_number]
	var normalized := float(absi(hash(seed_text)) % 10000) / 10000.0
	return normalized < ability.status_chance
