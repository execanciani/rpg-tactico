class_name CharacterPreviewPanel
extends HBoxContainer

func configure(catalog: ProgressionCatalog, race_id: String, profession_id: String, character_name := "") -> void:
	for child in get_children():
		child.queue_free()
	var race := catalog.race(race_id)
	var profession := catalog.profession(profession_id)
	if race == null or profession == null:
		return
	add_theme_constant_override("separation", 20)
	var portrait := CharacterPortrait.new()
	portrait.custom_minimum_size = Vector2(180, 180)
	portrait.configure(race_id, profession_id, true)
	add_child(portrait)
	var temporary := CharacterProgress.new()
	temporary.setup("preview", character_name if not character_name.is_empty() else "Aventurero", race, profession_id)
	var stats := StatCalculator.calculate(temporary, race, profession)
	var attributes: Dictionary = stats.attributes
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.text = "%s%s\n%s · %s\n\nSTR %d   DEX %d   CON %d\nINT %d   WIS %d   MEN %d\n\n%s" % [
		character_name, "\n" if not character_name.is_empty() else "",
		race.display_name, profession.display_name,
		int(attributes.STR), int(attributes.DEX), int(attributes.CON),
		int(attributes.INT), int(attributes.WIS), int(attributes.MEN), profession.description,
	]
	add_child(label)
