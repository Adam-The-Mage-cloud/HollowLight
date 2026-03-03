extends Area2D

# Flip thresholds (hysteresis)
const FLIP_LEFT_THRESHOLD  = -0.25
const FLIP_RIGHT_THRESHOLD = 0.25
const FLIP_DOWN_THRESHOLD  = 0.45
const FLIP_UP_THRESHOLD    = -0.45

var shield_skin

var equipped = false
var unequipped = true

var original_position = Vector2.ZERO

# Touchscreen:
var touch_stick = Vector2.ZERO

# Shield movement variables
var area_centre
var target_position
var direction
var distance
var verticality
var vertical_smoothness
var target_angle
var angle_difference_to
var heaviness
var rotational_easer

# Angular inertia
var angular_velocity = 0.0

var shield_stamina_bonus = 1.0
var shield_speed_bonus = 1.0

# Shield properties
var speed = 9.0
var max_radius = 14.0
var return_speed = 8.0

# Stamina system
var rotation_stamina = 0.4
var stamina_drain_rate = 0.55
var stamina_recover_rate = 2.0
var min_heaviness = 0.6

# Flip states
var facing_left = false
var facing_down = false

func _ready():
	check_shield()
	unequip()

func check_shield() :
	shield_skin = EventBus.shield_acquired
	if EventBus.shield_acquired == "none" :
		visible = false
	else :
		visible = true
		

func _physics_process(delta: float) -> void:
	if not equipped:
		if not unequipped:
			unequip()
		return
	
	%Brody.shield_slowdown_speed = 0.8
	area_centre = %Brody.global_position

	# Direction from input
	direction = _get_aim_direction(area_centre)
	if direction == Vector2.ZERO:
		return

	# Distance from Brody
	distance = _get_aim_distance(area_centre, max_radius)

	# Smooth positional movement
	target_position = area_centre + direction * distance
	verticality = abs(direction.y)
	vertical_smoothness = lerp(return_speed, return_speed * 0.15, verticality)
	global_position = global_position.lerp(target_position, delta * vertical_smoothness)

	# -------------------------
	#   SHIELD ROTATION LOGIC
	# -------------------------

	# Target angle
	target_angle = direction.angle()

	# Angular dead-zone (shields shouldn't micro-adjust)
	var deadzone = 0.15
	if abs(angle_difference(rotation, target_angle)) < deadzone:
		target_angle = rotation

	# Limit shield rotation arc (shields don't rotate behind the body)
	var max_arc = deg_to_rad(110)
	var wrapped = wrapf(target_angle, -PI, PI)
	target_angle = clamp(wrapped, -max_arc, max_arc)

	# Forward bias (shields naturally want to face forward)
	var forward_bias = 0.1
	target_angle = lerp_angle(target_angle, 0.0, forward_bias * delta)

	# Angle difference
	angle_difference_to = abs(angle_difference(rotation, target_angle))

	# Stamina drain / recovery
	var rotation_speed_request = angle_difference_to / max(delta, 0.0001)
	if rotation_speed_request > 1.0:
		rotation_stamina -= stamina_drain_rate * delta
	else:
		rotation_stamina += stamina_recover_rate * delta

	rotation_stamina = clamp(rotation_stamina, 0.0, 1.0)

	# Stamina affects heaviness
	var stamina_factor = lerp(min_heaviness, 1.0, rotation_stamina)

	# Heaviness based on angle difference
	heaviness = clamp(1.0 - (angle_difference_to / PI), 0.2, 1.0)
	heaviness *= stamina_factor

	# -------------------------
	#   ANGULAR INERTIA
	# -------------------------

	var angle_diff = angle_difference(rotation, target_angle)

	# Apply torque proportional to angle difference
	angular_velocity += angle_diff * heaviness * delta * speed

	# Angular damping (friction)
	angular_velocity *= 0.85

	# Apply rotation
	rotation += angular_velocity
	

	# -------------------------
	#   FLIP LOGIC
	# -------------------------
	# Clamp so it never flips
	var max_tilt = deg_to_rad(80)
	rotation = clamp(rotation, -max_tilt, max_tilt)

	# -------------------------
	#   VISUAL SECONDARY MOTION
	# -------------------------

	# Tilt based on angular velocity
	var tilt_amount = clamp(angular_velocity * 0.4, -0.4, 0.4)
	var settle_speed = 10.0
	$".".rotation = lerp($".".rotation, tilt_amount, delta * settle_speed)

	# Directional tilt for extra life
	var move_dir = (global_position - target_position).normalized()
	$".".rotation -= move_dir.x * 0.125

	# Squash/stretch
	var stretch = 1.0 + abs(angular_velocity) * 0.05
	$".".scale.y = lerp($".".scale.y, stretch, delta * 8.0)
	$".".scale.x = lerp($".".scale.x, 1.0 / stretch, delta * 8.0)



