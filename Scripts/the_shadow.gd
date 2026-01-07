extends Area2D

var version_number

var target
var brody_position
var direction
var speed = 5

func _ready() :
	# Pick Random Appearance :
	version_number = randi_range(1, 9)
	%ShadowVersion.play("v" + str(version_number))
	# Deviation of how they're titled towards the player :
	%ShadowVersion.rotation_degrees = randf_range(60, 90)

func _physics_process(delta: float) -> void:
	# Look at Brody gradually (acting like a cloud) :
	var desired_angle = (target.global_position - global_position).angle()
	rotation = lerp_angle(rotation, desired_angle, 0.025)
	# Moving : )
	brody_position = target.global_position
	direction = (brody_position - global_position).normalized()
	# Potentially Flip Horizontally :
	if brody_position.x > global_position.x :
		$".".scale.x = -1
	else :
		$".".scale.x = 1
	# Now we have the direction to Brody we can move towards it with :
	if global_position.distance_to(brody_position) > 10 :
		position += delta * speed * direction
