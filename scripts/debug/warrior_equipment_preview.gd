extends Control

const ITEMS := {
	"iron_helmet": "Casco", "iron_armor": "Armadura", "iron_boots": "Botas",
	"iron_sword": "Espada", "iron_shield": "Escudo",
}
const DIRECTIONS := {"front": "Frente", "right": "Derecha", "back": "Espalda", "left": "Izquierda"}
const STATES := {"idle": "Reposo", "walk": "Caminar", "attack": "Ataque",
	"cast": "Habilidad", "hurt": "Daño", "death": "Derrota"}
const ANCHOR_COLORS := {"head": Color.YELLOW, "torso": Color.LIME_GREEN,
	"main_hand": Color.ORANGE, "off_hand": Color.CYAN,
	"foot_a": Color.HOT_PINK, "foot_b": Color.HOT_PINK}

var profile := CampaignProfile.new()
var progress: CharacterProgress
var bare: CharacterEquipmentPreview
var equipped: CharacterEquipmentPreview
var markers: Node2D
var anchors: Dictionary = {}
var anchor_toggle: CheckButton
var direction := "front"
var state := "idle"

func _ready() -> void:
	profile.initialize_new()
	var reference := profile.create_character("reference", "Referencia", "human", "warrior")
	progress = profile.create_character("comparison", "Comparación", "human", "warrior")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/characters/warrior/modular/anchors.json"))
	if parsed is Dictionary:
		anchors = parsed

	var background := ColorRect.new()
	background.color = Color("#172439")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Guerrero · inspección de equipamiento"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	var facing_selector := OptionButton.new()
	for value: String in DIRECTIONS:
		facing_selector.add_item(DIRECTIONS[value])
	facing_selector.item_selected.connect(func(index: int):
		direction = DIRECTIONS.keys()[index]
		_play()
	)
	controls.add_child(facing_selector)
	var state_selector := OptionButton.new()
	for value: String in STATES:
		state_selector.add_item(STATES[value])
	state_selector.item_selected.connect(func(index: int):
		state = STATES.keys()[index]
		_play()
	)
	controls.add_child(state_selector)
	var replay := Button.new()
	replay.text = "Reproducir"
	replay.pressed.connect(_play)
	controls.add_child(replay)
	anchor_toggle = CheckButton.new()
	anchor_toggle.text = "Anclajes"
	anchor_toggle.toggled.connect(func(enabled: bool): markers.visible = enabled)
	controls.add_child(anchor_toggle)
	var gear := HBoxContainer.new()
	column.add_child(gear)
	for item_id: String in ITEMS:
		profile.add_item(progress.character_id, item_id)
		var toggle := CheckButton.new()
		toggle.text = ITEMS[item_id]
		toggle.toggled.connect(_toggle_item.bind(item_id))
		gear.add_child(toggle)
	var panes := HBoxContainer.new()
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panes)
	bare = _add_preview(panes, "Sin equipo", reference)
	equipped = _add_preview(panes, "Combinación actual", progress)
	markers = Node2D.new()
	markers.z_index = 9
	markers.hide()
	equipped.character_visual.add_child(markers)
	markers.draw.connect(_draw_anchors)
	equipped.character_visual.frame_changed.connect(markers.queue_redraw)
	equipped.character_visual.animation_changed.connect(markers.queue_redraw)

func _add_preview(parent: HBoxContainer, caption: String, character: CharacterProgress) -> CharacterEquipmentPreview:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	var preview := CharacterEquipmentPreview.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(preview)
	preview.configure(profile, character)
	return preview

func _toggle_item(enabled: bool, item_id: String) -> void:
	if enabled:
		profile.equip_item(progress.character_id, item_id)
	else:
		profile.unequip_item(progress.character_id, profile.catalog.item(item_id).slot_key())
	equipped.equipment_visual.configure("warrior", profile.equipped_resources(progress))
	equipped.equipment_visual.sync_sprite(equipped.character_visual)

func _play() -> void:
	for preview in [bare, equipped]:
		preview.character_visual.stop()
		preview.set_direction(direction)
		preview.play_state(state)

func _draw_anchors() -> void:
	var visual := equipped.character_visual
	var clip := String(visual.animation).replace("cast_", "attack_")
	var points: Dictionary = anchors.get("%s:%d" % [clip, visual.frame], {})
	var center := Vector2.ONE * WarriorVisual.FRAME_SIZE / 2.0
	markers.draw_circle(WarriorVisual.FEET_ANCHOR - center, 2.0, Color.WHITE, false)
	for name: String in points:
		var coordinate: Array = points[name]
		var point := Vector2(coordinate[0], coordinate[1]) - center
		markers.draw_circle(point, 2.0, ANCHOR_COLORS[name], false)
