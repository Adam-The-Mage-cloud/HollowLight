extends Area2D

var equipped = false

var speed = 5
var max_radius = 12
var return_speed = 8.0

var flip_state := 1.0               # 1 = normal, -1 = flipped
var flip_timer := 0.0             # counts how long we've been in flip zone
var flip_delay := 0.12            # how long before flipping (tweak this)
var flip_threshold := 0.55        # how downward before flip starts
var flip_speed := 12.0            # how fast the flip animation happens

func _physics_process(delta: float) -> void:
	if not equipped:
		return
	var center = %Brody.global_position
	# Direction (mouse or stick)
	var dir = _get_aim_direction(center)
	if dir == Vector2.ZERO:
		return

	# Distance
	var dist = _get_aim_distance(center, max_radius)

	# --- POSITION SMOOTHING ---
	var target_pos = center + dir * dist

	# More smoothing when aiming vertically
	var vertical_factor = abs(dir.y)
	var smooth = lerp(return_speed, return_speed * 0.15, vertical_factor)

	global_position = global_position.lerp(target_pos, delta * smooth)

	# --- ROTATION INERTIA ---
	var target_angle = dir.angle()
	var angle_diff = abs(angle_difference(rotation, target_angle))
	var weight = clamp(1.0 - (angle_diff / PI), 0.2, 1.0)

	var t = (1.0 - pow(0.001, delta * speed)) * weight
	rotation = lerp_angle(rotation, target_angle, t)
	
	# --- NATURAL WRIST FLIP (LEFT/RIGHT) ---
	var left_side = dir.x < -flip_threshold
	# Count time spent in flip zone
	if left_side:
		flip_timer += delta
	else:
		flip_timer = 0.0
	# Trigger flip only after delay
	if left_side and flip_timer > flip_delay:
		flip_state = -1
	elif not left_side:
		flip_state = 1
	# Smooth wrist rotation
	scale.y = lerp(scale.y, flip_state, delta * flip_speed)


func _get_aim_direction(center: Vector2) -> Vector2:
	# Controller stick direction
	var stick := Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

	# If stick is being used, prefer it
	if stick.length() > 0.2:
		return stick.normalized()

	# Otherwise use mouse direction
	var mouse_dir := get_global_mouse_position() - center
	if mouse_dir.length() < 1.0:
		return Vector2.ZERO

	return mouse_dir.normalized()


func _get_aim_distance(center: Vector2, max_r: float) -> float:
	var stick := Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

	# If stick is active, distance = stick magnitude * radius
	if stick.length() > 0.2:
		return clamp(stick.length() * max_r, 0.0, max_r)

	# Mouse distance
	var mouse_dist := (get_global_mouse_position() - center).length()
	return clamp(mouse_dist, 0.0, max_r)



func now_unequipped() :
	equipped = false

func now_equipped() :
	equipped = true
