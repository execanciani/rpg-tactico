class_name BattleUI
extends Control

signal move_requested
signal attack_requested
signal skill_requested
signal wait_requested
signal ability_selected(ability_id: StringName)
signal progression_requested
signal inventory_requested
signal learn_skill_requested(character_id: String, ability_id: String)
signal profession_change_requested(character_id: String, profession_id: String)
signal equip_requested(character_id: String, item_id: String)
signal unequip_requested(character_id: String, slot_id: String)
signal progression_closed
signal save_requested
signal load_requested
signal continue_requested
signal dialogue_finished

var turn_label: Label
var mission_label: Label
var hint_label: Label
var objective_label: Label
var unit_name_label: Label
var unit_stats_label: Label
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var move_button: Button
var attack_button: Button
var skill_button: Button
var wait_button: Button
var message_label: Label
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label
var result_button: Button
var ability_overlay: PanelContainer
var ability_list: VBoxContainer
var ability_title: Label
var progression_overlay: PanelContainer
var progression_character_tabs: HBoxContainer
var progression_content: VBoxContainer
var progression_profile: CampaignProfile
var progression_character_id := ""
var progression_tab := "character"
var dialogue_overlay: ColorRect
var dialogue_label: Label
var dialogue_lines: Array[String] = []
var dialogue_index := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_unit_panel()
	_build_action_panel()
	_build_message_log()
	_build_result_overlay()
	_build_ability_overlay()
	_build_progression_overlay()
	_build_dialogue_overlay()
	show_unit(null)

func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 18
	panel.offset_top = 16
	panel.offset_right = -18
	panel.offset_bottom = 88
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#17222ce8"), Color("#668c99")))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	mission_label = Label.new()
	mission_label.custom_minimum_size = Vector2(270, 0)
	mission_label.clip_text = true
	mission_label.add_theme_font_size_override("font_size", 15)
	mission_label.add_theme_color_override("font_color", Color("#9fd5bd"))
	row.add_child(mission_label)
	turn_label = Label.new()
	turn_label.add_theme_font_size_override("font_size", 19)
	turn_label.add_theme_color_override("font_color", Color("#ffe29a"))
	row.add_child(turn_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	hint_label = Label.new()
	hint_label.custom_minimum_size = Vector2(220, 0)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.clip_text = true
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color("#cfdae0"))
	row.add_child(hint_label)
	var save_button := Button.new()
	save_button.text = "Guardar"
	save_button.custom_minimum_size = Vector2(96, 46)
	save_button.pressed.connect(func(): save_requested.emit())
	row.add_child(save_button)
	var progression_button := Button.new()
	progression_button.text = "Progreso"
	progression_button.custom_minimum_size = Vector2(100, 46)
	progression_button.pressed.connect(func(): progression_requested.emit())
	row.add_child(progression_button)
	var inventory_button := Button.new()
	inventory_button.text = "Inventario"
	inventory_button.custom_minimum_size = Vector2(108, 46)
	inventory_button.pressed.connect(func(): inventory_requested.emit())
	row.add_child(inventory_button)
	var load_button := Button.new()
	load_button.text = "Cargar"
	load_button.custom_minimum_size = Vector2(96, 46)
	load_button.pressed.connect(func(): load_requested.emit())
	row.add_child(load_button)
	objective_label = Label.new()
	objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_label.offset_left = 20
	objective_label.offset_top = 94
	objective_label.offset_right = 760
	objective_label.offset_bottom = 126
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color("#ffe195"))
	objective_label.add_theme_color_override("font_outline_color", Color("#17222c"))
	objective_label.add_theme_constant_override("outline_size", 5)
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_label)

func _build_unit_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 18
	panel.offset_top = -218
	panel.offset_right = 390
	panel.offset_bottom = -18
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#17222cef"), Color("#557a89")))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	unit_name_label = Label.new()
	unit_name_label.add_theme_font_size_override("font_size", 21)
	unit_name_label.add_theme_color_override("font_color", Color("#f3d78f"))
	column.add_child(unit_name_label)
	unit_stats_label = Label.new()
	unit_stats_label.add_theme_font_size_override("font_size", 15)
	unit_stats_label.add_theme_color_override("font_color", Color("#d9e2e6"))
	column.add_child(unit_stats_label)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 14)
	hp_bar.show_percentage = false
	hp_bar.visible = false
	column.add_child(hp_bar)
	mp_bar = ProgressBar.new()
	mp_bar.custom_minimum_size = Vector2(0, 12)
	mp_bar.show_percentage = false
	mp_bar.visible = false
	column.add_child(mp_bar)

