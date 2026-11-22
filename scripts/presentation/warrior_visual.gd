class_name WarriorVisual
extends MageVisual

const BODY_ATLAS := preload("res://assets/characters/warrior/modular/body.png")
const FRAME_SIZE := 96
const FEET_ANCHOR := Vector2(48, 86)
const DIRECTIONS := ["front", "right", "back", "left"]
const CLIPS := {
	"idle": [0, 3, 2.0, true],
	"walk": [3, 6, 13.0, true],
	"attack": [9, 4, 13.0, false],
	"cast": [9, 4, 13.0, false],
	"hurt": [13, 2, 9.0, false],
	"death": [15, 4, 8.0, false],
}
static var shared_frames: SpriteFrames

func _build_sprite_frames() -> SpriteFrames:
	if shared_frames != null:
		return shared_frames
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for column in DIRECTIONS.size():
		for state in CLIPS:
			var clip: Array = CLIPS[state]
			var animation_name := "%s_%s" % [state, DIRECTIONS[column]]
			result.add_animation(animation_name)
			result.set_animation_speed(animation_name, clip[2])
			result.set_animation_loop(animation_name, clip[3])
			for index in int(clip[1]):
				result.add_frame(animation_name, atlas_frame(Rect2(
					column * FRAME_SIZE, (int(clip[0]) + index) * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)))
	shared_frames = result
	return result

static func atlas_frame(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = BODY_ATLAS
	texture.region = region
	texture.filter_clip = true
	return texture

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

