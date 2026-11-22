class_name VisualDiagnostics
extends Control

const CLASSES := ["warrior", "mage", "archer", "acolyte", "explorer"]
const STATES := ["idle", "walk", "attack", "cast", "hurt", "death"]
const KITS := {
	"warrior": ["iron_helmet", "iron_armor", "iron_boots", "iron_sword", "iron_shield"],
	"mage": ["cloth_hood", "arcane_robe", "cloth_gloves", "apprentice_sandals", "apprentice_staff"],
	"archer": ["leather_vest", "archer_gloves", "light_boots", "wooden_bow"],
	"acolyte": ["white_hood", "healer_robe", "cloth_boots", "ceremonial_staff"],
	"explorer": ["dark_hood", "light_armor", "explorer_boots", "iron_daggers"],
}

var profile := CampaignProfile.new()
var preview: CharacterEquipmentPreview
var class_selector: OptionButton
var state_selector: OptionButton
var direction_label: Label
var diagnostics_label: Label
var icon_grid: GridContainer
var progress: CharacterProgress

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_select_class(0)

func _build() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#081326")
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var title := Label.new()
	title.text = "DIAGNÓSTICO VISUAL · FASE 5"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f0c96f"))
	root.add_child(title)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 390
	controls.add_theme_constant_override("separation", 8)
	body.add_child(controls)
	class_selector = OptionButton.new()
	for class_id in CLASSES:
		class_selector.add_item(class_id.capitalize())
		class_selector.set_item_metadata(class_selector.item_count - 1, class_id)
	class_selector.item_selected.connect(_select_class)
	controls.add_child(class_selector)
	state_selector = OptionButton.new()
	for state in STATES:
		state_selector.add_item(state.capitalize())
		state_selector.set_item_metadata(state_selector.item_count - 1, state)
	state_selector.item_selected.connect(_select_state)
	controls.add_child(state_selector)
	preview = CharacterEquipmentPreview.new()
	preview.custom_minimum_size = Vector2(390, 410)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.direction_changed.connect(func(direction: String): direction_label.text = direction.to_upper())
	controls.add_child(preview)
	var turns := HBoxContainer.new()
	turns.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_child(turns)
	var left := Button.new()
	left.text = "◀ GIRAR"
	left.pressed.connect(func(): preview.turn(-1); _select_state(state_selector.selected))
	turns.add_child(left)
	direction_label = Label.new()
	direction_label.custom_minimum_size.x = 100
	direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turns.add_child(direction_label)
	var right := Button.new()
	right.text = "GIRAR ▶"
	right.pressed.connect(func(): preview.turn(1); _select_state(state_selector.selected))
	turns.add_child(right)
	var equipment_row := HBoxContainer.new()
	controls.add_child(equipment_row)
	var bare := Button.new()
	bare.text = "CUERPO BASE"
	bare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bare.pressed.connect(_show_bare)
	equipment_row.add_child(bare)
	var kit := Button.new()
	kit.text = "KIT COMPLETO"
	kit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kit.pressed.connect(_equip_kit)
	equipment_row.add_child(kit)
	diagnostics_label = Label.new()
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics_label.add_theme_color_override("font_color", Color("#9fc4d9"))
	controls.add_child(diagnostics_label)
	var icons_panel := VBoxContainer.new()
	icons_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(icons_panel)
	var icons_title := Label.new()
	icons_title.text = "CATÁLOGO · 33 ICONOS 64×64"
	icons_title.add_theme_font_size_override("font_size", 20)
	icons_title.add_theme_color_override("font_color", Color("#f0c96f"))
	icons_panel.add_child(icons_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icons_panel.add_child(scroll)
	icon_grid = GridContainer.new()
	icon_grid.columns = 6
	icon_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(icon_grid)
	_build_icons()

func _select_class(index: int) -> void:
	var class_id := str(class_selector.get_item_metadata(index))
	profile.initialize_new()
	progress = profile.create_character("diagnostic", "Diagnóstico", "human", class_id)
	if progress == null:
		return
	progress.appearance_id = class_id
	preview.configure(profile, progress)
	preview.set_direction("front")
	state_selector.select(0)
	preview.play_state("idle")
	_update_diagnostics(class_id)

func _select_state(index: int) -> void:
	var state := str(state_selector.get_item_metadata(index))
	if not preview.play_state(state):
		diagnostics_label.text = "No existe una secuencia %s para esta orientación; se conserva el fallback documentado." % state

func _show_bare() -> void:
	progress.equipped_items.clear()
	preview.configure(profile, progress)
	_select_state(state_selector.selected)

func _equip_kit() -> void:
	progress.equipped_items.clear()
	var class_id := progress.appearance_id
	for item_id in KITS.get(class_id, []):
		var item := profile.catalog.item(item_id)
		if item != null:
			progress.equipped_items[item.slot_key()] = item_id
	preview.configure(profile, progress)
	_select_state(state_selector.selected)

func _build_icons() -> void:
	var ids: Array[String] = []
	ids.assign(profile.catalog.equipment.keys())
	ids.sort()
	for item_id in ids:
		var item := profile.catalog.item(item_id)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(108, 94)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.texture = item.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cell.add_child(icon)
		var label := Label.new()
		label.text = item_id
		label.clip_text = true
		label.tooltip_text = item.display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(label)
		icon_grid.add_child(cell)

func _update_diagnostics(class_id: String) -> void:
	var note := "Guerrero: animaciones y equipo direccional extraídos de fuente real." if class_id == "warrior" else "Turnaround real en 4 vistas disponible; animaciones de movimiento siguen siendo provisionales."
	diagnostics_label.text = "%s\nPies: ancla (48, 88) · lienzo 96×96 · nearest-neighbor." % note