func _get_aim_direction(centre: Vector2) -> Vector2:
	# Touch joystick first
	if touch_stick.length() > 0.1:
		return touch_stick.normalized()
	
	# Controller stick
	var stick = Vector2(
	Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
	Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)
	if stick.length() > 0.2:
		return stick.normalized()
	
	# Mouse fallback
	var mouse_dir = get_global_mouse_position() - centre
	if mouse_dir.length() < 1.0:
		return Vector2.ZERO
	
	return mouse_dir.normalized()


func _get_aim_distance(centre: Vector2, max_r: float) -> float:
	var stick = Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

	# If stick is active, distance = stick magnitude * radius
	if stick.length() > 0.2:
		return clamp(stick.length() * max_r, 0.0, max_r)

	# Mouse distance
	var mouse_dist = (get_global_mouse_position() - centre).length()
	return clamp(mouse_dist, 0.0, max_r)

func shield_collision() :
	%ShieldSprite.play(str(shield_skin) + "_shield")
	%ShieldCollision.disabled = false

func unequip() :
	%Brody.shield_slowdown_speed = 1.0
	unequipped = true
	%ShieldCollision.disabled = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Anticipation move
	tween.tween_property(self, "position", Vector2(4, -2), 0.08)
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 0.9), 0.08) # squash/stretch
	
	# Flick Towards back
	tween.tween_property(self, "position", Vector2(-2, 5), 0.12)
	tween.parallel().tween_property(self, "rotation_degrees", -60, 0.12)
	tween.parallel().tween_property(self, "scale", Vector2(0.9, 1.1), 0.12) # stretch on swing
	
	# Adjust shield as needed
	tween.tween_property(self, "position", Vector2(0, 3), 0.10)
	tween.parallel().tween_property(self, "rotation_degrees", randf_range(-15, 15), 0.10)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	
	# Switch to animation
	tween.finished.connect(func():
		%ShieldSprite.play(str(shield_skin) + "_holstered")
	)


func get_lost() -> void:
	original_position = position

	# Random direction away from Brody
	var angle = randf_range(0.0, TAU)
	var direction = Vector2(cos(angle), sin(angle)).normalized()

	# How far the torch flies
	var distance = randf_range(40.0, 80.0)

	# Final landing spot
	var target_position = original_position + direction * distance

	# Random spin
	var spin_amount = randf_range(180.0, 540.0)

	# Create tween
	var tween = create_tween()

	# Fling outward (fast)
	tween.tween_property(self, "position", target_position, 0.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# Add rotation while flying
	tween.parallel().tween_property(self, "rotation_degrees", rotation_degrees + spin_amount, 0.25)

	# Small bounce / settle on the floor
	tween.tween_property(self, "position:y", target_position.y + 6.0, 0.15)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)


func now_unequipped() :
	equipped = false

func now_equipped() :
	equipped = true


func _on_touch_screen_press_1_stick_changed(vec: Variant) -> void:
	touch_stick = vec


func _on_event_bus_checker_timeout() -> void:
	shield_stamina_bonus = EventBus.amount_shield_stamina_upgraded
	shield_speed_bonus = EventBus.amount_shield_speed_upgraded
	
	# Stamina Upgrade :
	var stamina_scale = 1.0 + (shield_stamina_bonus * 0.12)
	stamina_drain_rate = 0.55 / stamina_scale
	stamina_recover_rate = 2.0 * stamina_scale
	
	# Speed Upgrade :
	var speed_scale = 1.0 + (shield_speed_bonus * 0.10)
	speed = 9.0 * speed_scale
	return_speed = 8.0 * speed_scale