func _build_action_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -720
	panel.offset_top = -102
	panel.offset_right = -18
	panel.offset_bottom = -18
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#17222cef"), Color("#557a89")))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	move_button = _action_button("Mover\n[M]", "Elegir una casilla alcanzable")
	attack_button = _action_button("Atacar\n[A]", "Ataque básico de la clase")
	skill_button = _action_button("Habilidad\n[S]", "Usar la primera habilidad disponible")
	wait_button = _action_button("Esperar\n[W]", "Finalizar la acción")
	for button in [move_button, attack_button, skill_button, wait_button]:
		row.add_child(button)
	move_button.pressed.connect(func(): move_requested.emit())
	attack_button.pressed.connect(func(): attack_requested.emit())
	skill_button.pressed.connect(func(): skill_requested.emit())
	wait_button.pressed.connect(func(): wait_requested.emit())

func _build_message_log() -> void:
	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	message_label.offset_left = -480
	message_label.offset_top = 96
	message_label.offset_right = -22
	message_label.offset_bottom = 134
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_color_override("font_outline_color", Color("#17222c"))
	message_label.add_theme_constant_override("outline_size", 6)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message_label)

func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.03, 0.06, 0.09, 0.87)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	add_child(result_overlay)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -280
	center.offset_top = -130
	center.offset_right = 280
	center.offset_bottom = 130
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 16)
	result_overlay.add_child(center)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 46)
	center.add_child(result_title)
	result_detail = Label.new()
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail.add_theme_font_size_override("font_size", 20)
	result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(result_detail)
	result_button = Button.new()
	result_button.custom_minimum_size = Vector2(220, 54)
	result_button.add_theme_font_size_override("font_size", 19)
	result_button.pressed.connect(func(): continue_requested.emit())
	center.add_child(result_button)

