class_name WarriorVisual
extends MageVisual

const WARRIOR_ANIMATION_ROOT := "res://assets/characters/warrior/animations/"

func _build_sprite_frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for direction in ["front", "right", "back", "left"]:
		_add_warrior(result, "idle_%s" % direction, _warrior_sequence("idle", direction, 3), 2.0, true)
		_add_warrior(result, "walk_%s" % direction, _warrior_sequence("walk", direction, 3), 9.0, true)
		_add_warrior(result, "attack_%s" % direction, _warrior_sequence("attack", direction, 3), 10.0, false)
		# Warrior abilities reuse the reliable attack motion until dedicated skill
		# frames exist in the source sheet.
		_add_warrior(result, "cast_%s" % direction, _warrior_sequence("attack", direction, 3), 10.0, false)
		_add_warrior(result, "hurt_%s" % direction, _warrior_sequence("hurt", direction, 2), 9.0, false)
		_add_warrior(result, "death_%s" % direction, _warrior_sequence("death", direction, 3), 6.0, false)
	return result

func _play_directional_once(prefix: String) -> void:
	var animation_name := "%s_%s" % [prefix, facing]
	if sprite_frames == null or sprite_frames.get_frame_count(animation_name) == 0:
		return
	play(animation_name)
	await animation_finished
	play_idle()

func play_death() -> void:
	var animation_name := "death_%s" % facing
	if sprite_frames == null or sprite_frames.get_frame_count(animation_name) == 0:
		return
	play(animation_name)
	await animation_finished

func _warrior_sequence(state: String, direction: String, count: int) -> Array[String]:
	var paths: Array[String] = []
	for index in count:
		paths.append("%s/%s_%02d.png" % [state, direction, index])
	return paths

func _add_warrior(frames: SpriteFrames, animation_name: String, paths: Array[String], speed: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loops)
	for relative_path in paths:
		var texture := load(WARRIOR_ANIMATION_ROOT + relative_path) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)

