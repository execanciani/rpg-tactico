class_name CharacterSelectionScreen
extends Control

signal create_requested(character_name: String, race_id: String, profession_id: String)
signal delete_requested(character_id: String)
signal formation_toggle_requested(character_id: String)
signal adventure_requested

const SLOT_SCENE := preload("res://scenes/ui/character_slot_card.tscn")
const RACE_SCENE := preload("res://scenes/ui/race_selection_panel.tscn")
const PROFESSION_SCENE := preload("res://scenes/ui/profession_selection_panel.tscn")
const PREVIEW_SCENE := preload("res://scenes/ui/character_preview_panel.tscn")
const DELETE_DIALOG_SCENE := preload("res://scenes/ui/delete_character_dialog.tscn")

var profile: CampaignProfile
var slots_row: HBoxContainer
var start_button: Button
var status_label: Label
var creation_overlay: Control
var creation_title: Label
var creation_content: VBoxContainer
var back_button: Button
var next_button: Button
var confirm_button: Button
var creation_error: Label
var info_overlay: Control
var info_content: VBoxContainer
var delete_dialog: DeleteCharacterDialog
var creation_step := 0
var selected_race_id := ""
var selected_profession_id := ""
var pending_name := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_main_content()
	_build_creation_overlay()
	_build_info_overlay()
	delete_dialog = DELETE_DIALOG_SCENE.instantiate() as DeleteCharacterDialog
	delete_dialog.character_delete_confirmed.connect(func(character_id: String): delete_requested.emit(character_id))
	add_child(delete_dialog)

func configure(new_profile: CampaignProfile) -> void:
	profile = new_profile
	refresh()
	visible = true

func refresh() -> void:
	if profile == null or slots_row == null:
		return
	for child in slots_row.get_children():
		slots_row.remove_child(child)
		child.queue_free()
	for slot_index in CampaignProfile.MAX_CHARACTERS:
		var card := SLOT_SCENE.instantiate() as CharacterSlotCard
		slots_row.add_child(card)
		if slot_index < profile.slot_ids.size():
			var character_id := profile.slot_ids[slot_index]
			var progress := profile.character(character_id)
			if progress != null:
				card.show_character(
					progress, profile.catalog.race(progress.race_id), profile.catalog.profession(progress.profession_id),
					profile.formation_ids.has(character_id)
				)
				card.selection_toggled.connect(func(id: String): formation_toggle_requested.emit(id))
				card.info_requested.connect(_show_character_info)
				card.delete_requested.connect(_request_delete)
				continue
		card.show_empty(slot_index + 1)
		card.empty_pressed.connect(_open_creation)
	start_button.disabled = profile.formation_ids.is_empty()
	status_label.text = "%d/3 personajes · %d seleccionados" % [profile.characters.size(), profile.formation_ids.size()]

func creation_succeeded() -> void:
	creation_overlay.visible = false
	pending_name = ""
	refresh()

func show_creation_error(message: String) -> void:
	creation_error.text = message
	creation_error.visible = true

func _build_main_content() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title_panel := PanelContainer.new()
	title_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_panel.custom_minimum_size = Vector2(620, 72)
	title_panel.add_theme_stylebox_override("panel", _title_style())
	column.add_child(title_panel)
	var title := Label.new()
	title.text = "SELECCIONAR PERSONAJES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#f0c76a"))
	title.add_theme_color_override("font_outline_color", Color("#50371a"))
	title.add_theme_constant_override("outline_size", 5)
	title_panel.add_child(title)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("#aec7d8"))
	column.add_child(status_label)
	var slots_scroll := ScrollContainer.new()
	slots_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slots_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(slots_scroll)
	slots_row = HBoxContainer.new()
	slots_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_row.add_theme_constant_override("separation", 16)
	slots_scroll.add_child(slots_row)
	start_button = Button.new()
	start_button.text = "COMENZAR AVENTURA"
	start_button.custom_minimum_size = Vector2(520, 68)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_font_size_override("font_size", 22)
	_apply_primary_button_style(start_button)
	start_button.pressed.connect(func(): adventure_requested.emit())
	column.add_child(start_button)

