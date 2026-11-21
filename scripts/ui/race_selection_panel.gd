class_name RaceSelectionPanel
extends VBoxContainer

signal race_selected(race_id: String)

func configure(catalog: ProgressionCatalog, selected_race_id := "") -> void:
	for child in get_children():
		child.queue_free()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	var race_ids: Array[String] = []
	race_ids.assign(catalog.races.keys())
	race_ids.sort()
	for race_id in race_ids:
		var race := catalog.race(race_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 310)
		button.toggle_mode = true
		button.button_pressed = race_id == selected_race_id
		button.pressed.connect(func(): race_selected.emit(race_id))
		row.add_child(button)
		var card := VBoxContainer.new()
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 8
		card.offset_top = 8
		card.offset_right = -8
		card.offset_bottom = -8
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card)
		var portrait := CharacterPortrait.new()
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait.configure(race_id)
		card.add_child(portrait)
		var label := Label.new()
		label.text = "%s\n%s\n\nSTR %d  DEX %d  CON %d\nINT %d  WIS %d  MEN %d" % [
			race.display_name, race.description,
			race.attribute_value("STR"), race.attribute_value("DEX"), race.attribute_value("CON"),
			race.attribute_value("INT"), race.attribute_value("WIS"), race.attribute_value("MEN"),
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
