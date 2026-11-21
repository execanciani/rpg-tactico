class_name ClassVisual
extends "res://scripts/presentation/mage_visual.gd"

## Shared visual adapter for the four non-mage starter class families.
## The generated sprites currently use one source viewing angle; front/back
## frames are placeholders until true directional art is drawn.
var archetype := "warrior"

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in ["front", "right", "left", "back"]:
		_add(frames, "idle_%s" % direction, ["idle/%s_00.png" % direction], 1.0, true)
		_add(frames, "walk_%s" % direction, _sequence("walk/%s" % direction, 4), 9.0, true)
		_add(frames, "attack_%s" % direction, _sequence("attack/%s" % direction, 4), 11.0, false)
		_add(frames, "cast_%s" % direction, _sequence("cast/%s" % direction, 4), 9.0, false)
		_add(frames, "hurt_%s" % direction, _sequence("hurt/%s" % direction, 3), 10.0, false)
	_add(frames, "death", _sequence("death/right", 4), 6.0, false)
	return frames

func _add(frames: SpriteFrames, animation_name: String, paths: Array[String], speed: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loops)
	for relative_path in paths:
		var path := "res://assets/sprites/characters/%s/%s" % [archetype, relative_path]
		var texture := load(path) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)
