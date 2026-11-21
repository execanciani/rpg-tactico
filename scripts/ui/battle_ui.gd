class_name BattleUI
extends Control

signal move_requested
signal attack_requested
signal skill_requested
signal wait_requested
signal item_requested
signal item_selected(item_id: String)
signal ability_selected(ability_id: StringName)
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
var item_button: Button
var message_label: Label
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label
var result_button: Button
var inventory_overlay: PanelContainer
var inventory_list: VBoxContainer
var inventory_title: Label
var ability_overlay: PanelContainer
var ability_list: VBoxContainer
var ability_title: Label
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
	_build_inventory_overlay()
	_build_ability_overlay()
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
	item_button = _action_button("Objetos\n[I]", "Consumir o equipar un objeto")
	wait_button = _action_button("Esperar\n[W]", "Finalizar la acción")
	for button in [move_button, attack_button, skill_button, item_button, wait_button]:
		row.add_child(button)
	move_button.pressed.connect(func(): move_requested.emit())
	attack_button.pressed.connect(func(): attack_requested.emit())
	skill_button.pressed.connect(func(): skill_requested.emit())
	item_button.pressed.connect(func(): item_requested.emit())
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

func _build_inventory_overlay() -> void:
	inventory_overlay = PanelContainer.new()
	inventory_overlay.set_anchors_preset(Control.PRESET_CENTER)
	inventory_overlay.offset_left = -285
	inventory_overlay.offset_top = -230
	inventory_overlay.offset_right = 285
	inventory_overlay.offset_bottom = 230
	inventory_overlay.add_theme_stylebox_override("panel", _panel_style(Color("#101a24f5"), Color("#7aa3b5")))
	inventory_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_overlay.visible = false
	add_child(inventory_overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	inventory_overlay.add_child(column)
	inventory_title = Label.new()
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_title.add_theme_font_size_override("font_size", 24)
	inventory_title.add_theme_color_override("font_color", Color("#ffe195"))
	column.add_child(inventory_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 7)
	scroll.add_child(inventory_list)
	var close_button := Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.pressed.connect(hide_inventory)
	column.add_child(close_button)

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

func set_mission(title: String, current: int, total: int, gold := 0) -> void:
	mission_label.text = "MISIÓN %d/%d · %s · %d oro" % [current, total, title, gold]

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
	unit_stats_label.text = "HP %d/%d   MP %d/%d   XP %d/%d\nATQ %d   MAG %d   DEF %d   RES %d\nMOV %d (%d)   VEL %d   ALT %d\nEquipo: %s\nEstados: %s" % [
		unit.hp, unit.max_hp, unit.mp, unit.max_mp, unit.xp, unit.xp_to_next,
		unit.physical_attack, unit.magical_attack, unit.effective_physical_defense(), unit.effective_magical_defense(),
		unit.effective_move_range(), unit.move_range, unit.speed, unit.elevation,
		unit.equipped_summary, unit.status_summary(),
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
	item_button.disabled = not can_act
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

func show_inventory(entries: Array[Dictionary], unit: UnitData) -> void:
	inventory_title.text = "Inventario · %s" % unit.display_name
	for child in inventory_list.get_children():
		child.queue_free()
	for entry in entries:
		var button := Button.new()
		button.text = "%s ×%d · %s\n%s" % [str(entry.name), int(entry.quantity), "EQUIPAR" if bool(entry.equippable) else "USAR", str(entry.description)]
		button.custom_minimum_size = Vector2(0, 62)
		button.pressed.connect(_emit_item_selected.bind(str(entry.id)))
		inventory_list.add_child(button)
	inventory_overlay.visible = true
	inventory_overlay.move_to_front()

func _emit_item_selected(item_id: String) -> void:
	item_selected.emit(item_id)

func hide_inventory() -> void:
	inventory_overlay.visible = false

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
