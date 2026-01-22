extends CharacterBody2D

var squashed = false

# Touchscreen :
var touch_move = Vector2.ZERO
var input_enabled = true

var direction = Vector2.ZERO
var speed = 4000
var max_speed = 75.0

var weapon_equipped = false
var torch_equipped = true

var bobbing = false

var dash_available = true
var dashing = false

func _ready() :
	breathing()

func _physics_process(delta: float) -> void:
	if input_enabled == true :
		# Change Tool :
		if Input.is_action_just_pressed("tool_switch") :
			initialise_swap_tool() 
		# Check for Dash :
		if Input.is_action_pressed("dash") :
			dash_ability()
		# Check For Input :
		direction = get_move_direction()
		
		if direction != Vector2.ZERO:
			if dashing == false:
				moving()
				%BrodySprite.play("moving")
		else :
			%BrodySprite.play("stationary")
			%feet.play("stationary")
		
		# Antenna Movement :
		if direction != Vector2.ZERO and %antenna.rotation_degrees > -25 :
			%antenna.rotation_degrees -= 225 * delta
		elif direction == Vector2.ZERO and %antenna.rotation_degrees <= 0 :
			%antenna.rotation_degrees += 225 * delta # until at degrees = 0
		
		# Movement :
		direction = direction.normalized()
		velocity = (direction * speed) * delta
		move_and_slide()

# Movement :
func get_move_direction() -> Vector2:
	if input_enabled == true :
		# Touch joystick first
		if touch_move.length() > 0.1:
			return touch_move.normalized()
		
		# Keyboard fallback
		var dir := Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		)
		
		return dir.normalized()
	else :
		return Vector2.ZERO


func dash_ability():
	if input_enabled == true :
		if dash_available == true:
			#flash_white()
			# Can dodge through furniture :
			var original_mask = collision_mask
			collision_mask = 1   # disable bit 2
			var target_angle = velocity.angle() * 180 / PI
		
			# --- Lean Into Direction (anticipation) ---
			var lean = create_tween()
			lean.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			lean.tween_property(%BrodySprite, "rotation_degrees", target_angle - 20, 0.08)
		
			# --- Roll Spin ---
			var roll_tween = create_tween()
			roll_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
			var current = %BrodySprite.rotation_degrees
			var spins = 1  # number of full rotations
		
			# Compute the next clean landing angle (smooth, no snapping)
			var target = (floor(current / 360.0) + spins) * 0 # CHANGE THIS 0 TO 360 ONCE THE ROLL ANIMATION IS ADDED IN 
		
			# Add a tiny overshoot for natural motion
			var overshoot = target + 18
		
			# Spin with overshoot
			roll_tween.tween_property(%BrodySprite, "rotation_degrees", overshoot, 0.22)
		
			# Ease back into the final clean angle
			roll_tween.tween_property(%BrodySprite, "rotation_degrees", target, 0.12)
		
			# --- Squash & Stretch ---
			var squash = create_tween()
			squash.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			squash.tween_property(%BrodySprite, "scale", Vector2(1.3, 0.8), 0.1)
			squash.tween_property(%BrodySprite, "scale", Vector2(1, 1), 0.2)
		
			# --- Dash Logic ---
			dashing = true
			dash_available = false
			%DashCooldown.start()
			speed = 4000
			%feet.visible = false
			%BrodySprite.play("roll")
			
			# Acceleration phase
			for i in range(9):
				await get_tree().create_timer(0.005).timeout
				speed *= 1.12
				max_speed *= 1.12
		
			# Deceleration phase
			await get_tree().create_timer(0.18).timeout
			for i in range(4):
				await get_tree().create_timer(0.03).timeout
				speed /= 2
				max_speed /= 2
		
			await get_tree().create_timer(0.04).timeout
			speed = 4000
			max_speed = 75.0
			
			# Reset state
			collision_mask = original_mask
			dashing = false
			%feet.visible = true
			%BrodySprite.play("moving")

