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
var last_rotation = 0.0
var drain_smooth = 0.0
var recovery_smooth = 0.0
var upgrade_bonus = 0.05

var effort = 0.0                  # Used for Calculating Knockback

var rotation_stamina = 0.66        # Maximum Stamina
var stamina_drain_rate = 0.35     # Stamina Drain rate (when rotated quickly) # max is 0.24
var stamina_recover_rate = 0.55   # Stamina Recovery rate (when not being rotated quickly)
var min_heaviness = 0.08          # How heavy it feels at 0 stamina

# Variables Needed For Flipping The Torch Once Axis Requirements Met :
var flip_state = 1.0             # 1 = normal, -1 = flipped
var flip_timer = 0.0             # Counts how long we've been in the flip zone
var flip_delay = 0.12        # Indicates how long before flipping (tweak this)
var flip_threshold = 0.2        # Indicates how downward before flip starts
var flip_speed = 4.0             # Indicates how fast the flip animation happens

func _ready() :
	EventBus.new_crawl.connect(check_torch_light_radiation_theme)
	EventBus.spawn_sanctuary.connect(lower_torch_light)
	change_skin()
	

func _physics_process(delta: float) -> void:
	area_centre = %Brody.global_position
	direction = _get_aim_direction(area_centre)
	if direction == Vector2.ZERO:
		last_rotation = rotation  # keep rotation stable
		return
	
	target_angle = direction.angle()
	if equipped == false:
		return
	
	direction = _get_aim_direction(area_centre)
	if direction == Vector2.ZERO:
		return
	
	distance = _get_aim_distance(area_centre, max_radius)
	target_position = area_centre + direction * distance
	
	verticality = abs(direction.y)
	vertical_smoothness = lerp(return_speed, return_speed * 0.15, verticality)
	global_position = global_position.lerp(target_position, delta * vertical_smoothness)
	
	# --- Rotation effort ---
	var rotation_delta = abs(angle_difference(rotation, last_rotation))
	var rotation_speed_request = rotation_delta / delta
	rotation_speed_request = clamp(rotation_speed_request, 0.0, 20.0)
	last_rotation = rotation
	effort = clamp(rotation_speed_request / 8.0, 0.0, 1.0)

	# --- Drain ---
	var drain = stamina_drain_rate * effort
	drain_smooth = lerp(drain_smooth, drain, delta * 3.0)

	# --- Recovery ---
	# --- Recovery ---
	var missing = 1.0 - rotation_stamina

	# Upgrade curve: increases minimum recovery speed
	var min_recovery = 0.5 + (EventBus.amount_torch_recovery_upgraded * 0.1)
	min_recovery = clamp(min_recovery, 0.5, 0.9)

	# Recovery factor scales with missing stamina
	var recovery_factor = lerp(min_recovery, 1.0, missing)

	# Final recovery rate
	var recovery = stamina_recover_rate * recovery_factor
	recovery_smooth = lerp(recovery_smooth, recovery, delta * 1.5)

	# --- Apply ---
	if effort > 0.05:
		rotation_stamina -= drain_smooth * delta
	else:
		rotation_stamina += recovery_smooth * delta

	rotation_stamina = clamp(rotation_stamina, 0.0, 1.0)
	
	# -----------------------------
	#   HEAVINESS FEEL
	# -----------------------------
	
	var stamina_factor = lerp(min_heaviness, 1.0, rotation_stamina)
	var speed_factor = clamp(1.0 - (rotation_speed_request / 20.0), 0.2, 1.0)
	heaviness = lerp(0.008, 0.725, stamina_factor * speed_factor * (stamina_factor * 1.25))

	
	# Optional micro‑shake when tired (feels human)
	heaviness += (1.0 - rotation_stamina) * 0.03 * sin(Time.get_ticks_msec() * 0.02) * 0.1
	
	# -----------------------------
	#   ROTATION EASING
	# -----------------------------
	
	rotational_easer = (1.0 - pow(0.001, delta * speed)) * heaviness
	rotation = lerp_angle(rotation, target_angle, rotational_easer)
	
	# -----------------------------
	#   WRIST FLIP LOGIC
	# -----------------------------
	
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
	
	if rotation_stamina > 0.4 and EventBus.sanctuary == false :
		%StaminaBarGreen.value = rotation_stamina * 97.5
		%StaminaBarGreen.visible = true
		%StaminaBarOrange.visible = false
		%StaminaBarRed.visible = false
	elif rotation_stamina > 0.15 and EventBus.sanctuary == false :
		%StaminaBarOrange.value = rotation_stamina * 97.5
		%StaminaBarOrange.visible = true
		%StaminaBarGreen.visible = false
		%StaminaBarRed.visible = false
	elif rotation_stamina <= 0.15 and EventBus.sanctuary == false :
		%StaminaBarRed.value = rotation_stamina * 97.5
		%StaminaBarRed.visible = true
		%StaminaBarGreen.visible = false
		%StaminaBarOrange.visible = false


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


func change_skin() :
	if EventBus.equipped_torch == null :
		EventBus.equipped_torch = "none"
	%TorchSprite.play(str(EventBus.equipped_torch) + "_lit")


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

func check_torch_light_radiation_theme() :
	if EventBus.current_theme == 1 or EventBus.current_theme == 4 : # Then Normal :
		%TorchLight.energy = 10.95
		%TorchLight.texture.width = 96
		%TorchLight.texture.height = 96
	elif EventBus.current_theme == 2 :
		%TorchLight.energy = 12.0
		%TorchLight.texture.width = 128
		%TorchLight.texture.height = 128
	elif EventBus.current_theme == 3 : # Hell so we need to alter it to be darker
		%TorchLight.energy = 2.0
		%TorchLight.texture.width = 96
		%TorchLight.texture.height = 96

func lower_torch_light() :
	%TorchLight.energy = 5.0
	%TorchLight.texture.width = 96
	%TorchLight.texture.height = 96


func _on_upgrade_checker_timeout() -> void:
	stamina_drain_rate = 0.35 * pow(0.88, EventBus.amount_max_stamina_upgraded)
	stamina_recover_rate = 0.55 * pow(1.0 / 0.88, EventBus.amount_torch_recovery_upgraded)
	upgrade_bonus = EventBus.amount_torch_recovery_upgraded * 0.05