func _build_ability_overlay() -> void:
	ability_overlay = PanelContainer.new()
	ability_overlay.set_anchors_preset(Control.PRESET_CENTER)
	ability_overlay.offset_left = -300
	ability_overlay.offset_top = -190
	ability_overlay.offset_right = 300
	ability_overlay.offset_bottom = 190
	ability_overlay.add_theme_stylebox_override("panel", _panel_style(Color("#101a24f5"), Color("#79b8d1")))
	ability_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ability_overlay.visible = false
	add_child(ability_overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	ability_overlay.add_child(column)
	ability_title = Label.new()
	ability_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_title.add_theme_font_size_override("font_size", 24)
	ability_title.add_theme_color_override("font_color", Color("#aee5ff"))
	column.add_child(ability_title)
	ability_list = VBoxContainer.new()
	ability_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ability_list.add_theme_constant_override("separation", 8)
	column.add_child(ability_list)
	var close_button := Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.pressed.connect(hide_abilities)
	column.add_child(close_button)

func _build_dialogue_overlay() -> void:
	dialogue_overlay = ColorRect.new()
	dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_overlay.color = Color(0.02, 0.04, 0.07, 0.72)
	dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_overlay.visible = false
	add_child(dialogue_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 110
	panel.offset_top = -220
	panel.offset_right = -110
	panel.offset_bottom = -40
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#101a24f5"), Color("#9fc4d2")))
	dialogue_overlay.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	dialogue_label = Label.new()
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 22)
	column.add_child(dialogue_label)
	var next_button := Button.new()
	next_button.text = "Continuar"
	next_button.custom_minimum_size = Vector2(180, 48)
	next_button.pressed.connect(_advance_dialogue)
	column.add_child(next_button)

func _build_progression_overlay() -> void:
	progression_overlay = PanelContainer.new()
	progression_overlay.set_anchors_preset(Control.PRESET_CENTER)
	progression_overlay.offset_left = -500
	progression_overlay.offset_top = -300
	progression_overlay.offset_right = 500
	progression_overlay.offset_bottom = 300
	progression_overlay.add_theme_stylebox_override("panel", _panel_style(Color("#101822fa"), Color("#d0ad62")))
	progression_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	progression_overlay.visible = false
	add_child(progression_overlay)
	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 9)
	progression_overlay.add_child(root_column)
	var title := Label.new()
	title.text = "GESTIÓN DE PERSONAJES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#ffe195"))
	root_column.add_child(title)
	progression_character_tabs = HBoxContainer.new()
	progression_character_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	progression_character_tabs.add_theme_constant_override("separation", 8)
	root_column.add_child(progression_character_tabs)
	var sections := HBoxContainer.new()
	sections.alignment = BoxContainer.ALIGNMENT_CENTER
	sections.add_theme_constant_override("separation", 8)
	root_column.add_child(sections)
	for section_data in [["character", "Personaje"], ["equipment", "Equipo"], ["profession", "Profesiones"], ["skills", "Habilidades"]]:
		var section_button := Button.new()
		section_button.text = section_data[1]
		section_button.custom_minimum_size = Vector2(135, 42)
		section_button.pressed.connect(_select_progression_tab.bind(str(section_data[0])))
		sections.add_child(section_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(scroll)
	progression_content = VBoxContainer.new()
	progression_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progression_content.add_theme_constant_override("separation", 8)
	scroll.add_child(progression_content)
	var close_button := Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.pressed.connect(hide_progression)
	root_column.add_child(close_button)

func _action_button(text_value: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(128, 58)
	button.add_theme_font_size_override("font_size", 17)
	return button

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func set_turn(round_number: int, is_player_turn: bool) -> void:
	turn_label.text = "RONDA %d · %s" % [round_number, "TURNO DEL JUGADOR" if is_player_turn else "TURNO ENEMIGO"]
	turn_label.add_theme_color_override("font_color", Color("#ffe29a") if is_player_turn else Color("#ff9d96"))

func set_mission(title: String, current: int, total: int) -> void:
	mission_label.text = "MISIÓN %d/%d · %s" % [current, total, title]

func set_objective(value: String) -> void:
	objective_label.text = "OBJETIVO · %s" % value

func set_hint(value: String) -> void:
	hint_label.text = value
	hint_label.tooltip_text = value

func show_message(value: String, color: Color = Color.WHITE) -> void:
	message_label.text = value
	message_label.add_theme_color_override("font_color", color)
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.45)

func show_unit(unit: UnitData) -> void:
	if unit != null:
		hp_bar.visible = true
		mp_bar.visible = true
		hp_bar.max_value = unit.max_hp
		hp_bar.value = unit.hp
		mp_bar.max_value = maxi(1, unit.max_mp)
		mp_bar.value = unit.mp
	if unit == null:
		hp_bar.visible = false
		mp_bar.visible = false
		unit_name_label.text = "Sin unidad seleccionada"
		unit_stats_label.text = "Elegí una unidad azul para actuar."
		return
	unit_name_label.text = "%s · Nv. %d %s" % [unit.display_name, unit.level, unit.class_name_text]
	unit_stats_label.text = "%s · SP %d · XP %d/%d\nHP %d/%d   MP %d/%d\nATQ %d   MAG %d   DEF %d   RES %d\nMOV %d (%d)   VEL %d   ALT %d\nEstados: %s" % [
		unit.race_name_text, unit.skill_points, unit.xp, unit.xp_to_next,
		unit.hp, unit.max_hp, unit.mp, unit.max_mp,
		unit.physical_attack, unit.magical_attack, unit.effective_physical_defense(), unit.effective_magical_defense(),
		unit.effective_move_range(), unit.move_range, unit.speed, unit.elevation,
		unit.status_summary(),
	]

func configure_actions(unit: UnitData, enabled: bool) -> void:
	var can_act := enabled and unit != null and unit.is_alive() and not unit.has_acted
	move_button.disabled = not can_act or unit.has_moved
	attack_button.disabled = not can_act
	var has_available_ability := false
	if unit != null:
		for ability in unit.abilities:
			if unit.can_spend_mp(ability.mp_cost) and unit.is_ability_ready(ability.id):
				has_available_ability = true
	skill_button.disabled = not can_act or not has_available_ability
	wait_button.disabled = not can_act
	if unit != null and not unit.abilities.is_empty():
		skill_button.text = "Habilidades (%d)\n[S]" % unit.abilities.size()
	else:
		skill_button.text = "Habilidad\n[S]"

func show_result(victory: bool, rounds: int, has_next_mission := false, rewards: Array[String] = []) -> void:
	result_overlay.visible = true
	result_overlay.move_to_front()
	result_title.text = "¡VICTORIA!" if victory else "DERROTA"
	result_title.add_theme_color_override("font_color", Color("#ffe18a") if victory else Color("#ff7770"))
	var detail := "Todos los objetivos se completaron en %d rondas." % rounds if victory else "Tu escuadrón cayó. Ajustá la táctica e intentá de nuevo."
	if not rewards.is_empty():
		detail += "\n" + "\n".join(rewards)
	result_detail.text = detail
	result_button.text = "Siguiente misión" if victory and has_next_mission else ("Reiniciar campaña" if victory else "Reintentar misión")

func hide_result() -> void:
	result_overlay.visible = false

func show_abilities(unit: UnitData) -> void:
	ability_title.text = "Habilidades · %s" % unit.display_name
	for child in ability_list.get_children():
		child.queue_free()
	for ability in unit.abilities:
		var cooldown := unit.ability_cooldown(ability.id)
		var button := Button.new()
		var area_text := " · Área %d" % ability.area_radius if ability.area_radius > 0 else ""
		var cooldown_text := " · CD %d" % cooldown if cooldown > 0 else ""
		button.text = "%s · %d MP · Alcance %d%s%s\n%s" % [ability.display_name, ability.mp_cost, ability.range_cells, area_text, cooldown_text, ability.description]
		button.custom_minimum_size = Vector2(0, 66)
		button.disabled = not unit.can_spend_mp(ability.mp_cost) or cooldown > 0
		button.pressed.connect(_emit_ability_selected.bind(ability.id))
		ability_list.add_child(button)
	ability_overlay.visible = true
	ability_overlay.move_to_front()

func _emit_ability_selected(ability_id: StringName) -> void:
	ability_overlay.visible = false
	ability_selected.emit(ability_id)

func hide_abilities() -> void:
	ability_overlay.visible = false

func show_progression(profile: CampaignProfile, selected_character_id := "", selected_tab := "") -> void:
	progression_profile = profile
	if not selected_tab.is_empty():
		progression_tab = selected_tab
	var ids: Array[String] = []
	ids.assign(profile.characters.keys())
	ids.sort()
	if ids.is_empty():
		return
	if not selected_character_id.is_empty():
		progression_character_id = selected_character_id
	if progression_character_id.is_empty() or not profile.characters.has(progression_character_id):
		progression_character_id = ids[0]
	for child in progression_character_tabs.get_children():
		child.queue_free()
	for character_id in ids:
		var progress := profile.character(character_id)
		var button := Button.new()
		button.text = "%s · Nv.%d" % [progress.display_name, progress.level]
		button.disabled = character_id == progression_character_id
		button.pressed.connect(_select_progression_character.bind(character_id))
		progression_character_tabs.add_child(button)
	_rebuild_progression_content()
	progression_overlay.visible = true
	progression_overlay.move_to_front()

func _select_progression_character(character_id: String) -> void:
	show_progression(progression_profile, character_id, progression_tab)

func _select_progression_tab(tab_id: String) -> void:
	progression_tab = tab_id
	_rebuild_progression_content()

func _rebuild_progression_content() -> void:
	for child in progression_content.get_children():
		child.queue_free()
	var progress := progression_profile.character(progression_character_id)
	if progress == null:
		return
	match progression_tab:
		"equipment":
			_build_equipment_screen(progress)
		"profession":
			_build_profession_screen(progress)
		"skills":
			_build_skill_screen(progress)
		_:
			_build_character_screen(progress)

func _build_character_screen(progress: CharacterProgress) -> void:
	var race := progression_profile.catalog.race(progress.race_id)
	var profession := progression_profile.catalog.profession(progress.profession_id)
	var calculated := StatCalculator.calculate(progress, race, profession, progression_profile.equipment_bonuses(progress))
	var attributes: Dictionary = calculated.attributes
	var derived: Dictionary = calculated.derived
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.text = "%s · %s · %s · Nivel %d\nXP total: %d · Progreso: %d/%d · SP: %d disponibles / %d gastados\n\nATRIBUTOS\nSTR %d   DEX %d   CON %d   INT %d   WIS %d   MEN %d\n\nESTADÍSTICAS\nHP %d   MP %d   ATQ %d   MAG %d   DEF %d   RES %d\nPrecisión %d   Evasión %d   Crítico %d%% ×%d%%\nVelocidad %d   Movimiento %d   Resistencia a estados %d%%\n\n%s" % [
		progress.display_name, race.display_name, profession.display_name, progress.level,
		progress.total_experience, progress.experience_into_level(), progress.experience_to_next_level(), progress.sp_available, progress.sp_spent,
		int(attributes.STR), int(attributes.DEX), int(attributes.CON), int(attributes.INT), int(attributes.WIS), int(attributes.MEN),
		int(derived.max_hp), int(derived.max_mp), int(derived.physical_attack), int(derived.magical_attack), int(derived.physical_defense), int(derived.magical_defense),
		int(derived.accuracy), int(derived.evasion), int(derived.critical_chance), int(derived.critical_damage),
		int(derived.speed), int(derived.move_range), int(derived.effect_resistance), race.description,
	]
	progression_content.add_child(label)

func _build_equipment_screen(progress: CharacterProgress) -> void:
	var race := progression_profile.catalog.race(progress.race_id)
	var profession := progression_profile.catalog.profession(progress.profession_id)
	var calculated := StatCalculator.calculate(progress, race, profession, progression_profile.equipment_bonuses(progress))
	var derived: Dictionary = calculated.derived
	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 18)
	heading.text = "%s · %s · %s · Nivel %d\nATQ %d   MAG %d   DEF %d   RES %d   VEL %d   EVA %d" % [
		progress.display_name, race.display_name, profession.display_name, progress.level,
		int(derived.physical_attack), int(derived.magical_attack), int(derived.physical_defense),
		int(derived.magical_defense), int(derived.speed), int(derived.evasion),
	]
	progression_content.add_child(heading)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	progression_content.add_child(body)
	body.add_child(_equipment_preview(progress))
	var lists := VBoxContainer.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_theme_constant_override("separation", 6)
	body.add_child(lists)
	var slots_title := Label.new()
	slots_title.text = "EQUIPAMIENTO ACTUAL"
	slots_title.add_theme_color_override("font_color", Color("#ffe195"))
	lists.add_child(slots_title)
	var slot_names := {
		"head": "Cabeza", "torso": "Torso", "legs": "Piernas", "hands": "Manos",
		"feet": "Pies", "cape": "Capa", "main_hand": "Arma principal", "off_hand": "Arma secundaria",
	}
	for slot_id in EquipmentItemData.SLOT_KEYS:
		var equipped_id := str(progress.equipped_items.get(slot_id, ""))
		var equipped := progression_profile.catalog.equipment_item(equipped_id)
		var slot_button := Button.new()
		slot_button.text = "%s: %s" % [slot_names[slot_id], equipped.display_name if equipped != null else "Vacio"]
		slot_button.tooltip_text = "Tocar para desequipar y devolver al inventario." if equipped != null else "Espacio disponible."
		slot_button.disabled = equipped == null
		slot_button.pressed.connect(_emit_unequip.bind(progress.character_id, slot_id))
		lists.add_child(slot_button)
	var inventory_title := Label.new()
	inventory_title.text = "INVENTARIO DISPONIBLE"
	inventory_title.add_theme_color_override("font_color", Color("#9fd5bd"))
	lists.add_child(inventory_title)
	var item_ids: Array[String] = []
	item_ids.assign(progress.inventory.keys())
	item_ids.sort()
	if item_ids.is_empty():
		var empty := Label.new()
		empty.text = "No hay objetos disponibles."
		lists.add_child(empty)
	for item_id in item_ids:
		var item := progression_profile.catalog.equipment_item(item_id)
		if item == null:
			continue
		var item_button := Button.new()
		item_button.icon = item.icon
		item_button.expand_icon = true
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.text = "%s ×%d · %s\n%s" % [item.display_name, progress.item_quantity(item_id), slot_names[item.slot_key()], str(item.derived_bonuses)]
		item_button.tooltip_text = item.description
		item_button.disabled = not item.can_be_used_by(progress)
		item_button.pressed.connect(_emit_equip.bind(progress.character_id, item.item_id))
		lists.add_child(item_button)

