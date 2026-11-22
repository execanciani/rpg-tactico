class_name EquipmentLayerVisual
extends Node2D

const SLOT_ORDER: Array[String] = [
	"cape", "legs", "feet", "torso", "hands", "head", "main_hand", "off_hand",
]

var layer_sprites: Dictionary = {}
var layer_items: Dictionary = {}
var facing := "front"
var body_model_id := ""
var pose_state := "idle"
var pose_frame := 0
var pose_region := Rect2()

func configure(body_model: String, items: Array[EquipmentItemData]) -> void:
	for child in get_children():
		child.free()
	layer_sprites.clear()
	layer_items.clear()
	body_model_id = body_model
	var by_slot := {}
	for item in items:
		if item != null:
			by_slot[item.slot_key()] = item
	for slot_id in SLOT_ORDER:
		var item := by_slot.get(slot_id) as EquipmentItemData
		if item == null:
			continue
		var texture := item.combat_visual_for(body_model, facing)
		if texture == null and (item.combat_pose_atlas == null or item.body_model_id != body_model):
			continue
		var sprite := Sprite2D.new()
		sprite.name = item.item_id
		sprite.texture = texture
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		layer_sprites[slot_id] = sprite
		layer_items[slot_id] = item
	_apply_pose()

func set_facing(direction: String) -> void:
	facing = direction
	_apply_pose()

func sync_sprite(visual: AnimatedSprite2D) -> void:
	if visual.sprite_frames == null or not visual.sprite_frames.has_animation(visual.animation):
		return
	var region := Rect2()
	if visual.frame < visual.sprite_frames.get_frame_count(visual.animation):
		var texture := visual.sprite_frames.get_frame_texture(visual.animation, visual.frame) as AtlasTexture
		if texture != null:
			region = texture.region
	sync_pose(visual.animation, visual.frame, region)

func sync_pose(animation_name: StringName, frame_index: int, region := Rect2()) -> void:
	pose_state = String(animation_name).get_slice("_", 0)
	pose_frame = frame_index
	pose_region = region
	_apply_pose()

func _apply_pose() -> void:
	for slot_id in layer_sprites:
		var sprite := layer_sprites[slot_id] as Sprite2D
		var item := layer_items[slot_id] as EquipmentItemData
		var atlas := item.combat_pose_atlas
		if atlas != null and item.body_model_id == body_model_id and pose_region.has_area() and Rect2(Vector2.ZERO, atlas.get_size()).encloses(pose_region):
			sprite.texture = atlas
			sprite.region_enabled = true
			sprite.region_filter_clip_enabled = true
			sprite.region_rect = pose_region
			sprite.position = Vector2.ZERO
		else:
			sprite.region_enabled = false
			sprite.texture = item.combat_visual_for(body_model_id, facing)
			sprite.position = item.combat_offset(pose_state, facing, pose_frame)
	_apply_layer_order()

func _apply_layer_order() -> void:
	for slot_id in layer_sprites:
		var sprite := layer_sprites[slot_id] as Sprite2D
		var item := layer_items[slot_id] as EquipmentItemData
		var default_order := 1
		match slot_id:
			"cape": default_order = -3
			"off_hand": default_order = -1 if facing in ["back", "left"] else 3
			"main_hand": default_order = -1 if facing == "back" else 2
		sprite.z_index = item.combat_z_index(pose_state, facing, pose_frame, default_order)

