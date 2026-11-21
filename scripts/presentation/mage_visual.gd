class_name MageVisual
extends AnimatedSprite2D

const ROOT := "res://assets/sprites/characters/mage/"

var facing := "front"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	sprite_frames = _build_sprite_frames()
	play_idle()

func set_facing_from_vector(direction: Vector2) -> void:
	if direction.length_squared() < 0.001:
		return
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x > 0.0 else "left"
	else:
		facing = "front" if direction.y > 0.0 else "back"

func play_idle() -> void:
	play("idle_%s" % facing)

func play_walk() -> void:
	play("walk_%s" % facing)

func play_attack() -> void:
	await _play_directional_once("attack")

func play_cast() -> void:
	await _play_directional_once("cast")

func play_hurt() -> void:
	await _play_directional_once("hurt")

func play_death() -> void:
	if sprite_frames == null or sprite_frames.get_frame_count("death") == 0:
		return
	play("death")
	await animation_finished

func _play_directional_once(prefix: String) -> void:
	var side := facing
	if side not in ["left", "right"]:
		side = "right"
	var animation_name := "%s_%s" % [prefix, side]
	if sprite_frames == null or sprite_frames.get_frame_count(animation_name) == 0:
		return
	play(animation_name)
	await animation_finished
	play_idle()

func _build_sprite_frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	result.remove_animation("default")
	_add(result, "idle_front", ["idle/front_00.png"], 1.0, true)
	_add(result, "idle_right", ["idle/right_00.png"], 1.0, true)
	_add(result, "idle_back", ["idle/back_00.png"], 1.0, true)
	_add(result, "idle_left", ["idle/left_00.png"], 1.0, true)
	_add(result, "walk_front", ["walk/front_00.png"], 1.0, true)
	_add(result, "walk_back", ["walk/back_00.png"], 1.0, true)
	_add(result, "walk_right", _sequence("walk/right", 4), 9.0, true)
	_add(result, "walk_left", _sequence("walk/left", 4), 9.0, true)
	_add(result, "attack_right", _sequence("attack/right", 4), 11.0, false)
	_add(result, "attack_left", _sequence("attack/left", 4), 11.0, false)
	_add(result, "cast_right", _sequence("cast/right", 4), 9.0, false)
	_add(result, "cast_left", _sequence("cast/left", 4), 9.0, false)
	_add(result, "hurt_right", _sequence("hurt/right", 3), 10.0, false)
	_add(result, "hurt_left", _sequence("hurt/left", 3), 10.0, false)
	_add(result, "death", _sequence("death/right", 4), 6.0, false)
	return result

func _add(frames: SpriteFrames, animation_name: String, paths: Array[String], speed: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loops)
	for relative_path in paths:
		var texture := load(ROOT + relative_path) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)

func _sequence(prefix: String, count: int) -> Array[String]:
	var paths: Array[String] = []
	for index in count:
		paths.append("%s_%02d.png" % [prefix, index])
	return paths
