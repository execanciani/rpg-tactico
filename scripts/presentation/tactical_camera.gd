class_name TacticalCamera
extends Camera2D

@export var keyboard_speed := 360.0
@export var minimum_zoom := 0.72
@export var maximum_zoom := 1.45

var mouse_dragging := false
var touch_points: Dictionary = {}
var previous_pinch_distance := 0.0
var previous_touch_center := Vector2.ZERO

func _ready() -> void:
	reset_view()

func reset_view() -> void:
	position = Vector2(0, 150)
	zoom = Vector2.ONE

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		position += direction * keyboard_speed * delta / zoom.x
		_clamp_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			mouse_dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(1.1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(0.9)
	elif event is InputEventMouseMotion and mouse_dragging:
		position -= event.relative / zoom.x
		_clamp_position()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
		_reset_touch_reference()
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() >= 2:
			var points := touch_points.values()
			var center: Vector2 = (points[0] + points[1]) * 0.5
			var distance: float = points[0].distance_to(points[1])
			if previous_pinch_distance > 0.0:
				position -= (center - previous_touch_center) / zoom.x
				_apply_zoom(distance / previous_pinch_distance)
			previous_touch_center = center
			previous_pinch_distance = distance
			_clamp_position()

func _apply_zoom(factor: float) -> void:
	var value := clampf(zoom.x * factor, minimum_zoom, maximum_zoom)
	zoom = Vector2(value, value)

func _reset_touch_reference() -> void:
	previous_pinch_distance = 0.0
	if touch_points.size() >= 2:
		var points := touch_points.values()
		previous_touch_center = (points[0] + points[1]) * 0.5
		previous_pinch_distance = points[0].distance_to(points[1])

func _clamp_position() -> void:
	position.x = clampf(position.x, -500.0, 500.0)
	position.y = clampf(position.y, -80.0, 430.0)
