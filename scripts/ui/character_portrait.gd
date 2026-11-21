class_name CharacterPortrait
extends Control

var race_id := "human"
var profession_id := "warrior"
var highlighted := false
var portrait_texture: Texture2D

func _ready() -> void:
	custom_minimum_size = Vector2(112, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func configure(new_race_id: String, new_profession_id := "", is_highlighted := false) -> void:
	race_id = new_race_id
	profession_id = new_profession_id
	highlighted = is_highlighted
	portrait_texture = null
	var class_path := "res://assets/portraits/classes/%s.png" % profession_id
	var race_path := "res://assets/portraits/races/%s.png" % race_id
	if not profession_id.is_empty() and ResourceLoader.exists(class_path):
		portrait_texture = load(class_path) as Texture2D
	elif ResourceLoader.exists(race_path):
		portrait_texture = load(race_path) as Texture2D
	queue_redraw()

func _draw() -> void:
	var size_value := minf(size.x, size.y)
	var origin := Vector2((size.x - size_value) * 0.5, (size.y - size_value) * 0.5)
	var frame := Rect2(origin, Vector2(size_value, size_value))
	draw_rect(frame, Color("#111c2b"), true)
	draw_rect(frame, Color("#f0c76a") if highlighted else Color("#6689a3"), false, 4.0)
	if portrait_texture != null:
		draw_texture_rect(portrait_texture, frame.grow(-6.0), false)
		return
	var palette := _race_palette()
	var scale := size_value / 16.0
	_draw_pixel_rect(origin, scale, Rect2i(5, 3, 6, 6), palette.skin)
	_draw_pixel_rect(origin, scale, Rect2i(4, 2, 8, 3), palette.hair)
	_draw_pixel_rect(origin, scale, Rect2i(3, 9, 10, 6), palette.cloth)
	_draw_pixel_rect(origin, scale, Rect2i(6, 6, 1, 1), Color("#17202a"))
	_draw_pixel_rect(origin, scale, Rect2i(9, 6, 1, 1), Color("#17202a"))
	if profession_id in ["mage", "acolyte", "elementalist", "summoner", "healer", "oracle"]:
		_draw_pixel_rect(origin, scale, Rect2i(2, 10, 2, 5), Color("#916fd1"))
	elif profession_id in ["archer", "explorer", "marksman", "hunter", "assassin", "stalker"]:
		_draw_pixel_rect(origin, scale, Rect2i(12, 8, 1, 7), Color("#d6aa5d"))
	else:
		_draw_pixel_rect(origin, scale, Rect2i(12, 9, 2, 5), Color("#aeb9c6"))

func _draw_pixel_rect(origin: Vector2, scale: float, rect: Rect2i, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(rect.position) * scale, Vector2(rect.size) * scale), color, true)

func _race_palette() -> Dictionary:
	match race_id:
		"elf":
			return {"skin": Color("#f4d7b2"), "hair": Color("#d9e9b5"), "cloth": Color("#4f92a8")}
		"dark_elf":
			return {"skin": Color("#8175a8"), "hair": Color("#d8d6e8"), "cloth": Color("#493e78")}
		"orc":
			return {"skin": Color("#78934f"), "hair": Color("#312c24"), "cloth": Color("#854c3e")}
		"dwarf":
			return {"skin": Color("#d7a978"), "hair": Color("#8e5b38"), "cloth": Color("#596b80")}
		_:
			return {"skin": Color("#e1b28a"), "hair": Color("#684936"), "cloth": Color("#3e6c91")}
