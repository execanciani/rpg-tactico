class_name BattleUI
extends Control

signal move_requested
signal attack_requested
signal skill_requested
signal wait_requested
signal save_requested
signal load_requested
signal continue_requested

var turn_label: Label
var mission_label: Label
var hint_label: Label
var unit_name_label: Label
var unit_stats_label: Label
var move_button: Button
var attack_button: Button
var skill_button: Button
var wait_button: Button
var message_label: Label
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label
var result_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_unit_panel()
	_build_action_panel()
	_build_message_log()
	_build_result_overlay()
	show_unit(null)

func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.name = "TurnPanel"
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
	mission_label.text = "MISIÓN 1/3"
	mission_label.custom_minimum_size = Vector2(270, 0)
	mission_label.clip_text = true
	mission_label.add_theme_font_size_override("font_size", 15)
	mission_label.add_theme_color_override("font_color", Color("#9fd5bd"))
	row.add_child(mission_label)
	turn_label = Label.new()
	turn_label.text = "RONDA 1 · TURNO DEL JUGADOR"
	turn_label.add_theme_font_size_override("font_size", 19)
	turn_label.add_theme_color_override("font_color", Color("#ffe29a"))
	row.add_child(turn_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	hint_label = Label.new()
	hint_label.text = "Seleccioná una unidad azul"
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

func _build_unit_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "UnitPanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 18
	panel.offset_top = -165
	panel.offset_right = 330
	panel.offset_bottom = -18
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#17222cef"), Color("#557a89")))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	unit_name_label = Label.new()
	unit_name_label.add_theme_font_size_override("font_size", 22)
	unit_name_label.add_theme_color_override("font_color", Color("#f3d78f"))
	column.add_child(unit_name_label)
	unit_stats_label = Label.new()
	unit_stats_label.add_theme_font_size_override("font_size", 16)
	unit_stats_label.add_theme_color_override("font_color", Color("#d9e2e6"))
	column.add_child(unit_stats_label)

func _build_action_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "ActionPanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -590
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
	wait_button = _action_button("Esperar\n[W]", "Finalizar la acción de esta unidad")
	row.add_child(move_button)
	row.add_child(attack_button)
	row.add_child(skill_button)
	row.add_child(wait_button)
	move_button.pressed.connect(func(): move_requested.emit())
	attack_button.pressed.connect(func(): attack_requested.emit())
	skill_button.pressed.connect(func(): skill_requested.emit())
	wait_button.pressed.connect(func(): wait_requested.emit())

func _build_message_log() -> void:
	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	message_label.offset_left = -430
	message_label.offset_top = 88
	message_label.offset_right = -22
	message_label.offset_bottom = 126
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color("#ffffff"))
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
	center.offset_left = -250
	center.offset_top = -115
	center.offset_right = 250
	center.offset_bottom = 115
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
	result_button.text = "Jugar de nuevo"
	result_button.custom_minimum_size = Vector2(220, 54)
	result_button.add_theme_font_size_override("font_size", 19)
	result_button.pressed.connect(func(): continue_requested.emit())
	center.add_child(result_button)

func _action_button(text_value: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(130, 58)
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
	mission_label.text = "MISIÓN %d/%d · %s" % [current, total, title.to_upper()]

func set_hint(value: String) -> void:
	hint_label.text = value

func show_message(value: String, color: Color = Color.WHITE) -> void:
	message_label.text = value
	message_label.add_theme_color_override("font_color", color)
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.45)

func show_unit(unit: UnitData) -> void:
	if unit == null:
		unit_name_label.text = "Sin unidad seleccionada"
		unit_stats_label.text = "Elegí una unidad azul para actuar."
		return
	unit_name_label.text = "%s · Nv. %d %s" % [unit.display_name, unit.level, unit.class_name_text]
	unit_stats_label.text = "HP  %d / %d     MP  %d / %d\nATQ %d   MAG %d   DEF %d   RES %d\nMOV %d   VEL %d   ALT %d" % [
		unit.hp, unit.max_hp, unit.mp, unit.max_mp,
		unit.physical_attack, unit.magical_attack, unit.physical_defense, unit.magical_defense,
		unit.move_range, unit.speed, unit.elevation,
	]

func configure_actions(unit: UnitData, enabled: bool) -> void:
	var can_act := enabled and unit != null and unit.is_alive() and not unit.has_acted
	move_button.disabled = not can_act or unit.has_moved
	attack_button.disabled = not can_act
	skill_button.disabled = not can_act or unit.abilities.is_empty() or not unit.can_spend_mp(unit.abilities[0].mp_cost)
	wait_button.disabled = not can_act
	if unit != null and not unit.abilities.is_empty():
		var ability: AbilityData = unit.abilities[0]
		skill_button.text = "%s (%d MP)\n[S]" % [ability.display_name, ability.mp_cost]
	else:
		skill_button.text = "Habilidad\n[S]"

func show_result(victory: bool, rounds: int, has_next_mission: bool = false) -> void:
	result_overlay.visible = true
	result_title.text = "¡VICTORIA!" if victory else "DERROTA"
	result_title.add_theme_color_override("font_color", Color("#ffe18a") if victory else Color("#ff7770"))
	result_detail.text = "Todos los enemigos fueron derrotados en %d rondas." % rounds if victory else "Tu escuadrón cayó. Ajustá la táctica e intentá de nuevo."
	result_button.text = "Siguiente misión" if victory and has_next_mission else ("Reiniciar campaña" if victory else "Reintentar misión")

func hide_result() -> void:
	result_overlay.visible = false
