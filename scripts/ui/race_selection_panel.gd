class_name RaceSelectionPanel
extends VBoxContainer

signal race_selected(race_id: String)

var race_cards: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 380)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func configure(catalog: ProgressionCatalog, selected_race_id := "") -> void:
	for child in get_children():
		child.queue_free()
	race_cards.clear()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	var race_ids: Array[String] = []
	race_ids.assign(catalog.races.keys())
	race_ids.sort()
	for race_id in race_ids:
		var race := catalog.race(race_id)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(210, 350)
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", _card_style(race_id == selected_race_id))
		race_cards[race_id] = panel
		row.add_child(panel)
		var card := VBoxContainer.new()
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_theme_constant_override("separation", 6)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(card)
		var portrait := CharacterPortrait.new()
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait.configure(race_id, "", race_id == selected_race_id)
		card.add_child(portrait)
		var label := Label.new()
		label.text = "%s\n%s\n\nSTR %d  DEX %d  CON %d\nINT %d  WIS %d  MEN %d" % [
			race.display_name, race.description,
			race.attribute_value("STR"), race.attribute_value("DEX"), race.attribute_value("CON"),
			race.attribute_value("INT"), race.attribute_value("WIS"), race.attribute_value("MEN"),
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
		var button := Button.new()
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.flat = true
		button.focus_mode = Control.FOCUS_ALL
		button.tooltip_text = "Seleccionar %s" % race.display_name
		button.pressed.connect(_select_race.bind(race_id))
		panel.add_child(button)

func _select_race(race_id: String) -> void:
	for card_id in race_cards:
		var panel := race_cards[card_id] as PanelContainer
		panel.add_theme_stylebox_override("panel", _card_style(str(card_id) == race_id))
	race_selected.emit(race_id)

func _card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111b2a")
	style.border_color = Color("#f0c04f") if selected else Color("#526f89")
	style.set_border_width_all(5 if selected else 3)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(9)
	return style
