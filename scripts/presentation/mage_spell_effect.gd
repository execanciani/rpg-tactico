class_name MageSpellEffect
extends AnimatedSprite2D

const ROOT := "res://assets/sprites/characters/mage/effects/"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	z_index = 80

func play_once(paths: Array[String], world_position: Vector2, fps := 10.0, visual_scale := 0.5) -> void:
	position = world_position
	scale = Vector2.ONE * visual_scale
	_configure(paths, fps, false)
	play("effect")
	var duration := maxf(0.08, float(paths.size()) / fps)
	await get_tree().create_timer(duration).timeout
	queue_free()

func travel(paths: Array[String], origin: Vector2, destination: Vector2, duration := 0.28, visual_scale := 0.45) -> void:
	position = origin
	scale = Vector2.ONE * visual_scale
	_configure(paths, maxf(8.0, float(paths.size()) / duration), true)
	play("effect")
	var tween := create_tween()
	tween.tween_property(self, "position", destination, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	queue_free()

func _configure(paths: Array[String], fps: float, loops: bool) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("effect")
	frames.set_animation_speed("effect", fps)
	frames.set_animation_loop("effect", loops)
	for relative_path in paths:
		var texture := load(ROOT + relative_path) as Texture2D
		if texture != null:
			frames.add_frame("effect", texture)
	sprite_frames = frames
