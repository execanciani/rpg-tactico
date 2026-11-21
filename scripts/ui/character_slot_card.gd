class_name CharacterSlotCard
extends PanelContainer

signal empty_pressed
signal selection_toggled(character_id: String)
signal info_requested(character_id: String)
signal delete_requested(character_id: String)

var character_id := ""
var content: VBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(260, 330)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_content()

func _build_content() -> void:
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	add_child(content)

func show_empty(slot_number: int) -> void:
	_clear()
	character_id = ""
	add_theme_stylebox_override("panel", _style(Color("#14243a"), Color("#8e743d")))
	var label := Label.new()
	label.text = "ESPACIO %d\n\n+" % slot_number
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("#eac56d"))
	content.add_child(label)
	var button := Button.new()
	button.text = "CREAR PERSONAJE"
	button.custom_minimum_size = Vector2(0, 58)
	button.pressed.connect(func(): empty_pressed.emit())
	content.add_child(button)

func show_character(progress: CharacterProgress, race: RaceData, profession: ProfessionData, selected: bool) -> void:
	_clear()
	character_id = progress.character_id
	add_theme_stylebox_override("panel", _style(Color("#14243a"), Color("#f0c76a") if selected else Color("#607d96")))
	var portrait := CharacterPortrait.new()
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.configure(progress.race_id, progress.profession_id, selected)
	content.add_child(portrait)
	var label := Label.new()
	label.text = "%s\n%s · %s\nNivel %d" % [progress.display_name, race.display_name, profession.display_name, progress.level]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("#ffe39a"))
	content.add_child(label)
	var select_button := Button.new()
	select_button.text = "SELECCIONADO" if selected else "SELECCIONAR"
	select_button.custom_minimum_size = Vector2(0, 48)
	select_button.pressed.connect(func(): selection_toggled.emit(character_id))
	content.add_child(select_button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	content.add_child(actions)
	var info_button := Button.new()
	info_button.text = "INFO"
	info_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_button.pressed.connect(func(): info_requested.emit(character_id))
	actions.add_child(info_button)
	var delete_button := Button.new()
	delete_button.text = "ELIMINAR"
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button.pressed.connect(func(): delete_requested.emit(character_id))
	actions.add_child(delete_button)

func _clear() -> void:
	for child in content.get_children():
		child.queue_free()

func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	return style
