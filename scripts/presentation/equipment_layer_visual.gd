class_name EquipmentLayerVisual
extends Node2D

const SLOT_ORDER: Array[String] = [
	"cape", "legs", "feet", "torso", "hands", "head", "main_hand", "off_hand",
]

var layer_sprites: Dictionary = {}
var facing := "front"

func configure(body_model: String, items: Array[EquipmentItemData]) -> void:
	for child in get_children():
		child.free()
	layer_sprites.clear()
	var by_slot := {}
	for item in items:
		if item != null:
			by_slot[item.slot_key()] = item
	for slot_id in SLOT_ORDER:
		var item := by_slot.get(slot_id) as EquipmentItemData
		if item == null:
			continue
		var texture := item.visual_for(body_model, true)
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = item.item_id
		sprite.texture = texture
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		layer_sprites[slot_id] = sprite
	_apply_layer_order()

func set_facing(direction: String) -> void:
	facing = direction
	_apply_layer_order()

func _apply_layer_order() -> void:
	for slot_id in layer_sprites:
		var sprite := layer_sprites[slot_id] as Sprite2D
		match slot_id:
			"cape": sprite.z_index = -3
			"off_hand": sprite.z_index = -1 if facing in ["back", "left"] else 3
			"main_hand": sprite.z_index = -1 if facing == "back" else 2
			_: sprite.z_index = 1

