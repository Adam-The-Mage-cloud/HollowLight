extends Control

signal stick_changed(vec)

var radius := 30.0
var center := Vector2.ZERO
var output := Vector2.ZERO

func _ready():
	center = size / 2
	%TorchJoystickSprite.position = center
	# Make sure this Control actually receives touch events
	mouse_filter = MOUSE_FILTER_PASS

func _gui_input(event):
	if event is InputEventScreenTouch and event.pressed:
		_update_stick(event.position)

	elif event is InputEventScreenDrag:
		_update_stick(event.position)

	# IMPORTANT: do NOT reset on release
	# Right joystick stays where it was

func _update_stick(local: Vector2):
	var offset := local - center
	var clamped := offset.limit_length(radius)

	%TorchJoystickSprite.position = center + clamped

	if clamped.length() >= 6.0:
		output = clamped / radius

	emit_signal("stick_changed", output)
