extends Area2D

var equipped = true
var minitorch_now_on = true

var original_position = Vector2.ZERO

# Touchscreen :
var touch_stick = Vector2.ZERO

# All Variables Needed For Solid Torch Movement With Joystick / Mouse :
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
var left_side

# Torch Properties Itself :
var speed = 10.0
var max_radius = 9.0             # Max bounds the torch can leave
var return_speed = 8.0

# Torch Stamina System & Weighty Feel :
var rotation_stamina = 1.00        # Maximum Stamina
var stamina_drain_rate = 0.55      # Stamina Drain rate (when rotated quickly)
var stamina_recover_rate = 8.0    # Stamina Recovery rate (when not being rotated quickly)
var min_heaviness = 0.08          # How heavy it feels at 0 stamina

# Variables Needed For Flipping The Torch Once Axis Requirements Met :
var flip_state = 1.0             # 1 = normal, -1 = flipped
var flip_timer = 0.0             # Counts how long we've been in the flip zone
var flip_delay = 0.12        # Indicates how long before flipping (tweak this)
var flip_threshold = 0.2        # Indicates how downward before flip starts
var flip_speed = 4.0             # Indicates how fast the flip animation happens

func _ready() :
	EventBus.new_crawl.connect(check_torch_theme)

func _physics_process(delta: float) -> void:
	area_centre = %Brody.global_position
	
	if equipped == false :
		return
	# direction towards given mouse or stick indication :
	direction = _get_aim_direction(area_centre)
	if direction == Vector2.ZERO:
		return
		
	# distance from centre :
	distance = _get_aim_distance(area_centre, max_radius)
	
	# Smooths the position of the torch
	target_position = area_centre + direction * distance
	
	# More smoothing when aiming vertically
	verticality = abs(direction.y)
	vertical_smoothness = lerp(return_speed, return_speed * 0.15, verticality)
	global_position = global_position.lerp(target_position, delta * vertical_smoothness)
	
	# Weighty Stamina Fatigue System :
	
	# Target angle from aim direction 
	target_angle = direction.angle()
	
	# How far off we currently are
	angle_difference_to = abs(angle_difference(rotation, target_angle))
	
	# Rotation Stamina :
	# How aggressively the player is trying to rotate the torch
	var rotation_speed_request = angle_difference_to / max(delta, 0.0001)
	
	# Drain stamina when rotating fast :
	if rotation_speed_request > 1.0:
		rotation_stamina -= stamina_drain_rate * delta
	else:
		rotation_stamina += stamina_recover_rate * delta
		
	rotation_stamina = clamp(rotation_stamina, 0.0, 1.0)
	
	# Stamina affects heaviness (lower stamina = heavier)
	var stamina_factor = lerp(min_heaviness, 1.0, rotation_stamina)
	
	# Heaviness Feel Logic :
	# Heaviness based on angle difference
	heaviness = clamp(1.0 - (angle_difference_to / PI), 0.2, 1.0)
	
	# Stamina system and heaviness feel
	heaviness *= stamina_factor
	
	# Easing rotation of the torch :
	rotational_easer = (1.0 - pow(0.001, delta * speed)) * heaviness
	
	# Apply rotation
	rotation = lerp_angle(rotation, target_angle, rotational_easer)
	
	# Wrist Flip (cool epic ninjago skills)
	left_side = direction.x < -flip_threshold
	
	if left_side:
		flip_timer += delta
	else:
		flip_timer = 0.0
		
	if left_side and flip_timer > flip_delay:
		flip_state = -1.0
	elif not left_side:
		flip_state = 1.0
		
	scale.y = lerp(scale.y, flip_state, delta * flip_speed)
	
	# fuck me that was complicated as shite 


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

func minitorch_on() :
	%TorchSprite.visible = false
	%MiniTorch.visible = true
	%MainFlameSecondary.emitting = false
	%MainFlameSecondary.emitting = false
	
func minitorch_off() :
	%MiniTorch.visible = false
	%TorchSprite.visible = true
	%MainFlameSecondary.emitting = true
	%MainFlameSecondary.emitting = true


func _on_touch_screen_layer_stick_changed(vec: Variant) -> void:
	touch_stick = vec

func check_torch_theme() :
	if EventBus.current_theme == 1 or EventBus.current_theme == 4 : # Then Normal :
		%TorchLight.energy = 10.95
		%TorchLight.texture.width = 96
		%TorchLight.texture.height = 96
	elif EventBus.current_theme == 2 :
		%TorchLight.energy = 12.0
		%TorchLight.texture.width = 128
		%TorchLight.texture.height = 128
	elif EventBus.current_theme == 3 : # Hell so we need to alter it to be darker
		print("done")
		%TorchLight.energy = 2.0
		%TorchLight.texture.width = 96
		%TorchLight.texture.height = 96