func _equipment_preview(progress: CharacterProgress) -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(256, 384)
	var appearance := progression_profile.catalog.appearance(progress.appearance_id)
	if appearance == null:
		return preview
	_add_preview_texture(preview, appearance.preview_base)
	for slot_id in EquipmentLayerVisual.SLOT_ORDER:
		var item := progression_profile.catalog.equipment_item(str(progress.equipped_items.get(slot_id, "")))
		if item != null:
			_add_preview_texture(preview, item.visual_for(progress.appearance_id, false))
	return preview

func _add_preview_texture(parent: Control, texture: Texture2D) -> void:
	if texture == null:
		return
	var layer := TextureRect.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(layer)

func _emit_equip(character_id: String, item_id: String) -> void:
	equip_requested.emit(character_id, item_id)

func _emit_unequip(character_id: String, slot_id: String) -> void:
	unequip_requested.emit(character_id, slot_id)

func _build_profession_screen(progress: CharacterProgress) -> void:
	var current := progression_profile.catalog.profession(progress.profession_id)
	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 20)
	heading.text = "Profesión actual: %s\n%s\n\nEvoluciones disponibles:" % [current.display_name, current.description]
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progression_content.add_child(heading)
	if current.evolution_ids.is_empty():
		var final_label := Label.new()
		final_label.text = "No hay nuevas evoluciones configuradas para esta rama."
		progression_content.add_child(final_label)
		return
	for evolution_id in current.evolution_ids:
		var evolution := progression_profile.catalog.profession(evolution_id)
		if evolution == null:
			continue
		var button := Button.new()
		button.text = "%s · Nivel %d\n%s\nBonificaciones: %s" % [evolution.display_name, evolution.minimum_level, evolution.description, str(evolution.attribute_modifiers)]
		button.custom_minimum_size = Vector2(0, 72)
		button.disabled = not progress.can_change_profession(evolution)
		button.pressed.connect(_emit_profession_change.bind(progress.character_id, evolution.profession_id))
		progression_content.add_child(button)

