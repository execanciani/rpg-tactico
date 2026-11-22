class_name InventoryScreen
extends Control

signal closed
signal equip_requested(character_id: String, item_id: String)
signal unequip_requested(character_id: String, slot_id: String)
signal use_requested(character_id: String, slot_index: int)
signal discard_requested(character_id: String, slot_index: int, quantity: int)
signal move_requested(character_id: String, from_index: int, to_index: int)
signal split_requested(character_id: String, slot_index: int, quantity: int)
signal sort_requested(character_id: String)

const GOLD := Color("#d8ab4f")
const BLUE := Color("#0d1b36")
const PANEL_BLUE := Color("#132746")
const SLOT_NAMES := {
	"head": "Cabeza", "torso": "Torso", "legs": "Piernas", "hands": "Guantes",
	"feet": "Botas", "cape": "Capa", "main_hand": "Arma principal",
	"off_hand": "Arma secundaria", "accessory": "Accesorio",
}

var profile: CampaignProfile
var character_id := ""
var consumables_allowed := true
var selected_slot := -1
var selected_equipment_slot := ""
var move_source := -1
var filter_id := "all"

var character_selector: OptionButton
var character_info: Label
var portrait: TextureRect
var preview_container: Control
var preview_widget: CharacterEquipmentPreview
var preview_direction_buttons: Dictionary = {}
var equipment_grid: GridContainer
var inventory_grid: GridContainer
var capacity_label: Label
var filter_selector: OptionButton
var item_name_label: Label
var item_description_label: Label
var status_label: Label
var equip_button: Button
var use_button: Button
var discard_button: Button
var move_button: Button
var split_button: Button
var discard_dialog: ConfirmationDialog

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_interface()

func open(new_profile: CampaignProfile, preferred_character_id := "", allow_consumables := true) -> void:
	profile = new_profile
	consumables_allowed = allow_consumables
	var ids: Array[String] = []
	ids.assign(profile.slot_ids)
	if ids.is_empty():
		return
	character_id = preferred_character_id if profile.characters.has(preferred_character_id) else ids[0]
	selected_slot = -1
	selected_equipment_slot = ""
	move_source = -1
	_rebuild_character_selector()
	refresh()
	visible = true
	move_to_front()

func refresh() -> void:
	if profile == null or not profile.characters.has(character_id):
		return
	profile.ensure_character_vitals(profile.character(character_id))
	_rebuild_character_panel()
	_rebuild_preview()
	_rebuild_equipment()
	_rebuild_inventory()
	_refresh_item_details()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = BLUE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 52
	root.add_child(header)
	var title := Label.new()
	title.text = "INVENTARIO Y EQUIPAMIENTO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ffe09a"))
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "CERRAR"
	close_button.custom_minimum_size = Vector2(140, 48)
	close_button.pressed.connect(_close)
	header.add_child(close_button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)
	body.add_child(_build_left_panel())
	body.add_child(_build_center_panel())
	body.add_child(_build_right_panel())
	status_label = Label.new()
	status_label.custom_minimum_size.y = 26
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("#f4c96e"))
	root.add_child(status_label)
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Descartar objeto"
	discard_dialog.dialog_text = "Esta accion no se puede deshacer."
	discard_dialog.confirmed.connect(_confirm_discard)
	add_child(discard_dialog)

