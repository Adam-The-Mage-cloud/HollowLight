extends Camera2D

var smooth_pos = Vector2.ZERO
var follow_speed = 12.0

func _ready():
	smooth_pos = global_position

func _physics_process(delta):
	var brody = %Brody
	var target = brody.global_position

	# Smooth follow
	smooth_pos = smooth_pos.lerp(target, delta * follow_speed)

	global_position = smooth_pos
