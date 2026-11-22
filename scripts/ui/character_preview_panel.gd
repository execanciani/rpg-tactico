class_name CharacterPreviewPanel
extends HBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
	var starter_family := _starter_family(profession_id)
	var preview_path := "res://assets/sprites/characters/%s/idle/fase5_front_00.png" % starter_family
	if starter_family == "warrior" or (not starter_family.is_empty() and ResourceLoader.exists(preview_path)):
		var sprite_preview := TextureRect.new()
		sprite_preview.custom_minimum_size = Vector2(150, 200)
		sprite_preview.texture = WarriorVisual.atlas_frame(Rect2(0, 0, 96, 96)) if starter_family == "warrior" else load(preview_path) as Texture2D
		sprite_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite_preview.tooltip_text = "Turnaround base de %s · frente" % profession.display_name
		add_child(sprite_preview)
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

func _starter_family(profession_id: String) -> String:
	if profession_id in ["warrior", "swordsman", "guardian", "blade_master", "iron_protector"]:
		return "warrior"
	if profession_id in ["mage", "elementalist", "summoner", "frost_sorcerer", "flame_sorcerer", "spirit_master"]:
		return "mage"
	if profession_id in ["archer", "marksman", "hunter", "imperial_archer"]:
		return "archer"
	if profession_id in ["acolyte", "healer", "oracle", "light_priest"]:
		return "acolyte"
	if profession_id in ["explorer", "assassin", "stalker", "lethal_shadow"]:
		return "explorer"
	return ""
