class_name CharacterEquipmentPreview
extends Control

signal direction_changed(direction: String)

const DIRECTIONS: Array[String] = ["front", "right", "back", "left"]

var current_direction := "front"
var stage: Node2D
var character_visual: MageVisual
var equipment_visual: EquipmentLayerVisual

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_center_stage)

func configure(profile: CampaignProfile, progress: CharacterProgress) -> void:
	if stage != null:
		stage.free()
	character_visual = null
	equipment_visual = null
	stage = Node2D.new()
	# Elevar todo el escenario evita que las capas negativas de arma/escudo
	# queden detras del PanelContainer; su orden relativo respecto al cuerpo se
	# conserva igual que en combate.
	stage.z_index = 20
	add_child(stage)
	_center_stage()
	character_visual = _create_visual(progress.appearance_id)
	if character_visual == null:
		return
	stage.add_child(character_visual)
	equipment_visual = EquipmentLayerVisual.new()
	stage.add_child(equipment_visual)
	_apply_scale()
	equipment_visual.configure(progress.appearance_id, profile.equipped_resources(progress))
	character_visual.frame_changed.connect(_sync_equipment)
	character_visual.animation_changed.connect(_sync_equipment)
	set_direction(current_direction)

func set_direction(direction: String) -> void:
	if direction not in DIRECTIONS:
		return
	current_direction = direction
	if character_visual != null:
		character_visual.facing = direction
		character_visual.play_idle()
	if equipment_visual != null:
		equipment_visual.set_facing(direction)
		_sync_equipment()
	direction_changed.emit(direction)

func turn(step: int) -> void:
	var index := DIRECTIONS.find(current_direction)
	set_direction(DIRECTIONS[posmod(index + step, DIRECTIONS.size())])

func play_state(state: String) -> bool:
	if character_visual == null or character_visual.sprite_frames == null:
		return false
	var directional := "%s_%s" % [state, current_direction]
	if character_visual.sprite_frames.has_animation(directional) and character_visual.sprite_frames.get_frame_count(directional) > 0:
		character_visual.play(directional)
		return true
	if state == "death" and character_visual.sprite_frames.has_animation("death"):
		character_visual.play("death")
		return true
	return false

func _create_visual(appearance_id: String) -> MageVisual:
	match appearance_id:
		"warrior":
			return WarriorVisual.new()
		"mage":
			return MageVisual.new()
		"archer", "acolyte", "explorer":
			var visual := ClassVisual.new()
			visual.archetype = appearance_id
			return visual
	return null

func _sync_equipment() -> void:
	if character_visual != null and equipment_visual != null:
		equipment_visual.sync_sprite(character_visual)

func _center_stage() -> void:
	if stage != null:
		stage.position = size * 0.5
	_apply_scale()

func _apply_scale() -> void:
	if character_visual == null:
		return
	var factor := clampf(minf(size.x / 120.0, size.y / 110.0), 1.6, 3.2)
	character_visual.scale = Vector2(factor, factor)
	if equipment_visual != null:
		equipment_visual.scale = character_visual.scale