func moving() :
	if input_enabled == true :
		while direction != Vector2.ZERO :
			# Animation :
			%feet.play("moving")
			# Footsteps :
			%FootStepParticlesLeft.emitting = true
			await get_tree().create_timer(0.2).timeout
			%FootStepParticlesRight.emitting = true
			await get_tree().create_timer(0.2).timeout

func initialise_swap_tool() :
	if weapon_equipped == false :
		torch_equipped = false
		weapon_equipped = true
		%Torch.now_unequipped()
		%weapon.now_equipped()
	else :
		weapon_equipped = false
		torch_equipped = true
		%weapon.now_unequipped()
		%Torch.now_equipped()

func _on_dash_cooldown_timeout() -> void:
	dash_available = true

# Appearance :
func breathing() :
	if bobbing == false :
		bobbing = true
		for i in range(6) :
			%BrodySprite.position.y += 0.1
			%antenna.position.y += 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%BrodySprite.position.y += 0.05
			%antenna.position.y += 0.05
			await get_tree().create_timer(0.175).timeout
		for i in range(6) :
			%BrodySprite.position.y -= 0.1
			%antenna.position.y -= 0.1
			await get_tree().create_timer(0.175).timeout
		for i in range(4) :
			%BrodySprite.position.y -= 0.05
			%antenna.position.y -= 0.05
			await get_tree().create_timer(0.175).timeout
		bobbing = false
		breathing()

# UI Tracking :
func get_nearest_unlit_brazier(player_pos: Vector2) -> Node2D:
	var braziers = get_tree().get_nodes_in_group("braziers")
	var nearest: Node2D = null
	var nearest_dist = INF
	
	for b in braziers:
		if b.lit == true:  # or whatever your property is
			continue
	
		var dist = player_pos.distance_to(b.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = b
	
	return nearest

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# EXTERNAL GAMEPLAY REACTIONS :
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func crushed() :
	if squashed == false :
		squashed = true
		input_enabled = false
		%BrodySprite.play("puddle")
		%antenna.position.y += 4
		%feet.position.y -= 2
		await get_tree().create_timer(1.6).timeout
		%antenna.position.y -= 4
		%feet.position.y += 2
		squashed = false
		input_enabled = true
		#get_tree().pause()

func blood_splatter() :
	%BloodSplatterParticles.emitting = true

func flash_white():
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/flash_amount", 1.0, 0.05)
	tween.tween_property(material, "shader_parameter/flash_amount", 0.0, 0.1)

func darkness_consuming() :
	EventBus.total_current_darkness -= 4
	# Play Darkened Sprite

func caught_by_wormbat(wormbat) :
	EventBus.total_current_darkness -= 1
	flash_white()
	blood_splatter()
	basic_knockback(wormbat)

func got_torch_wraithed(torch_wraith) :
	EventBus.total_current_darkness -= 1
	flash_white()
	blood_splatter()
	basic_knockback(torch_wraith) 

func ogre_slashed(ogre) :
	EventBus.total_current_darkness -= 2
	flash_white()
	blood_splatter()
	# Bigger Knockback :
	global_position.y += randf_range(-3, 3)
	global_position.x += randf_range(-3, 3)
	var knockback_direction = (global_position - ogre.global_position).normalized()
	var knockback_movement = create_tween()
	knockback_movement.tween_property(self, "position", position + knockback_direction * 4, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	crushed()


# General Basic Knockback :
func basic_knockback(entity) :
	global_position.y += randf_range(-2, 2)
	global_position.x += randf_range(-2, 2)
	var knockback_direction = (global_position - entity.global_position).normalized()
	var knockback_movement = create_tween()
	knockback_movement.tween_property(self, "position", position + knockback_direction * 2, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Beacon Reactions :
func resting() :
	%DarknessClearingParticles.emitting = true

func nolonger_resting() :
	%DarknessClearingParticles.emitting = false


# TOUCHSCREEN REACTIONS :
func _on_touch_screen_press_2_move_stick_changed(vec: Variant) -> void:
	touch_move = vec

func _on_dash_button_pressed() -> void:
	dash_ability()
