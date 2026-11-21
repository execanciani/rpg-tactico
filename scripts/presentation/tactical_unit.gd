class_name TacticalUnit
extends Node2D

signal movement_finished

const MAGE_VISUAL_SCENE := preload("res://scenes/presentation/mage_visual.tscn")
const CLASS_VISUAL_SCENE := preload("res://scenes/presentation/class_visual.tscn")

var data: UnitData
var is_selected := false
var is_targeted := false
var is_active := false
var mage_visual: MageVisual
var equipment_visual: EquipmentLayerVisual

func setup(unit_data: UnitData, world_position: Vector2) -> void:
	data = unit_data
	position = world_position + Vector2(0, -9)
	z_index = unit_data.grid_position.x + unit_data.grid_position.y + 10
	if _uses_human_mage_visual():
		mage_visual = MAGE_VISUAL_SCENE.instantiate() as MageVisual
	elif unit_data.team == UnitData.Team.HEROES:
		var starter_art := _starter_visual_archetype()
		if not starter_art.is_empty():
			var visual := CLASS_VISUAL_SCENE.instantiate() as ClassVisual
			visual.archetype = starter_art
			mage_visual = visual
	if mage_visual != null:
		mage_visual.position = Vector2(0, -15)
		mage_visual.scale = Vector2(0.75, 0.75)
		add_child(mage_visual)
	if unit_data.team == UnitData.Team.HEROES and mage_visual != null:
		equipment_visual = EquipmentLayerVisual.new()
		equipment_visual.position = mage_visual.position
		equipment_visual.scale = mage_visual.scale
		add_child(equipment_visual)
		refresh_equipment_visual()
	queue_redraw()

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func set_targeted(value: bool) -> void:
	is_targeted = value
	queue_redraw()

func set_active(value: bool) -> void:
	is_active = value
	queue_redraw()

func refresh() -> void:
	refresh_equipment_visual()
	queue_redraw()

func refresh_equipment_visual() -> void:
	if equipment_visual == null or data == null:
		return
	equipment_visual.configure(data.body_model_id, data.equipment_items)
	if mage_visual != null:
		equipment_visual.set_facing(mage_visual.facing)

func animate_path(path: Array[Vector2i], grid: IsometricGrid) -> void:
	if path.is_empty():
		movement_finished.emit()
		return
	var tween := create_tween()
	for cell in path:
		var destination := grid.grid_to_world(cell) + Vector2(0, -9)
		if mage_visual != null:
			tween.tween_callback(_play_walk_toward.bind(destination))
		tween.tween_property(self, "position", destination, 0.11).set_trans(Tween.TRANS_SINE)
		# El estado lógico se actualiza al llegar a cada casilla, no al crear el tween.
		tween.tween_callback(_commit_movement_step.bind(cell, grid))
	tween.finished.connect(func():
		if mage_visual != null:
			mage_visual.play_idle()
		movement_finished.emit()
	)

func play_hit() -> void:
	if mage_visual != null:
		mage_visual.play_hurt()
		return
	var original_modulate := modulate
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("#ff7070"), 0.07)
	tween.tween_property(self, "modulate", original_modulate, 0.13)

func play_attack(target_position: Vector2, magical := false, ability_cast := false) -> void:
	if mage_visual != null:
		mage_visual.set_facing_from_vector(target_position - position)
		if equipment_visual != null:
			equipment_visual.set_facing(mage_visual.facing)
		if ability_cast:
			await mage_visual.play_cast()
		else:
			await mage_visual.play_attack()
		return
	var origin := position
	var direction := origin.direction_to(target_position)
	var tween := create_tween()
	if magical:
		tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.10)
		tween.tween_property(self, "modulate", Color("#8edbff"), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.12)
		tween.tween_property(self, "modulate", Color.WHITE, 0.06)
	else:
		tween.tween_property(self, "position", origin + direction * 10.0, 0.09)
		tween.tween_property(self, "position", origin, 0.13)
	await tween.finished

func play_defeat() -> void:
	if mage_visual != null:
		await mage_visual.play_death()
		visible = false
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(self, "position:y", position.y + 10.0, 0.35)
	await tween.finished
	visible = false

func _commit_movement_step(cell: Vector2i, grid: IsometricGrid) -> void:
	data.grid_position = cell
	data.elevation = grid.get_height(cell)
	_update_depth()

func _update_depth() -> void:
	z_index = data.grid_position.x + data.grid_position.y + 10