func _build_skill_screen(progress: CharacterProgress) -> void:
	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 19)
	heading.text = "SP disponibles: %d · Habilidades aprendidas: %d" % [progress.sp_available, progress.learned_ability_ids.size()]
	progression_content.add_child(heading)
	for ability in progression_profile.catalog.abilities_for_character(progress):
		var learned := progress.learned_ability_ids.has(String(ability.id))
		var button := Button.new()
		button.text = "%s%s · Nv.%d · %d SP\n%s" % ["✓ " if learned else "", ability.display_name, ability.required_level, ability.sp_cost, ability.description]
		button.custom_minimum_size = Vector2(0, 62)
		button.disabled = learned or not progress.can_learn(ability)
		button.pressed.connect(_emit_learn_skill.bind(progress.character_id, String(ability.id)))
		progression_content.add_child(button)

func _emit_learn_skill(character_id: String, ability_id: String) -> void:
	learn_skill_requested.emit(character_id, ability_id)

func _emit_profession_change(character_id: String, profession_id: String) -> void:
	profession_change_requested.emit(character_id, profession_id)

func hide_progression() -> void:
	progression_overlay.visible = false
	progression_closed.emit()

func show_dialogue(lines: Array[String]) -> void:
	if lines.is_empty():
		dialogue_finished.emit()
		return
	dialogue_lines = lines.duplicate()
	dialogue_index = 0
	dialogue_overlay.visible = true
	dialogue_overlay.move_to_front()
	dialogue_label.text = dialogue_lines[0]

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_overlay.visible = false
		dialogue_finished.emit()
		return
	dialogue_label.text = dialogue_lines[dialogue_index]
