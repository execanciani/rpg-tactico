class_name ProfessionSelectionPanel
extends VBoxContainer

signal profession_selected(profession_id: String)

func configure(catalog: ProgressionCatalog, race: RaceData, selected_profession_id := "") -> void:
	for child in get_children():
		child.queue_free()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	for profession_id in race.allowed_initial_professions:
		var profession := catalog.profession(profession_id)
		if profession == null:
			continue
		var button := Button.new()
		button.text = "%s\n%s" % [profession.display_name, profession.description]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(360, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = profession_id == selected_profession_id
		button.pressed.connect(func(): profession_selected.emit(profession_id))
		grid.add_child(button)
