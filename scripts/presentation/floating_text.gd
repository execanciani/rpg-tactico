class_name FloatingText
extends Label

func show_text(value: String, world_position: Vector2, color: Color = Color.WHITE) -> void:
	text = value
	position = world_position - Vector2(42, 52)
	size = Vector2(84, 30)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", Color("#182027"))
	add_theme_constant_override("outline_size", 5)
	z_index = 100
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 34.0, 0.7).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.finished.connect(queue_free)