func _draw() -> void:
	if data == null:
		return
	var team_color := Color("#4da6ff") if data.team == UnitData.Team.HEROES else Color("#ed5d5d")
	var accent := _class_color()
	_draw_flat_ellipse(Vector2(0, 13), Vector2(20, 8), Color(0.05, 0.08, 0.10, 0.45))
	if is_selected:
		draw_arc(Vector2(0, 11), 22.0, 0, TAU, 32, Color("#ffe784"), 3.0)
	if is_active:
		draw_arc(Vector2(0, 10), 26.0, -PI * 0.85, PI * 0.15, 24, Color("#ffffff"), 4.0)
		var indicator_y := -67.0 if mage_visual != null else -55.0
		draw_colored_polygon(PackedVector2Array([Vector2(-5, indicator_y), Vector2(5, indicator_y), Vector2(0, indicator_y + 8)]), Color("#fff19a"))
	if is_targeted:
		draw_arc(Vector2(0, -12), 23.0, 0, TAU, 32, Color("#ff5b55"), 3.0)
	if mage_visual == null:
		# Representación provisional para clases que todavía no tienen sprites definitivos.
		draw_rect(Rect2(-11, -9, 22, 24), team_color)
		draw_rect(Rect2(-8, -5, 16, 17), accent)
		draw_circle(Vector2(0, -17), 10.0, Color("#e8bd91"))
		draw_rect(Rect2(-10, -25, 20, 7), accent.darkened(0.18))
		draw_rect(Rect2(-12, 13, 9, 8), Color("#263248"))
		draw_rect(Rect2(3, 13, 9, 8), Color("#263248"))
		_draw_class_details(accent)
	var hp_ratio := float(data.hp) / float(data.max_hp)
	var bar_y := -54.0 if mage_visual != null else -36.0
	draw_rect(Rect2(-21, bar_y, 42, 6), Color("#182027"))
	draw_rect(Rect2(-20, bar_y + 1, 40.0 * hp_ratio, 4), Color("#58d26d") if hp_ratio > 0.35 else Color("#f0655b"))
	if data.has_acted:
		var acted_y := -41.0 if mage_visual != null else -23.0
		draw_circle(Vector2(16, acted_y), 6.0, Color("#2c333d"))
		draw_line(Vector2(13, acted_y), Vector2(15, acted_y + 3), Color("#d5dae0"), 2.0)
		draw_line(Vector2(15, acted_y + 3), Vector2(20, acted_y - 3), Color("#d5dae0"), 2.0)
	for index in mini(3, data.active_statuses.size()):
		var entry: Dictionary = data.active_statuses[index]
		var effect := load(str(entry.get("path", ""))) as StatusEffectData
		if effect != null:
			var status_y := -63.0 if mage_visual != null else -45.0
			draw_circle(Vector2(-14 + index * 14, status_y), 5.0, effect.color)
			draw_arc(Vector2(-14 + index * 14, status_y), 5.0, 0, TAU, 12, Color("#17222c"), 1.5)

func _draw_class_details(accent: Color) -> void:
	match data.class_name_text:
		"Guerrero", "Guardia":
			draw_rect(Rect2(13, -9, 5, 25), Color("#d9e0e5"))
			draw_colored_polygon(PackedVector2Array([Vector2(11, -9), Vector2(20, -9), Vector2(15, -18)]), Color("#eef3f6"))
		"Mago", "Chamán":
			draw_line(Vector2(15, 15), Vector2(20, -21), Color("#6b432b"), 4.0)
			draw_circle(Vector2(21, -23), 6.0, Color("#80d8ff"))
		"Arquero", "Explorador":
			draw_arc(Vector2(15, -1), 13.0, -PI * 0.5, PI * 0.5, 12, Color("#d7a65d"), 3.0)
			draw_line(Vector2(15, -14), Vector2(15, 12), Color("#e8dfbd"), 1.0)

func _class_color() -> Color:
	match data.class_name_text:
		"Guerrero", "Guardia": return Color("#607d9b")
		"Mago", "Chamán": return Color("#7759a8")
		"Arquero", "Explorador": return Color("#507c55")
		_: return Color("#777777")

func _draw_flat_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _play_walk_toward(destination: Vector2) -> void:
	mage_visual.set_facing_from_vector(destination - position)
	if equipment_visual != null:
		equipment_visual.set_facing(mage_visual.facing)
	mage_visual.play_walk()

func _uses_human_mage_visual() -> bool:
	if data == null or data.team != UnitData.Team.HEROES or data.race_id != "human":
		return false
	return data.profession_id in ["mage", "elementalist", "summoner", "frost_sorcerer", "flame_sorcerer", "spirit_master"]


func _starter_visual_archetype() -> String:
	# Advanced professions reuse their initial class family artwork until
	# differentiated advancement sprites are authored.
	match data.profession_id:
		"warrior", "swordsman", "guardian", "blade_master", "iron_protector":
			return "warrior"
		"archer", "marksman", "hunter", "imperial_archer":
			return "archer"
		"acolyte", "healer", "oracle", "light_priest":
			return "acolyte"
		"explorer", "assassin", "stalker", "lethal_shadow":
			return "explorer"
		"mage", "elementalist", "summoner", "frost_sorcerer", "flame_sorcerer", "spirit_master":
			return ""
	return ""