func _build_left_panel() -> Control:
	var panel := _panel(Vector2(255, 0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	character_selector = OptionButton.new()
	character_selector.custom_minimum_size.y = 48
	character_selector.item_selected.connect(_select_character)
	column.add_child(character_selector)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(150, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(portrait)
	character_info = Label.new()
	character_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_info.add_theme_font_size_override("font_size", 16)
	column.add_child(character_info)
	return panel

func _build_center_panel() -> Control:
	var panel := _panel(Vector2(300, 0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "EQUIPAMIENTO"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", GOLD)
	column.add_child(heading)
	preview_container = Control.new()
	preview_container.custom_minimum_size = Vector2(250, 205)
	preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(preview_container)
	preview_widget = CharacterEquipmentPreview.new()
	preview_widget.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_widget.direction_changed.connect(_on_preview_direction_changed)
	preview_container.add_child(preview_widget)
	var direction_row := HBoxContainer.new()
	direction_row.alignment = BoxContainer.ALIGNMENT_CENTER
	direction_row.add_theme_constant_override("separation", 8)
	column.add_child(direction_row)
	var directions := {"front": "Frente", "right": "Der.", "back": "Espalda", "left": "Izq."}
	var direction_group := ButtonGroup.new()
	for direction: String in directions:
		var button := Button.new()
		button.text = directions[direction]
		button.tooltip_text = {"right": "Derecha", "left": "Izquierda"}.get(direction, button.text)
		button.custom_minimum_size.y = 44
		button.toggle_mode = true
		button.button_group = direction_group
		button.pressed.connect(preview_widget.set_direction.bind(direction))
		direction_row.add_child(button)
		preview_direction_buttons[direction] = button
	equipment_grid = GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.add_theme_constant_override("h_separation", 6)
	equipment_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(equipment_grid)
	return panel

func _build_right_panel() -> Control:
	var panel := _panel(Vector2(520, 0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	var tools := HBoxContainer.new()
	column.add_child(tools)
	capacity_label = Label.new()
	capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capacity_label.add_theme_font_size_override("font_size", 19)
	capacity_label.add_theme_color_override("font_color", GOLD)
	tools.add_child(capacity_label)
	filter_selector = OptionButton.new()
	for entry in [["Todos", "all"], ["Equipo", "equipment"], ["Consumibles", "consumable"], ["Materiales", "material"]]:
		filter_selector.add_item(entry[0])
		filter_selector.set_item_metadata(filter_selector.item_count - 1, entry[1])
	filter_selector.item_selected.connect(_select_filter)
	tools.add_child(filter_selector)
	var sort_button := Button.new()
	sort_button.text = "Ordenar"
	sort_button.custom_minimum_size = Vector2(92, 44)
	sort_button.pressed.connect(func(): sort_requested.emit(character_id))
	tools.add_child(sort_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 5
	inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_grid.add_theme_constant_override("h_separation", 5)
	inventory_grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(inventory_grid)
	var details := PanelContainer.new()
	details.custom_minimum_size.y = 126
	details.add_theme_stylebox_override("panel", _style(Color("#0b172c"), Color("#806a3d"), 2))
	column.add_child(details)
	var detail_column := VBoxContainer.new()
	details.add_child(detail_column)
	item_name_label = Label.new()
	item_name_label.add_theme_font_size_override("font_size", 19)
	item_name_label.add_theme_color_override("font_color", Color("#9fd7ff"))
	detail_column.add_child(item_name_label)
	item_description_label = Label.new()
	item_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_column.add_child(item_description_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	column.add_child(actions)
	equip_button = _action_button("Equipar")
	use_button = _action_button("Usar")
	discard_button = _action_button("Descartar")
	move_button = _action_button("Mover")
	split_button = _action_button("Separar")
	for button in [equip_button, use_button, discard_button, move_button, split_button]:
		actions.add_child(button)
	equip_button.pressed.connect(_equip_selected)
	use_button.pressed.connect(func(): use_requested.emit(character_id, selected_slot))
	discard_button.pressed.connect(_request_discard)
	move_button.pressed.connect(_begin_move)
	split_button.pressed.connect(_split_selected)
	return panel

func _rebuild_character_selector() -> void:
	character_selector.clear()
	var selected_index := 0
	for id in profile.slot_ids:
		var progress := profile.character(id)
		if progress == null:
			continue
		character_selector.add_item(progress.display_name)
		character_selector.set_item_metadata(character_selector.item_count - 1, id)
		if id == character_id:
			selected_index = character_selector.item_count - 1
	character_selector.select(selected_index)

func _rebuild_character_panel() -> void:
	var progress := profile.character(character_id)
	var race := profile.catalog.race(progress.race_id)
	var profession := profile.catalog.profession(progress.profession_id)
	var stats := profile.calculated_stats(progress)
	var attributes: Dictionary = stats.attributes
	var derived: Dictionary = stats.derived
	var portrait_path := "res://assets/portraits/races/portrait_%s.png" % progress.race_id
	portrait.texture = load(portrait_path) as Texture2D if ResourceLoader.exists(portrait_path) else null
	character_info.text = "%s\nNv. %d · %s\n%s\n\nHP %d/%d   MP %d/%d\n\nSTR %d   DEX %d   CON %d\nINT %d   WIS %d   MEN %d\n\nATQ %d   MAG %d\nDEF %d   RES %d\nVEL %d   EVA %d\nPREC %d   CRIT %d%%" % [
		progress.display_name, progress.level, profession.display_name, race.display_name,
		progress.current_hp, int(derived.max_hp), progress.current_mp, int(derived.max_mp),
		int(attributes.STR), int(attributes.DEX), int(attributes.CON), int(attributes.INT), int(attributes.WIS), int(attributes.MEN),
		int(derived.physical_attack), int(derived.magical_attack), int(derived.physical_defense), int(derived.magical_defense),
		int(derived.speed), int(derived.evasion), int(derived.accuracy), int(derived.critical_chance),
	]

func _rebuild_preview() -> void:
	var progress := profile.character(character_id)
	preview_widget.configure(profile, progress)
	_on_preview_direction_changed(preview_widget.current_direction)

func _on_preview_direction_changed(direction: String) -> void:
	var button := preview_direction_buttons.get(direction) as Button
	if button != null:
		button.set_pressed_no_signal(true)

func _rebuild_equipment() -> void:
	for child in equipment_grid.get_children():
		child.queue_free()
	var progress := profile.character(character_id)
	for slot_id in EquipmentItemData.SLOT_KEYS:
		var item := profile.catalog.item(str(progress.equipped_items.get(slot_id, "")))
		var button := Button.new()
		button.custom_minimum_size = Vector2(138, 45)
		button.text = "%s\n%s" % [SLOT_NAMES.get(slot_id, slot_id), item.display_name if item != null else "—"]
		var equipped_border := Color("#5fbf85") if item != null else Color("#3e5878")
		if selected_equipment_slot == slot_id:
			equipped_border = Color("#ffd36b")
		_apply_slot_style(button, equipped_border, item == null)
		button.pressed.connect(_select_equipped.bind(slot_id))
		equipment_grid.add_child(button)

func _rebuild_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	var progress := profile.character(character_id)
	capacity_label.text = "Inventario (%d/%d)" % [progress.occupied_slot_count(), CharacterProgress.INVENTORY_CAPACITY]
	for slot_index in CharacterProgress.INVENTORY_CAPACITY:
		var slot := progress.inventory_slot(slot_index)
		var item := profile.catalog.item(str(slot.get("item_id", "")))
		var button := Button.new()
		button.custom_minimum_size = Vector2(88, 76)
		button.text = ""
		button.tooltip_text = "Espacio %d" % (slot_index + 1)
		var border_color := Color("#334c6d")
		if item != null and _passes_filter(item):
			button.icon = item.icon
			button.expand_icon = true
			button.text = "×%d" % int(slot.quantity) if int(slot.quantity) > 1 else ""
			button.tooltip_text = "%s · %d/%d" % [item.display_name, int(slot.quantity), item.stack_limit()]
			border_color = Color("#6f83a0") if item.can_be_used_by(progress) or not item.is_equipment() else Color("#a85c5c")
		elif item != null:
			button.modulate = Color(0.45, 0.45, 0.55, 0.65)
			border_color = Color("#4a4f61")
		if selected_slot == slot_index:
			border_color = Color("#ffd36b")
		_apply_slot_style(button, border_color, item == null)
		button.disabled = item != null and not _passes_filter(item) and move_source < 0
		button.pressed.connect(_select_inventory_slot.bind(slot_index))
		inventory_grid.add_child(button)

func _refresh_item_details() -> void:
	var progress := profile.character(character_id)
	var slot := progress.inventory_slot(selected_slot)
	var item := profile.catalog.item(str(slot.get("item_id", "")))
	if item == null and not selected_equipment_slot.is_empty():
		item = profile.catalog.item(str(progress.equipped_items.get(selected_equipment_slot, "")))
	if item == null:
		item_name_label.text = "Selecciona un objeto"
		item_description_label.text = "Toca una ranura para ver su descripcion y acciones disponibles."
	else:
		var bonuses := item.derived_bonuses if not item.derived_bonuses.is_empty() else item.attribute_bonuses
		item_name_label.text = item.display_name
		item_description_label.text = "%s\nCategoria: %s · Nivel %d · Precio %d · Peso %.1f\nBonificaciones/efectos: %s" % [
			item.description, item.category, item.minimum_level, item.base_price, item.weight,
			str(item.consumable_effects if item.is_consumable() else bonuses),
		]
	equip_button.text = "Desequipar" if not selected_equipment_slot.is_empty() else "Equipar"
	equip_button.disabled = item == null or (selected_equipment_slot.is_empty() and (not item.is_equipment() or not item.can_be_used_by(progress)))
	use_button.disabled = item == null or not item.is_consumable() or not consumables_allowed or selected_slot < 0
	discard_button.disabled = item == null or selected_slot < 0
	move_button.disabled = item == null or selected_slot < 0
	split_button.disabled = item == null or selected_slot < 0 or not item.stackable or int(slot.get("quantity", 0)) < 2 or progress.first_empty_slot() < 0
	if not consumables_allowed and item != null and item.is_consumable():
		status_label.text = "Durante el combate, Usar queda bloqueado hasta integrarlo con las reglas de turno."

func _select_inventory_slot(slot_index: int) -> void:
	if move_source >= 0:
		move_requested.emit(character_id, move_source, slot_index)
		move_source = -1
		status_label.text = ""
		return
	selected_slot = slot_index
	selected_equipment_slot = ""
	_rebuild_inventory()
	_rebuild_equipment()
	_refresh_item_details()

func _select_equipped(slot_id: String) -> void:
	selected_equipment_slot = slot_id
	selected_slot = -1
	_rebuild_inventory()
	_rebuild_equipment()
	_refresh_item_details()

func _equip_selected() -> void:
	if not selected_equipment_slot.is_empty():
		unequip_requested.emit(character_id, selected_equipment_slot)
		return
	var slot := profile.character(character_id).inventory_slot(selected_slot)
	var item := profile.catalog.item(str(slot.get("item_id", "")))
	if item != null:
		equip_requested.emit(character_id, item.item_id)

func _begin_move() -> void:
	move_source = selected_slot
	status_label.text = "Selecciona la ranura de destino. Tocar una ocupada intercambia ambos objetos."
	_rebuild_inventory()

func _split_selected() -> void:
	var slot := profile.character(character_id).inventory_slot(selected_slot)
	var amount := int(slot.get("quantity", 0)) / 2
	if amount > 0:
		split_requested.emit(character_id, selected_slot, amount)

func _request_discard() -> void:
	var slot := profile.character(character_id).inventory_slot(selected_slot)
	var item := profile.catalog.item(str(slot.get("item_id", "")))
	if item == null:
		return
	discard_dialog.dialog_text = "¿Descartar 1 × %s? Esta accion no se puede deshacer." % item.display_name
	discard_dialog.popup_centered(Vector2i(500, 180))

func _confirm_discard() -> void:
	discard_requested.emit(character_id, selected_slot, 1)

func _select_character(index: int) -> void:
	character_id = str(character_selector.get_item_metadata(index))
	selected_slot = -1
	selected_equipment_slot = ""
	move_source = -1
	refresh()

func _select_filter(index: int) -> void:
	filter_id = str(filter_selector.get_item_metadata(index))
	_rebuild_inventory()

func _passes_filter(item: EquipmentItemData) -> bool:
	return filter_id == "all" or (filter_id == "equipment" and item.is_equipment()) \
		or (filter_id == "consumable" and item.is_consumable()) or (filter_id == "material" and item.is_material())

func show_status(message: String, success := true) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color("#9fe0bd") if success else Color("#ff9a8e"))
	refresh()

func _close() -> void:
	visible = false
	closed.emit()

func _panel(minimum: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	panel.add_theme_stylebox_override("panel", _style(PANEL_BLUE, GOLD, 3))
	return panel

func _action_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(90, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _apply_slot_style(button: Button, border: Color, empty: bool) -> void:
	var normal := _style(Color("#0b172b") if empty else Color("#15243a"), border, 2)
	normal.set_corner_radius_all(5)
	normal.set_content_margin_all(4)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#213957")
	hover.border_color = border.lightened(0.18)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#2a4160")
	pressed.border_color = Color("#ffe19a")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#101727")
	disabled.border_color = Color("#3a4050")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

func _style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(10)
	return style
