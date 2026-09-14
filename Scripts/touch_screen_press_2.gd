extends Control

signal move_stick_changed(vec)

var radius = 30.0
var output = Vector2.ZERO
var center = Vector2.ZERO

var active_finger := -1


func _ready():
	center = %BrodyJoystickBase.position
	%BrodyJoystickSprite.position = center

func _gui_input(event):
	if event is InputEventScreenDrag:
		_update_stick(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_update_stick(event.position)
		else:
			_reset_stick()

func _update_stick(pos: Vector2):
	var local = pos - global_position
	var offset = local - center
	var clamped = offset.limit_length(radius)
	%BrodyJoystickSprite.position = center + clamped
	# Deadzone to prevent jitter
	if clamped.length() < 6.0:
		output = Vector2.ZERO
	else:
		output = clamped / radius
	emit_signal("move_stick_changed", output)

func _reset_stick():
	%BrodyJoystickSprite.position = center
	output = Vector2.ZERO
	emit_signal("move_stick_changed", output)