func _build_creation_overlay() -> void:
	creation_overlay = ColorRect.new()
	creation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	creation_overlay.color = Color(0.02, 0.04, 0.08, 0.94)
	creation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	creation_overlay.visible = false
	add_child(creation_overlay)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_top = 0.04
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.96
	panel.add_theme_stylebox_override("panel", _panel_style())
	creation_overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	creation_title = Label.new()
	creation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creation_title.add_theme_font_size_override("font_size", 28)
	creation_title.add_theme_color_override("font_color", Color("#f0c76a"))
	column.add_child(creation_title)
	creation_error = Label.new()
	creation_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creation_error.add_theme_color_override("font_color", Color("#ff9a8e"))
	creation_error.visible = false
	column.add_child(creation_error)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	creation_content = VBoxContainer.new()
	creation_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creation_content.add_theme_constant_override("separation", 10)
	scroll.add_child(creation_content)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	column.add_child(navigation)
	var cancel_button := Button.new()
	cancel_button.text = "CANCELAR"
	cancel_button.custom_minimum_size = Vector2(150, 52)
	cancel_button.pressed.connect(func(): creation_overlay.visible = false)
	navigation.add_child(cancel_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(spacer)
	back_button = Button.new()
	back_button.text = "ATRÁS"
	back_button.custom_minimum_size = Vector2(150, 52)
	back_button.pressed.connect(_previous_creation_step)
	navigation.add_child(back_button)
	next_button = Button.new()
	next_button.text = "SIGUIENTE"
	next_button.custom_minimum_size = Vector2(150, 52)
	next_button.pressed.connect(_next_creation_step)
	navigation.add_child(next_button)
	confirm_button = Button.new()
	confirm_button.text = "CREAR"
	confirm_button.custom_minimum_size = Vector2(150, 52)
	confirm_button.pressed.connect(_confirm_creation)
	navigation.add_child(confirm_button)

func _build_info_overlay() -> void:
	info_overlay = ColorRect.new()
	info_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_overlay.color = Color(0.02, 0.04, 0.08, 0.94)
	info_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	info_overlay.visible = false
	add_child(info_overlay)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.15
	panel.anchor_top = 0.15
	panel.anchor_right = 0.85
	panel.anchor_bottom = 0.85
	panel.add_theme_stylebox_override("panel", _panel_style())
	info_overlay.add_child(panel)
	info_content = VBoxContainer.new()
	info_content.add_theme_constant_override("separation", 16)
	panel.add_child(info_content)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CERRAR"
	close_button.custom_minimum_size = Vector2(0, 52)
	close_button.pressed.connect(func(): info_overlay.visible = false)
	info_content.add_child(close_button)

func _open_creation() -> void:
	if profile == null or profile.characters.size() >= CampaignProfile.MAX_CHARACTERS:
		return
	creation_step = 0
	selected_race_id = ""
	selected_profession_id = ""
	pending_name = ""
	creation_overlay.visible = true
	creation_overlay.move_to_front()
	_show_creation_step()

func _show_creation_step() -> void:
	for child in creation_content.get_children():
		creation_content.remove_child(child)
		child.queue_free()
	creation_error.visible = false
	back_button.disabled = creation_step == 0
	next_button.visible = creation_step < 3
	confirm_button.visible = creation_step == 3
	match creation_step:
		0:
			creation_title.text = "PASO 1 · SELECCIONAR RAZA"
			var panel := RACE_SCENE.instantiate() as RaceSelectionPanel
			panel.race_selected.connect(func(race_id: String):
				selected_race_id = race_id
				selected_profession_id = ""
				next_button.disabled = false
			)
			creation_content.add_child(panel)
			panel.configure(profile.catalog, selected_race_id)
			next_button.disabled = selected_race_id.is_empty()
		1:
			creation_title.text = "PASO 2 · SELECCIONAR PROFESIÓN"
			var panel := PROFESSION_SCENE.instantiate() as ProfessionSelectionPanel
			panel.profession_selected.connect(func(profession_id: String):
				selected_profession_id = profession_id
				next_button.disabled = false
			)
			creation_content.add_child(panel)
			panel.configure(profile.catalog, profile.catalog.race(selected_race_id), selected_profession_id)
			next_button.disabled = selected_profession_id.is_empty()
		2:
			creation_title.text = "PASO 3 · VISTA PREVIA"
			var preview := PREVIEW_SCENE.instantiate() as CharacterPreviewPanel
			creation_content.add_child(preview)
			preview.configure(profile.catalog, selected_race_id, selected_profession_id)
			next_button.disabled = false
		3:
			creation_title.text = "PASO 4 · NOMBRE Y CONFIRMACIÓN"
			var preview := PREVIEW_SCENE.instantiate() as CharacterPreviewPanel
			creation_content.add_child(preview)
			preview.configure(profile.catalog, selected_race_id, selected_profession_id, pending_name)
			var name_edit := LineEdit.new()
			name_edit.placeholder_text = "Nombre de 3 a 16 caracteres"
			name_edit.max_length = CampaignProfile.MAX_NAME_LENGTH
			name_edit.text = pending_name
			name_edit.custom_minimum_size = Vector2(0, 52)
			name_edit.text_changed.connect(func(value: String):
				pending_name = value
				creation_error.visible = false
			)
			creation_content.add_child(name_edit)
			name_edit.grab_focus()

func _next_creation_step() -> void:
	if creation_step == 0 and selected_race_id.is_empty():
		return
	if creation_step == 1 and selected_profession_id.is_empty():
		return
	creation_step = mini(3, creation_step + 1)
	_show_creation_step()

func _previous_creation_step() -> void:
	creation_step = maxi(0, creation_step - 1)
	_show_creation_step()

func _confirm_creation() -> void:
	create_requested.emit(pending_name, selected_race_id, selected_profession_id)

func _show_character_info(character_id: String) -> void:
	var progress := profile.character(character_id)
	if progress == null:
		return
	for child in info_content.get_children():
		if child.name != "CloseButton":
			info_content.remove_child(child)
			child.queue_free()
	var preview := PREVIEW_SCENE.instantiate() as CharacterPreviewPanel
	info_content.add_child(preview)
	info_content.move_child(preview, 0)
	preview.configure(profile.catalog, progress.race_id, progress.profession_id, "%s · Nivel %d" % [progress.display_name, progress.level])
	info_overlay.visible = true
	info_overlay.move_to_front()

func _request_delete(character_id: String) -> void:
	var progress := profile.character(character_id)
	if progress != null:
		delete_dialog.request_delete(character_id, progress.display_name)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#102039")
	style.border_color = Color("#d6aa52")
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	return style

func _title_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#102b56")
	style.border_color = Color("#f0c04f")
	style.set_border_width_all(5)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	return style

func _apply_primary_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#155ab1")
	normal.border_color = Color("#f0c04f")
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(9)
	normal.set_content_margin_all(10)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#2677d2")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#263b57")
	disabled.border_color = Color("#776b51")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("#fff0bd"))
	button.add_theme_color_override("font_outline_color", Color("#3b2712"))
	button.add_theme_constant_override("outline_size", 3)
